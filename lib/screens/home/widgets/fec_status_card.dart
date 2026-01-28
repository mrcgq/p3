// ============================================================
// lib/screens/home/widgets/fec_status_card.dart (中文版)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/stats_provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../theme/colors.dart';

class FecStatusCard extends StatelessWidget {
  const FecStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final connection = context.watch<ConnectionProvider>();
    final state = connection.state;

    if (!state.fecEnabled) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.healing,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'FEC 状态',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    state.fecMode == 'adaptive' ? '自适应' : '静态',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // FEC 统计
            Row(
              children: [
                Expanded(
                  child: _buildFecStat(
                    context,
                    label: '校验分片',
                    value: '${stats.currentParity}',
                    icon: Icons.layers,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFecStat(
                    context,
                    label: '丢包率',
                    value: stats.formattedLossRate,
                    icon: Icons.signal_cellular_alt,
                    color: AppColors.getLossRateColor(stats.lossRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFecStat(
                    context,
                    label: '已恢复',
                    value: '${stats.stats.fecRecovered}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFecStat(
                    context,
                    label: '恢复失败',
                    value: '${stats.stats.fecFailed}',
                    icon: Icons.error_outline,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),

            // 恢复率进度条
            if (stats.stats.fecRecovered + stats.stats.fecFailed > 0) ...[
              const SizedBox(height: 16),
              _buildRecoveryBar(context, stats),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFecStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryBar(BuildContext context, StatsProvider stats) {
    final recoveryRate = stats.stats.fecRecoveryRate;
    final color = AppColors.getFecRecoveryColor(recoveryRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '恢复率',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              stats.formattedFecRecoveryRate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: recoveryRate,
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
