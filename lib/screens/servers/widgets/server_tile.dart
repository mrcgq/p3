// ============================================================
// lib/screens/servers/widgets/server_tile.dart (中文版 - 完整)
// ============================================================

import 'package:flutter/material.dart';

import '../../../models/server.dart';
import '../../../theme/colors.dart';

class ServerTile extends StatelessWidget {
  final Server server;
  final bool isSelected;
  final bool isPinging;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPing;
  final VoidCallback onShare;

  const ServerTile({
    super.key,
    required this.server,
    required this.isSelected,
    this.isPinging = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPing,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.dns,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${server.address}:${server.activePort}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 标签
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildTag(context, server.mode.toUpperCase(), AppColors.primary),
                        if (server.tls.enabled)
                          _buildTag(context, 'TLS', AppColors.success),
                        if (server.fec.enabled)
                          _buildTag(context, 'FEC', AppColors.warning),
                        if (server.mux.enabled)
                          _buildTag(context, 'MUX', AppColors.info),
                      ],
                    ),
                  ],
                ),
              ),

              // 延迟
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isPinging)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (server.latency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.getLatencyColor(server.latency!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${server.latency}ms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getLatencyColor(server.latency!),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.speed, size: 18),
                      onPressed: onPing,
                      tooltip: '测试延迟',
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 4),
                  // 菜单
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 12),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'ping',
                        child: Row(
                          children: [
                            Icon(Icons.speed, size: 18),
                            SizedBox(width: 12),
                            Text('测试延迟'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18),
                            SizedBox(width: 12),
                            Text('分享'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.error),
                            SizedBox(width: 12),
                            Text('删除', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'ping':
                          onPing();
                          break;
                        case 'share':
                          onShare();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
