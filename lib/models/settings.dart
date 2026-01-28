
import 'package:flutter/material.dart';

/// 应用设置
class Settings {
  final ThemeMode themeMode;
  final bool autoConnect;
  final bool minimizeToTray;
  final bool launchAtStartup;
  final bool systemProxy;
  final String language;
  
  // 代理端口设置
  final int socksPort;
  final int httpPort;
  final int apiPort;
  
  // 日志设置
  final String logLevel;
  
  // FEC 默认设置
  final bool defaultFecEnabled;
  final String defaultFecMode;
  
  // Mux 默认设置
  final bool defaultMuxEnabled;
  
  // 高级设置
  final bool allowLan;
  final int connectionTimeout;

  const Settings({
    this.themeMode = ThemeMode.system,
    this.autoConnect = false,
    this.minimizeToTray = true,
    this.launchAtStartup = false,
    this.systemProxy = false,
    this.language = 'en',
    this.socksPort = 1080,
    this.httpPort = 1081,
    this.apiPort = 19080,
    this.logLevel = 'info',
    this.defaultFecEnabled = true,
    this.defaultFecMode = 'adaptive',
    this.defaultMuxEnabled = true,
    this.allowLan = false,
    this.connectionTimeout = 10,
  });

  Settings copyWith({
    ThemeMode? themeMode,
    bool? autoConnect,
    bool? minimizeToTray,
    bool? launchAtStartup,
    bool? systemProxy,
    String? language,
    int? socksPort,
    int? httpPort,
    int? apiPort,
    String? logLevel,
    bool? defaultFecEnabled,
    String? defaultFecMode,
    bool? defaultMuxEnabled,
    bool? allowLan,
    int? connectionTimeout,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      autoConnect: autoConnect ?? this.autoConnect,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      systemProxy: systemProxy ?? this.systemProxy,
      language: language ?? this.language,
      socksPort: socksPort ?? this.socksPort,
      httpPort: httpPort ?? this.httpPort,
      apiPort: apiPort ?? this.apiPort,
      logLevel: logLevel ?? this.logLevel,
      defaultFecEnabled: defaultFecEnabled ?? this.defaultFecEnabled,
      defaultFecMode: defaultFecMode ?? this.defaultFecMode,
      defaultMuxEnabled: defaultMuxEnabled ?? this.defaultMuxEnabled,
      allowLan: allowLan ?? this.allowLan,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode.index,
      'auto_connect': autoConnect,
      'minimize_to_tray': minimizeToTray,
      'launch_at_startup': launchAtStartup,
      'system_proxy': systemProxy,
      'language': language,
      'socks_port': socksPort,
      'http_port': httpPort,
      'api_port': apiPort,
      'log_level': logLevel,
      'default_fec_enabled': defaultFecEnabled,
      'default_fec_mode': defaultFecMode,
      'default_mux_enabled': defaultMuxEnabled,
      'allow_lan': allowLan,
      'connection_timeout': connectionTimeout,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeMode: ThemeMode.values[json['theme_mode'] as int? ?? 0],
      autoConnect: json['auto_connect'] as bool? ?? false,
      minimizeToTray: json['minimize_to_tray'] as bool? ?? true,
      launchAtStartup: json['launch_at_startup'] as bool? ?? false,
      systemProxy: json['system_proxy'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      socksPort: json['socks_port'] as int? ?? 1080,
      httpPort: json['http_port'] as int? ?? 1081,
      apiPort: json['api_port'] as int? ?? 19080,
      logLevel: json['log_level'] as String? ?? 'info',
      defaultFecEnabled: json['default_fec_enabled'] as bool? ?? true,
      defaultFecMode: json['default_fec_mode'] as String? ?? 'adaptive',
      defaultMuxEnabled: json['default_mux_enabled'] as bool? ?? true,
      allowLan: json['allow_lan'] as bool? ?? false,
      connectionTimeout: json['connection_timeout'] as int? ?? 10,
    );
  }

  /// 获取 SOCKS5 监听地址
  String get socksAddr => allowLan ? '0.0.0.0:$socksPort' : '127.0.0.1:$socksPort';

  /// 获取 HTTP 监听地址
  String get httpAddr => allowLan ? '0.0.0.0:$httpPort' : '127.0.0.1:$httpPort';

  /// 获取 API 监听地址
  String get apiAddr => '127.0.0.1:$apiPort';

  /// 验证端口是否有效
  static bool isValidPort(int port) => port > 0 && port <= 65535;

  /// 验证端口字符串
  static bool isValidPortString(String port) {
    final p = int.tryParse(port);
    return p != null && isValidPort(p);
  }
}

