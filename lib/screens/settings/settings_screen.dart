// ============================================================
// lib/screens/settings/settings_screen.dart (修复版 - 不使用 url_launcher)
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../providers/connection_provider.dart';
import '../../core/services/core_service.dart';
import '../../theme/colors.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 外观
        _buildSection(
          context,
          title: 'APPEARANCE',
          children: [
            _buildThemeTile(context, settings),
          ],
        ),
        const SizedBox(height: 16),

        // 常规
        _buildSection(
          context,
          title: 'GENERAL',
          children: [
            SwitchListTile(
              title: const Text('Auto Connect'),
              subtitle: const Text('Connect automatically on startup'),
              value: settings.autoConnect,
              onChanged: settings.setAutoConnect,
              secondary: const Icon(Icons.flash_on_outlined),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Minimize to Tray'),
              subtitle: const Text('Keep running in system tray'),
              value: settings.minimizeToTray,
              onChanged: settings.setMinimizeToTray,
              secondary: const Icon(Icons.minimize_outlined),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Launch at Startup'),
              subtitle: const Text('Start when system boots'),
              value: settings.launchAtStartup,
              onChanged: settings.setLaunchAtStartup,
              secondary: const Icon(Icons.power_settings_new_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 代理
        _buildSection(
          context,
          title: 'PROXY',
          children: [
            ListTile(
              leading: const Icon(Icons.lan_outlined),
              title: const Text('SOCKS5 Port'),
              subtitle: Text(settings.socksPortStr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPort(
                context,
                'SOCKS5 Port',
                settings.socksPort,
                (v) => settings.setSocksPort(v),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.http_outlined),
              title: const Text('HTTP Port'),
              subtitle: Text(settings.httpPortStr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPort(
                context,
                'HTTP Port',
                settings.httpPort,
                (v) => settings.setHttpPort(v),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Allow LAN'),
              subtitle: const Text('Accept connections from local network'),
              value: settings.allowLan,
              onChanged: settings.setAllowLan,
              secondary: const Icon(Icons.devices_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 默认设置
        _buildSection(
          context,
          title: 'DEFAULTS',
          children: [
            SwitchListTile(
              title: const Text('Enable FEC'),
              subtitle: const Text('Forward Error Correction for new servers'),
              value: settings.defaultFecEnabled,
              onChanged: settings.setDefaultFecEnabled,
              secondary: const Icon(Icons.healing_outlined),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('FEC Mode'),
              subtitle: Text(settings.defaultFecMode.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              enabled: settings.defaultFecEnabled,
              onTap: () => _selectFecMode(context, settings),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Enable Multiplexing'),
              subtitle: const Text('Share connection for new servers'),
              value: settings.defaultMuxEnabled,
              onChanged: settings.setDefaultMuxEnabled,
              secondary: const Icon(Icons.call_split_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 高级
        _buildSection(
          context,
          title: 'ADVANCED',
          children: [
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Log Level'),
              subtitle: Text(settings.logLevel.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectLogLevel(context, settings),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: const Text('Restart Core'),
              subtitle: const Text('Restart the proxy core service'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _restartCore(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 关于
        _buildSection(
          context,
          title: 'ABOUT',
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              subtitle: Text('${AppConstants.appVersion} (Core: ${AppConstants.coreVersion})'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.code_outlined),
              title: const Text('GitHub'),
              subtitle: const Text(AppConstants.githubUrl),
              trailing: const Icon(Icons.copy, size: 18),
              onTap: () => _copyAndOpenUrl(context, AppConstants.githubUrl),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Report Issue'),
              subtitle: const Text(AppConstants.issuesUrl),
              trailing: const Icon(Icons.copy, size: 18),
              onTap: () => _copyAndOpenUrl(context, AppConstants.issuesUrl),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeTile(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: Icon(
        settings.themeMode == ThemeMode.dark
            ? Icons.dark_mode
            : settings.themeMode == ThemeMode.light
                ? Icons.light_mode
                : Icons.brightness_auto,
      ),
      title: const Text('Theme'),
      subtitle: Text(_themeModeText(settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, settings),
    );
  }

  String _themeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_themeModeText(mode)),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editPort(
    BuildContext context,
    String title,
    int currentValue,
    Future<bool> Function(int) onSave,
  ) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter port number (1-65535)',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0 && port <= 65535) {
                final success = await onSave(port);
                Navigator.pop(ctx);
                if (success) {
                  context.showSnackBar('Port updated. Restart core to apply.');
                }
              } else {
                context.showSnackBar('Invalid port number', isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _selectFecMode(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FEC Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Adaptive'),
              subtitle: const Text('Adjusts based on network conditions'),
              value: 'adaptive',
              groupValue: settings.defaultFecMode,
              onChanged: (v) {
                if (v != null) {
                  settings.setDefaultFecMode(v);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Static'),
              subtitle: const Text('Fixed redundancy level'),
              value: 'static',
              groupValue: settings.defaultFecMode,
              onChanged: (v) {
                if (v != null) {
                  settings.setDefaultFecMode(v);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectLogLevel(BuildContext context, SettingsProvider settings) {
    final levels = ['debug', 'info', 'warn', 'error'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            return RadioListTile<String>(
              title: Text(level.toUpperCase()),
              value: level,
              groupValue: settings.logLevel,
              onChanged: (v) {
                if (v != null) {
                  settings.setLogLevel(v);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _restartCore(BuildContext context) {
    final connection = context.read<ConnectionProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart Core'),
        content: Text(
          connection.isConnected
              ? 'This will disconnect your current connection. Continue?'
              : 'This will restart the proxy core service. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              context.showSnackBar('Restarting core...');
              
              final coreService = context.read<CoreService>();
              await coreService.restart();
              
              context.showSnackBar('Core restarted');
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  /// 复制 URL 到剪贴板并尝试打开
  void _copyAndOpenUrl(BuildContext context, String url) async {
    // 复制到剪贴板
    await Clipboard.setData(ClipboardData(text: url));
    context.showSnackBar('Copied to clipboard: $url');
    
    // 尝试使用系统命令打开 URL
    try {
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      // 如果打开失败，URL 已经复制到剪贴板了
    }
  }
}
