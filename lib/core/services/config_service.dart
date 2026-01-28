
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/server.dart';
import '../../models/settings.dart';
import '../utils/logger.dart';

/// 配置服务 - 管理持久化存储
class ConfigService {
  late SharedPreferences _prefs;
  Settings _settings = const Settings();
  List<Server> _servers = [];
  String? _selectedServerId;
  bool _initialized = false;

  // Keys
  static const String _keySettings = 'settings';
  static const String _keyServers = 'servers';
  static const String _keySelectedServer = 'selected_server_id';
  static const String _keyFirstRun = 'first_run';

  // Getters
  Settings get settings => _settings;
  List<Server> get servers => List.unmodifiable(_servers);
  String? get selectedServerId => _selectedServerId;
  bool get isInitialized => _initialized;
  bool get hasServers => _servers.isNotEmpty;

  /// 获取选中的服务器
  Server? get selectedServer {
    if (_selectedServerId == null) return null;
    try {
      return _servers.firstWhere((s) => s.id == _selectedServerId);
    } catch (_) {
      return null;
    }
  }

  /// 是否首次运行
  Future<bool> get isFirstRun async {
    return _prefs.getBool(_keyFirstRun) ?? true;
  }

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      await _loadServers();
      _selectedServerId = _prefs.getString(_keySelectedServer);
      _initialized = true;
      
      AppLogger.info('ConfigService initialized');
    } catch (e, stack) {
      AppLogger.error('ConfigService init failed', e, stack);
      rethrow;
    }
  }

  /// 标记首次运行完成
  Future<void> markFirstRunComplete() async {
    await _prefs.setBool(_keyFirstRun, false);
  }

  // ============ Settings ============

  Future<void> _loadSettings() async {
    final json = _prefs.getString(_keySettings);
    if (json != null) {
      try {
        _settings = Settings.fromJson(jsonDecode(json));
        AppLogger.debug('Settings loaded');
      } catch (e) {
        AppLogger.warning('Failed to load settings, using defaults', e);
        _settings = const Settings();
      }
    }
  }

  Future<void> saveSettings(Settings settings) async {
    _settings = settings;
    await _prefs.setString(_keySettings, jsonEncode(settings.toJson()));
    AppLogger.debug('Settings saved');
  }

  Future<void> updateSettings(Settings Function(Settings) updater) async {
    final newSettings = updater(_settings);
    await saveSettings(newSettings);
  }

  // ============ Servers ============

  Future<void> _loadServers() async {
    final json = _prefs.getString(_keyServers);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _servers = list.map((e) => Server.fromJson(e)).toList();
        AppLogger.debug('Loaded ${_servers.length} servers');
      } catch (e) {
        AppLogger.warning('Failed to load servers', e);
        _servers = [];
      }
    }
  }

  Future<void> _saveServers() async {
    final json = jsonEncode(_servers.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyServers, json);
    AppLogger.debug('Saved ${_servers.length} servers');
  }

  /// 添加服务器
  Future<void> addServer(Server server) async {
    // 检查是否已存在相同地址的服务器
    final exists = _servers.any((s) =>
        s.address == server.address &&
        s.tcpPort == server.tcpPort &&
        s.udpPort == server.udpPort);

    if (exists) {
      throw Exception('Server with same address already exists');
    }

    _servers.add(server);
    await _saveServers();

    // 如果是第一个服务器，自动选中
    if (_servers.length == 1) {
      await selectServer(server.id);
    }

    AppLogger.info('Server added: ${server.name}');
  }

  /// 更新服务器
  Future<void> updateServer(Server server) async {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      _servers[index] = server;
      await _saveServers();
      AppLogger.info('Server updated: ${server.name}');
    }
  }

  /// 删除服务器
  Future<void> deleteServer(String id) async {
    _servers.removeWhere((s) => s.id == id);
    
    if (_selectedServerId == id) {
      _selectedServerId = _servers.isNotEmpty ? _servers.first.id : null;
      if (_selectedServerId != null) {
        await _prefs.setString(_keySelectedServer, _selectedServerId!);
      } else {
        await _prefs.remove(_keySelectedServer);
      }
    }
    
    await _saveServers();
    AppLogger.info('Server deleted: $id');
  }

  /// 选择服务器
  Future<void> selectServer(String? id) async {
    _selectedServerId = id;
    if (id != null) {
      await _prefs.setString(_keySelectedServer, id);
    } else {
      await _prefs.remove(_keySelectedServer);
    }
    AppLogger.debug('Server selected: $id');
  }

  /// 更新服务器延迟
  Future<void> updateServerLatency(String id, int? latency) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index != -1) {
      _servers[index] = _servers[index].copyWith(latency: latency);
      await _saveServers();
    }
  }

  /// 获取服务器
  Server? getServer(String id) {
    try {
      return _servers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根据地址查找服务器
  Server? findServerByAddress(String address, int port) {
    try {
      return _servers.firstWhere(
        (s) => s.address == address && (s.tcpPort == port || s.udpPort == port),
      );
    } catch (_) {
      return null;
    }
  }

  /// 导入服务器（从分享链接）
  Future<Server?> importServerFromLink(String link) async {
    final server = Server.fromShareLink(link);
    if (server != null) {
      await addServer(server);
      return server;
    }
    return null;
  }

  /// 批量导入服务器
  Future<List<Server>> importServersFromLinks(List<String> links) async {
    final imported = <Server>[];
    for (final link in links) {
      try {
        final server = await importServerFromLink(link);
        if (server != null) {
          imported.add(server);
        }
      } catch (e) {
        AppLogger.warning('Failed to import server from link', e);
      }
    }
    return imported;
  }

  /// 导出所有服务器为分享链接
  List<String> exportAllServers() {
    return _servers.map((s) => s.toShareLink()).toList();
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    _settings = const Settings();
    _servers = [];
    _selectedServerId = null;
    await _prefs.clear();
    AppLogger.info('All data cleared');
  }
}

