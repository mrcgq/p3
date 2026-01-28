// ============================================================
// lib/screens/logs/logs_screen.dart (中文版)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';
import '../../core/utils/extensions.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _addDemoLogs();
  }

  void _addDemoLogs() {
    _logs.addAll([
      LogEntry(level: 'INFO', message: 'Phantom 内核已启动', time: DateTime.now()),
      LogEntry(level: 'DEBUG', message: 'API 服务器监听于 127.0.0.1:19080', time: DateTime.now()),
      LogEntry(level: 'INFO', message: 'SOCKS5 服务器监听于 127.0.0.1:1080', time: DateTime.now()),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filter == 'all'
        ? _logs
        : _logs.where((l) => l.level.toLowerCase() == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'debug', child: Text('调试')),
              const PopupMenuItem(value: 'info', child: Text('信息')),
              const PopupMenuItem(value: 'warn', child: Text('警告')),
              const PopupMenuItem(value: 'error', child: Text('错误')),
            ],
          ),
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.pause),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
            tooltip: _autoScroll ? '暂停自动滚动' : '恢复自动滚动',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: '复制日志',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: '清空日志',
          ),
        ],
      ),
      body: filteredLogs.isEmpty
          ? Center(
              child: Text(
                '暂无日志',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _buildLogItem(context, log);
              },
            ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogEntry log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间
          Text(
            _formatTime(log.time),
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 8),
          // 级别
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getLevelColor(log.level).withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _getLevelText(log.level),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getLevelColor(log.level),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // 消息
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  String _getLevelText(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return '调试';
      case 'info':
        return '信息';
      case 'warn':
      case 'warning':
        return '警告';
      case 'error':
        return '错误';
      default:
        return level;
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return AppColors.info;
      case 'info':
        return AppColors.success;
      case 'warn':
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  void _copyLogs() {
    final text = _logs.map((l) => '[${_formatTime(l.time)}] [${l.level}] ${l.message}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    context.showSnackBar('日志已复制到剪贴板');
  }
}

class LogEntry {
  final String level;
  final String message;
  final DateTime time;

  LogEntry({
    required this.level,
    required this.message,
    required this.time,
  });
}
