
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/connection_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/servers/servers_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/logs/logs_screen.dart';
import 'core/services/tray_service.dart';
import 'core/services/core_service.dart';
import 'core/utils/constants.dart';

class PhantomApp extends StatefulWidget {
  const PhantomApp({super.key});

  @override
  State<PhantomApp> createState() => _PhantomAppState();
}

class _PhantomAppState extends State<PhantomApp> with WindowListener {
  late TrayService _trayService;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServersScreen(),
    SettingsScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.dns_outlined),
      selectedIcon: Icon(Icons.dns),
      label: 'Servers',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
    }
    _initTray();
    _checkAutoConnect();
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    _trayService.dispose();
    super.dispose();
  }

  Future<void> _initTray() async {
    final connection = context.read<ConnectionProvider>();
    
    _trayService = TrayService(
      onShow: () => windowManager.show(),
      onQuit: () => _quit(),
      onConnect: () => connection.connect(),
      onDisconnect: () => connection.disconnect(),
    );
    
    await _trayService.init();
    connection.setTrayService(_trayService);
  }

  Future<void> _checkAutoConnect() async {
    final settings = context.read<SettingsProvider>();
    if (settings.autoConnect) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.read<ConnectionProvider>().connect();
      }
    }
  }

  Future<void> _quit() async {
    final coreService = context.read<CoreService>();
    await coreService.shutdown();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    final settings = context.read<SettingsProvider>();
    if (settings.minimizeToTray) {
      await windowManager.hide();
    } else {
      await _quit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      home: Scaffold(
        body: Column(
          children: [
            // 自定义标题栏
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
              const _TitleBar(),
            // 主内容
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _screens[_currentIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: NavigationBar(
        height: 65,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _destinations,
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();
    
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 36,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            const SizedBox(width: 12),
            // 状态指示器
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connection.isConnected
                    ? Colors.green
                    : connection.isConnecting
                        ? Colors.orange
                        : Colors.grey,
                boxShadow: connection.isConnected
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (connection.isConnected)
              Text(
                ' - Connected',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            const Spacer(),
            // 窗口控制按钮
            if (Platform.isWindows) ...[
              _WindowButton(
                icon: Icons.remove,
                onTap: () => windowManager.minimize(),
              ),
              _WindowButton(
                icon: Icons.crop_square,
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: Icons.close,
                onTap: () => windowManager.close(),
                isClose: true,
              ),
            ],
            if (Platform.isMacOS) const SizedBox(width: 70),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 36,
          color: _isHovered
              ? (widget.isClose ? Colors.red : Colors.grey.withOpacity(0.2))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered && widget.isClose
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

