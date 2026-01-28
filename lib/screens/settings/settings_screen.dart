// ============================================================
// lib/screens/settings/settings_screen.dart (中文版)
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
            '设置',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 外观
        _buildSection(
          context,
          title: '外观',
          children: [
            _buildThemeTile(context, settings),
          ],
        ),
        const SizedBox(height: 16),

        // 常规
        _buildSection(
          context,
          title: '常规',
          children: [
            SwitchListTile(
              title: const Text('自动连接'),
              subtitle: const Text('启动时自动连接'),
              value: settings.autoConnect,
              onChanged: settings.setAutoConnect,
              secondary: const Icon(Icons.flash_on_outlined),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('最小化到托盘'),
              subtitle: const Text('关闭窗口时保持运行'),
              value: settings.minimizeToTray,
              onChanged: settings.setMinimizeToTray,
              secondary: const Icon(Icons.minimize_outlined),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('开机启动'),
              subtitle: const Text('系统启动时自动运行'),
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
          title: '代理',
          children: [
            ListTile(
              leading: const Icon(Icons.lan_outlined),
              title: const Text('SOCKS5 端口'),
              subtitle: Text(settings.socksPortStr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPort(
                context,
                'SOCKS5 端口',
                settings.socksPort,
                (v) => settings.setSocksPort(v),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.http_outlined),
              title: const Text('HTTP 端口'),
              subtitle: Text(settings.httpPortStr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPort(
                context,
                'HTTP 端口',
                settings.httpPort,
                (v) => settings.setHttpPort(v),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('允许局域网连接'),
              subtitle: const Text('接受来自局域网的连接'),
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
          title: '默认设置',
          children: [
            SwitchListTile(
              title: const Text('启用 FEC'),
              subtitle: const Text('新服务器默认开启前向纠错'),
              value: settings.defaultFecEnabled,
              onChanged: settings.setDefaultFecEnabled,
              secondary: const Icon(Icons.healing_outlined),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('FEC 模式'),
              subtitle: Text(settings.defaultFecMode == 'adaptive' ? '自适应' : '静态'),
              trailing: const Icon(Icons.chevron_right),
              enabled: settings.defaultFecEnabled,
              onTap: () => _selectFecMode(context, settings),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('启用多路复用'),
              subtitle: const Text('新服务器默认开启多路复用'),
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
          title: '高级',
          children: [
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('日志级别'),
              subtitle: Text(_getLogLevelText(settings.logLevel)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectLogLevel(context, settings),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: const Text('重启内核'),
              subtitle: const Text('重新启动代理核心服务'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _restartCore(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 关于
        _buildSection(
          context,
          title: '关于',
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本'),
              subtitle: Text('${AppConstants.appVersion} (内核: ${AppConstants.coreVersion})'),
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
              title: const Text('报告问题'),
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
      title: const Text('主题'),
      subtitle: Text(_themeModeText(settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, settings),
    );
  }

  String _themeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  String _getLogLevelText(String level) {
    switch (level) {
      case 'debug':
        return '调试';
      case 'info':
        return '信息';
      case 'warn':
        return '警告';
      case 'error':
        return '错误';
      default:
        return level.toUpperCase();
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色'),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色'),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
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
            hintText: '请输入端口号 (1-65535)',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0 && port <= 65535) {
                final success = await onSave(port);
                Navigator.pop(ctx);
                if (success) {
                  context.showSnackBar('端口已更新，重启内核后生效');
                }
              } else {
                context.showSnackBar('端口号无效', isError: true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _selectFecMode(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FEC 模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('自适应'),
              subtitle: const Text('根据网络状况自动调整'),
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
              title: const Text('静态'),
              subtitle: const Text('固定冗余等级'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('日志级别'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('调试'),
              value: 'debug',
              groupValue: settings.logLevel,
              onChanged: (v) {
                if (v != null) {
                  settings.setLogLevel(v);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('信息'),
              value: 'info',
              groupValue: settings.logLevel,
              onChanged: (v) {
                if (v != null) {
                  settings.setLogLevel(v);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('警告'),
              value: 'warn',
              groupValue: settings.logLevel,
              onChanged: (v) {
                if (v != null) {
                  settings.setLogLevel(v);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('错误'),
              value: 'error',
              groupValue: settings.logLevel,
              onChanged: (v) {
                if (v != null) {
                  settings.setLogLevel(v);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _restartCore(BuildContext context) {
    final connection = context.read<ConnectionProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重启内核'),
        content: Text(
          connection.isConnected
              ? '这将断开当前连接。是否继续？'
              : '这将重启代理核心服务。是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              context.showSnackBar('正在重启内核...');
              
              final coreService = context.read<CoreService>();
              await coreService.restart();
              
              context.showSnackBar('内核已重启');
            },
            child: const Text('重启'),
          ),
        ],
      ),
    );
  }

  void _copyAndOpenUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    context.showSnackBar('已复制到剪贴板: $url');
    
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
