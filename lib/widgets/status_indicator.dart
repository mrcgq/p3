// ============================================================
// lib/widgets/status_indicator.dart (修复)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../models/connection_state.dart';

class StatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final double size;
  final bool showPulse;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 10,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final shouldPulse = showPulse && status == ConnectionStatus.connected;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 脉冲动画
        if (shouldPulse)
          Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.3),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 1.seconds,
              )
              .fadeOut(duration: 1.seconds),

        // 主指示器
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: size,
                spreadRadius: size / 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return AppColors.warning;
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.error:
        return AppColors.error;
    }
  }
}
