// ============================================================
// lib/main.dart (修复版)
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import 'app.dart';
import 'providers/connection_provider.dart';
import 'providers/servers_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/settings_provider.dart';
import 'core/services/core_service.dart';
import 'core/services/config_service.dart';
import 'core/utils/logger.dart';
import 'core/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置日志级别
  AppLogger.minLevel = LogLevel.debug;
  AppLogger.info('Starting ${AppConstants.appName} v${AppConstants.appVersion}');

  // 初始化桌面窗口管理
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(400, 720),
      minimumSize: Size(360, 600),
      maximumSize: Size(500, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: AppConstants.appName,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 初始化开机启动
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    LaunchAtStartup.instance.setup(
      appName: AppConstants.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  // 初始化服务
  final configService = ConfigService();
  await configService.init();

  final coreService = CoreService(configService);
  
  // 创建 providers
  final settingsProvider = SettingsProvider(configService);
  final serversProvider = ServersProvider(configService);
  
  // 设置服务引用
  settingsProvider.setCoreService(coreService);
  serversProvider.setCoreService(coreService);

  // 初始化核心服务
  try {
    await coreService.init();
  } catch (e) {
    AppLogger.error('Failed to initialize core service', e);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ConfigService>.value(value: configService),
        Provider<CoreService>.value(value: coreService),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ServersProvider>.value(value: serversProvider),
        ChangeNotifierProvider(
          create: (context) => ConnectionProvider(
            coreService,
            context.read<ServersProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(coreService),
        ),
      ],
      child: const PhantomApp(),
    ),
  );
}
