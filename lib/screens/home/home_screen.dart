
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/connection_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/servers_provider.dart';
import '../../core/services/core_service.dart';
import '../../theme/colors.dart';
import 'widgets/connection_card.dart';
import 'widgets/stats_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/fec_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coreService = context.watch<CoreService>();
    
    return RefreshIndicator(
      onRefresh: () async {
        // 刷新统计数据
        await coreService.getStats();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 连接卡片
            const ConnectionCard()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // 统计卡片
            const StatsCard()
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // FEC 状态卡片（仅在连接时显示）
            Consumer<ConnectionProvider>(
              builder: (context, connection, _) {
                if (!connection.isConnected) return const SizedBox.shrink();
                return const FecStatusCard()
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 150.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
            
            const SizedBox(height: 16),
            
            // 快捷操作
            const QuickActions()
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

