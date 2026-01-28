// ============================================================
// lib/screens/servers/servers_screen.dart (中文版)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/server.dart';
import '../../providers/servers_provider.dart';
import '../../providers/connection_provider.dart';
import '../../theme/colors.dart';
import '../../core/utils/extensions.dart';
import 'add_server_screen.dart';
import 'widgets/server_tile.dart';

class ServersScreen extends StatelessWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServersProvider>();

    return Scaffold(
      body: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  '服务器',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (servers.hasServers)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${servers.servers.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const Spacer(),
                if (servers.hasServers)
                  IconButton(
                    icon: servers.isPinging
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.speed, size: 22),
                    onPressed: servers.isPinging ? null : () => servers.pingAllServers(),
                    tooltip: '测试延迟',
                  ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  onPressed: () => _showAddServerScreen(context),
                  tooltip: '添加服务器',
                ),
              ],
            ),
          ),

          // 服务器列表
          Expanded(
            child: servers.servers.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: servers.servers.length,
                    itemBuilder: (context, index) {
                      final server = servers.servers[index];
                      final isSelected = server.id == servers.selectedServerId;
                      final isPinging = servers.isServerPinging(server.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ServerTile(
                          server: server,
                          isSelected: isSelected,
                          isPinging: isPinging,
                          onTap: () => _selectServer(context, server.id),
                          onEdit: () => _editServer(context, server),
                          onDelete: () => _deleteServer(context, server.id, server.name),
                          onPing: () => servers.pingServer(server),
                          onShare: () => _shareServer(context, server),
                        ).animate().fadeIn(
                          duration: 200.ms,
                          delay: (30 * index).ms,
                        ).slideX(
                          begin: 0.05,
                          end: 0,
                          duration: 200.ms,
                          delay: (30 * index).ms,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dns_outlined,
                size: 48,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '暂无服务器',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加服务器以开始使用 Phantom',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddServerScreen(context),
              icon: const Icon(Icons.add),
              label: const Text('添加服务器'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServerScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddServerScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _selectServer(BuildContext context, String id) {
    final connection = context.read<ConnectionProvider>();
    
    if (connection.isConnected) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('切换服务器'),
          content: const Text(
            '切换服务器前需要先断开连接。是否立即断开？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await connection.disconnect();
                if (context.mounted) {
                  context.read<ServersProvider>().selectServer(id);
                }
              },
              child: const Text('断开并切换'),
            ),
          ],
        ),
      );
    } else {
      context.read<ServersProvider>().selectServer(id);
    }
  }

  void _editServer(BuildContext context, Server server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddServerScreen(server: server),
        fullscreenDialog: true,
      ),
    );
  }

  void _deleteServer(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除 "$name" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ServersProvider>().deleteServer(id);
              Navigator.pop(ctx);
              context.showSnackBar('服务器已删除');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _shareServer(BuildContext context, Server server) {
    final link = server.toShareLink();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ShareServerSheet(
        serverName: server.name,
        shareLink: link,
      ),
    );
  }
}

class ShareServerSheet extends StatelessWidget {
  final String serverName;
  final String shareLink;

  const ShareServerSheet({
    super.key,
    required this.serverName,
    required this.shareLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '分享服务器',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serverName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  shareLink,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shareLink));
                Navigator.pop(context);
                context.showSnackBar('分享链接已复制');
              },
              icon: const Icon(Icons.copy),
              label: const Text('复制链接'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
