
import 'dart:async';
import 'package:flutter/material.dart';

import '../core/services/config_service.dart';
import '../core/services/core_service.dart';
import '../core/utils/logger.dart';
import '../models/server.dart';

/// 服务器列表管理
class ServersProvider extends ChangeNotifier {
  final ConfigService _configService;
  CoreService? _coreService;
  
  bool _isPinging = false;
  Set<String> _pingingServers = {};

  // Getters
  List<Server> get servers => _configService.servers;
  Server? get selectedServer => _configService.selectedServer;
  String? get selectedServerId => _configService.selectedServerId;
  bool get hasServers => _configService.hasServers;
  bool get isPinging => _isPinging;

  ServersProvider(this._configService);

  /// 设置核心服务引用
  void setCoreService(CoreService coreService) {
    _coreService = coreService;
  }

  /// 添加服务器
  Future<void> addServer(Server server) async {
    await _configService.addServer(server);
    notifyListeners();
    AppLogger.info('Server added: ${server.name}');
  }

  /// 从分享链接添加服务器
  Future<Server?> addServerFromLink(String link) async {
    try {
      final server = await _configService.importServerFromLink(link);
      if (server != null) {
        notifyListeners();
        AppLogger.info('Server imported: ${server.name}');
      }
      return server;
    } catch (e) {
      AppLogger.warning('Failed to import server', e);
      return null;
    }
  }

  /// 更新服务器
  Future<void> updateServer(Server server) async {
    await _configService.updateServer(server);
    notifyListeners();
  }

  /// 删除服务器
  Future<void> deleteServer(String id) async {
    await _configService.deleteServer(id);
    notifyListeners();
  }

  /// 选择服务器
  Future<void> selectServer(String? id) async {
    await _configService.selectServer(id);
    notifyListeners();
  }

  /// Ping 单个服务器
  Future<void> pingServer(Server server) async {
    if (_coreService == null || _pingingServers.contains(server.id)) return;

    _pingingServers.add(server.id);
    notifyListeners();

    try {
      final latency = await _coreService!.pingServer(server);
      await _configService.updateServerLatency(server.id, latency);
      notifyListeners();
    } finally {
      _pingingServers.remove(server.id);
      notifyListeners();
    }
  }

  /// Ping 所有服务器
  Future<void> pingAllServers() async {
    if (_coreService == null || _isPinging) return;

    _isPinging = true;
    notifyListeners();

    try {
      final futures = servers.map((server) async {
        final latency = await _coreService!.pingServer(server);
        await _configService.updateServerLatency(server.id, latency);
      });

      await Future.wait(futures);
      notifyListeners();
    } finally {
      _isPinging = false;
      notifyListeners();
    }
  }

  /// 检查服务器是否正在 ping
  bool isServerPinging(String id) => _pingingServers.contains(id);

  /// 获取服务器分享链接
  String? getShareLink(String id) {
    final server = _configService.getServer(id);
    return server?.toShareLink();
  }

  /// 导出所有服务器
  List<String> exportAll() {
    return _configService.exportAllServers();
  }

  /// 排序服务器（按延迟）
  List<Server> get serversSortedByLatency {
    final sorted = List<Server>.from(servers);
    sorted.sort((a, b) {
      if (a.latency == null && b.latency == null) return 0;
      if (a.latency == null) return 1;
      if (b.latency == null) return -1;
      return a.latency!.compareTo(b.latency!);
    });
    return sorted;
  }

  /// 获取最快的服务器
  Server? get fastestServer {
    final sorted = serversSortedByLatency;
    return sorted.isNotEmpty && sorted.first.latency != null
        ? sorted.first
        : null;
  }

  /// 选择最快的服务器
  Future<void> selectFastestServer() async {
    await pingAllServers();
    final fastest = fastestServer;
    if (fastest != null) {
      await selectServer(fastest.id);
    }
  }
}


