// ============================================================
// lib/screens/home/widgets/quick_actions.dart (中文版)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/settings_provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../theme/colors.dart';
import '../../../core/utils/extensions.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final connection = context.watch<ConnectionProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '快捷操作',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.public,
                    label: '系统代理',
                    isActive: settings.systemProxy,
                    enabled: connection.isConnected,
                    onTap: () async {
                      final newValue = !settings.systemProxy;
                      await settings.setSystemProxy(newValue);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy,
                    label: '复制代理',
                    onTap: () {
                      final proxy = 'socks5://127.0.0.1:${settings.socksPort}';
                      Clipboard.setData(ClipboardData(text: proxy));
                      context.showSnackBar('已复制: $proxy');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.http,
                    label: '复制HTTP',
                    onTap: () {
                      final proxy = 'http://127.0.0.1:${settings.httpPort}';
                      Clipboard.setData(ClipboardData(text: proxy));
                      context.showSnackBar('已复制: $proxy');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.refresh,
                    label: '重新连接',
                    enabled: connection.isConnected,
                    onTap: () async {
                      await context.read<ConnectionProvider>().reconnect();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled;
    final effectiveActive = isActive && enabled;

    return Material(
      color: effectiveActive
          ? AppColors.primary.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: effectiveEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: effectiveActive
                  ? AppColors.primary
                  : effectiveEnabled
                      ? Theme.of(context).dividerColor
                      : Theme.of(context).dividerColor.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: effectiveActive
                    ? AppColors.primary
                    : effectiveEnabled
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: effectiveActive ? FontWeight.w600 : FontWeight.w500,
                  color: effectiveActive
                      ? AppColors.primary
                      : effectiveEnabled
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
