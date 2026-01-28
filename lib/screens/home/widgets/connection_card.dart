// ============================================================
// lib/screens/home/widgets/connection_card.dart (中文版)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../providers/connection_provider.dart';
import '../../../providers/servers_provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../theme/colors.dart';
import '../../../models/connection_state.dart';

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();
    final servers = context.watch<ServersProvider>();
    final stats = context.watch<StatsProvider>();
    final isConnected = connection.isConnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 状态指示器
            _buildStatusIndicator(context, connection),
            const SizedBox(height: 24),

            // 状态文本
            Text(
              _getStatusText(connection.status),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(connection.status),
              ),
            ),
            const SizedBox(height: 8),

            // 服务器信息
            if (servers.selectedServer != null) ...[
              Text(
                servers.selectedServer!.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.language,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${servers.selectedServer!.address}:${servers.selectedServer!.activePort}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(servers.selectedServer!.mode),
                ],
              ),
              if (isConnected) ...[
                const SizedBox(height: 8),
                Text(
                  '运行时间: ${stats.formattedUptime}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ] else
              Text(
                '未选择服务器',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),

            const SizedBox(height: 24),

            // 连接按钮
            _buildConnectButton(context, connection, servers),

            // 错误消息
            if (connection.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        connection.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ConnectionProvider connection) {
    const size = 100.0;
    final isConnected = connection.isConnected;
    final isConnecting = connection.isConnecting;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈动画
        if (isConnecting)
          SizedBox(
            width: size + 20,
            height: size + 20,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        
        // 主圆圈
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isConnected ? AppColors.successGradient : null,
            color: isConnected ? null : Theme.of(context).colorScheme.surface,
            border: isConnected
                ? null
                : Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isConnected ? Icons.shield : Icons.shield_outlined,
            size: 44,
            color: isConnected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ).animate(target: isConnected ? 1 : 0).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 200.ms,
        ),
      ],
    );
  }

  Widget _buildModeChip(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildConnectButton(
    BuildContext context,
    ConnectionProvider connection,
    ServersProvider servers,
  ) {
    final isConnected = connection.isConnected;
    final isConnecting = connection.isConnecting;
    final canConnect = servers.selectedServer != null && connection.canConnect;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (canConnect || isConnected) && !isConnecting
            ? () => connection.toggle()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? AppColors.error : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isConnecting) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              isConnecting
                  ? '连接中...'
                  : isConnected
                      ? '断开连接'
                      : '连接',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return '已保护';
      case ConnectionStatus.connecting:
        return '连接中...';
      case ConnectionStatus.disconnecting:
        return '断开中...';
      case ConnectionStatus.error:
        return '连接失败';
      case ConnectionStatus.disconnected:
        return '未连接';
    }
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return AppColors.warning;
      case ConnectionStatus.error:
        return AppColors.error;
      case ConnectionStatus.disconnected:
        return AppColors.textSecondaryLight;
    }
  }
}
