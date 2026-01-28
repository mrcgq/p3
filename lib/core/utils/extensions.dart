
import 'package:flutter/material.dart';

/// 字符串扩展
extension StringExtensions on String {
  /// 截断字符串
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// 是否是有效的IP地址
  bool get isValidIp {
    final ipv4Pattern = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    final ipv6Pattern = RegExp(
      r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$',
    );
    return ipv4Pattern.hasMatch(this) || ipv6Pattern.hasMatch(this);
  }

  /// 是否是有效的域名
  bool get isValidDomain {
    final pattern = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return pattern.hasMatch(this);
  }

  /// 是否是有效的地址（IP或域名）
  bool get isValidAddress => isValidIp || isValidDomain;

  /// 是否是有效的端口
  bool get isValidPort {
    final port = int.tryParse(this);
    return port != null && port > 0 && port <= 65535;
  }

  /// 是否是有效的Base64
  bool get isValidBase64 {
    try {
      final pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      return pattern.hasMatch(this) && length % 4 == 0;
    } catch (_) {
      return false;
    }
  }
}

/// 整数扩展
extension IntExtensions on int {
  /// 格式化字节数
  String formatBytes() {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化持续时间
  String formatDuration() {
    if (this < 60) return '${this}s';
    if (this < 3600) return '${this ~/ 60}m ${this % 60}s';
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  /// 格式化毫秒延迟
  String formatLatency() => '${this}ms';
}

/// Duration 扩展
extension DurationExtensions on Duration {
  /// 格式化为人类可读
  String formatHuman() {
    if (inSeconds < 60) return '${inSeconds}s';
    if (inMinutes < 60) return '${inMinutes}m ${inSeconds % 60}s';
    return '${inHours}h ${inMinutes % 60}m';
  }
}

/// BuildContext 扩展
extension BuildContextExtensions on BuildContext {
  /// 获取主题
  ThemeData get theme => Theme.of(this);

  /// 获取颜色方案
  ColorScheme get colorScheme => theme.colorScheme;

  /// 获取文本主题
  TextTheme get textTheme => theme.textTheme;

  /// 是否是暗色主题
  bool get isDark => theme.brightness == Brightness.dark;

  /// 屏幕尺寸
  Size get screenSize => MediaQuery.of(this).size;

  /// 屏幕宽度
  double get screenWidth => screenSize.width;

  /// 屏幕高度
  double get screenHeight => screenSize.height;

  /// 显示 SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : null,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}

