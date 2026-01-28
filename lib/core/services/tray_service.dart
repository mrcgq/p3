// ============================================================
// lib/core/services/tray_service.dart (中文版)
// ============================================================

import 'dart:io';
import 'package:system_tray/system_tray.dart';

import '../utils/logger.dart';

typedef TrayCallback = void Function();

/// 系统托盘服务
class TrayService {
  final TrayCallback onShow;
  final TrayCallback onQuit;
  final TrayCallback? onConnect;
  final TrayCallback? onDisconnect;

  SystemTray? _systemTray;
  Menu? _menu;
  bool _isConnected = false;
  bool _initialized = false;

  TrayService({
    required this.onShow,
    required this.onQuit,
    this.onConnect,
    this.onDisconnect,
  });

  bool get isSupported =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// 初始化
  Future<void> init() async {
    if (!isSupported || _initialized) return;

    try {
      _systemTray = SystemTray();

      await _systemTray!.initSystemTray(
        title: 'Phantom',
        iconPath: _getIconPath(false),
        toolTip: 'Phantom - 未连接',
      );

      await _buildMenu();

      _systemTray!.registerSystemTrayEventHandler((eventName) {
        switch (eventName) {
          case kSystemTrayEventClick:
            if (Platform.isWindows) {
              onShow();
            } else {
              _systemTray!.popUpContextMenu();
            }
            break;
          case kSystemTrayEventRightClick:
            _systemTray!.popUpContextMenu();
            break;
        }
      });

      _initialized = true;
      AppLogger.info('托盘服务已初始化');
    } catch (e, stack) {
      AppLogger.error('托盘服务初始化失败', e, stack);
    }
  }

  Future<void> _buildMenu() async {
    _menu = Menu();
    
    final items = <MenuItemBase>[
      MenuItemLabel(
        label: '显示 Phantom',
        onClicked: (_) => onShow(),
      ),
      MenuSeparator(),
    ];

    if (onConnect != null && onDisconnect != null) {
      if (_isConnected) {
        items.add(MenuItemLabel(
          label: '断开连接',
          onClicked: (_) => onDisconnect!(),
        ));
      } else {
        items.add(MenuItemLabel(
          label: '连接',
          onClicked: (_) => onConnect!(),
        ));
      }
      items.add(MenuSeparator());
    }

    items.add(MenuItemLabel(
      label: '退出',
      onClicked: (_) => onQuit(),
    ));

    await _menu!.buildFrom(items);
    await _systemTray?.setContextMenu(_menu!);
  }

  String _getIconPath(bool connected) {
    if (Platform.isWindows) {
      return connected
          ? 'assets/icons/tray_connected.ico'
          : 'assets/icons/tray_disconnected.ico';
    } else if (Platform.isMacOS) {
      return connected
          ? 'assets/icons/tray_connected.png'
          : 'assets/icons/tray_disconnected.png';
    }
    return 'assets/icons/app_icon.png';
  }

  /// 更新连接状态
  Future<void> updateConnectionStatus(bool connected) async {
    if (!_initialized || _isConnected == connected) return;
    
    _isConnected = connected;

    try {
      await _systemTray?.setImage(_getIconPath(connected));
      await _systemTray?.setToolTip(
        connected ? 'Phantom - 已连接' : 'Phantom - 未连接',
      );
      await _buildMenu();
      
      AppLogger.debug('托盘状态已更新: ${connected ? '已连接' : '未连接'}');
    } catch (e) {
      AppLogger.warning('更新托盘状态失败', e);
    }
  }

  /// 显示通知
  Future<void> showNotification(String title, String message) async {
    if (!_initialized) return;

    try {
      AppLogger.info('通知: $title - $message');
    } catch (e) {
      AppLogger.warning('显示通知失败', e);
    }
  }

  /// 释放资源
  void dispose() {
    if (_initialized) {
      _systemTray?.destroy();
      _initialized = false;
    }
  }
}
