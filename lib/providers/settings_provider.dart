
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import '../core/services/config_service.dart';
import '../core/services/core_service.dart';
import '../core/utils/logger.dart';
import '../models/settings.dart';

/// 设置管理
class SettingsProvider extends ChangeNotifier {
  final ConfigService _configService;
  CoreService? _coreService;

  Settings get _settings => _configService.settings;

  // Getters
  ThemeMode get themeMode => _settings.themeMode;
  bool get autoConnect => _settings.autoConnect;
  bool get minimizeToTray => _settings.minimizeToTray;
  bool get launchAtStartup => _settings.launchAtStartup;
  bool get systemProxy => _settings.systemProxy;
  String get language => _settings.language;
  
  int get socksPort => _settings.socksPort;
  int get httpPort => _settings.httpPort;
  int get apiPort => _settings.apiPort;
  String get logLevel => _settings.logLevel;
  
  bool get defaultFecEnabled => _settings.defaultFecEnabled;
  String get defaultFecMode => _settings.defaultFecMode;
  bool get defaultMuxEnabled => _settings.defaultMuxEnabled;
  
  bool get allowLan => _settings.allowLan;
  int get connectionTimeout => _settings.connectionTimeout;

  // 格式化的端口字符串
  String get socksPortStr => socksPort.toString();
  String get httpPortStr => httpPort.toString();
  String get apiPortStr => apiPort.toString();

  // 地址
  String get socksAddr => _settings.socksAddr;
  String get httpAddr => _settings.httpAddr;
  String get apiAddr => _settings.apiAddr;

  SettingsProvider(this._configService);

  /// 设置核心服务引用
  void setCoreService(CoreService coreService) {
    _coreService = coreService;
  }

  // ============ 主题设置 ============

  Future<void> setThemeMode(ThemeMode mode) async {
    await _configService.saveSettings(_settings.copyWith(themeMode: mode));
    notifyListeners();
  }

  // ============ 常规设置 ============

  Future<void> setAutoConnect(bool value) async {
    await _configService.saveSettings(_settings.copyWith(autoConnect: value));
    notifyListeners();
  }

  Future<void> setMinimizeToTray(bool value) async {
    await _configService.saveSettings(_settings.copyWith(minimizeToTray: value));
    notifyListeners();
  }

  Future<void> setLaunchAtStartup(bool value) async {
    try {
      if (value) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      await _configService.saveSettings(_settings.copyWith(launchAtStartup: value));
      notifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to set launch at startup', e);
    }
  }

  Future<void> setSystemProxy(bool value) async {
    if (_coreService != null) {
      final success = await _coreService!.setSystemProxy(value);
      if (success) {
        await _configService.saveSettings(_settings.copyWith(systemProxy: value));
        notifyListeners();
      }
    }
  }

  Future<void> setLanguage(String value) async {
    await _configService.saveSettings(_settings.copyWith(language: value));
    notifyListeners();
  }

  // ============ 代理端口设置 ============

  Future<bool> setSocksPort(int port) async {
    if (!Settings.isValidPort(port)) return false;
    
    await _configService.saveSettings(_settings.copyWith(socksPort: port));
    notifyListeners();
    
    // 需要重启内核才能生效
    return true;
  }

  Future<bool> setHttpPort(int port) async {
    if (!Settings.isValidPort(port)) return false;
    
    await _configService.saveSettings(_settings.copyWith(httpPort: port));
    notifyListeners();
    return true;
  }

  Future<bool> setApiPort(int port) async {
    if (!Settings.isValidPort(port)) return false;
    
    await _configService.saveSettings(_settings.copyWith(apiPort: port));
    notifyListeners();
    return true;
  }

  // ============ 日志设置 ============

  Future<void> setLogLevel(String level) async {
    if (!['debug', 'info', 'warn', 'error'].contains(level)) return;
    
    await _configService.saveSettings(_settings.copyWith(logLevel: level));
    notifyListeners();
  }

  // ============ FEC/Mux 默认设置 ============

  Future<void> setDefaultFecEnabled(bool value) async {
    await _configService.saveSettings(_settings.copyWith(defaultFecEnabled: value));
    notifyListeners();
  }

  Future<void> setDefaultFecMode(String mode) async {
    if (!['static', 'adaptive'].contains(mode)) return;
    
    await _configService.saveSettings(_settings.copyWith(defaultFecMode: mode));
    notifyListeners();
  }

  Future<void> setDefaultMuxEnabled(bool value) async {
    await _configService.saveSettings(_settings.copyWith(defaultMuxEnabled: value));
    notifyListeners();
  }

  // ============ 高级设置 ============

  Future<void> setAllowLan(bool value) async {
    await _configService.saveSettings(_settings.copyWith(allowLan: value));
    notifyListeners();
  }

  Future<void> setConnectionTimeout(int seconds) async {
    if (seconds < 1 || seconds > 60) return;
    
    await _configService.saveSettings(_settings.copyWith(connectionTimeout: seconds));
    notifyListeners();
  }

  // ============ 辅助方法 ============

  /// 检查端口字符串是否有效
  bool isValidPortString(String port) {
    return Settings.isValidPortString(port);
  }

  /// 端口是否需要重启
  bool get requiresRestart => false; // 可以追踪端口变更

  /// 重置所有设置
  Future<void> resetAll() async {
    await _configService.saveSettings(const Settings());
    notifyListeners();
  }
}


