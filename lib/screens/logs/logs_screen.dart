
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
    // TODO: 订阅日志流
    _addDemoLogs();
  }

  void _addDemoLogs() {
    _logs.addAll([
      LogEntry(level: 'INFO', message: 'Phantom Core started', time: DateTime.now()),
      LogEntry(level: 'DEBUG', message: 'API server listening on 127.0.0.1:19080', time: DateTime.now()),
      LogEntry(level: 'INFO', message: 'SOCKS5 server listening on 127.0.0.1:1080', time: DateTime.now()),
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
        title: const Text('Logs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'debug', child: Text('Debug')),
              const PopupMenuItem(value: 'info', child: Text('Info')),
              const PopupMenuItem(value: 'warn', child: Text('Warning')),
              const PopupMenuItem(value: 'error', child: Text('Error')),
            ],
          ),
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.pause),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
            tooltip: _autoScroll ? 'Pause auto-scroll' : 'Resume auto-scroll',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: filteredLogs.isEmpty
          ? Center(
              child: Text(
                'No logs',
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
              log.level,
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
    context.showSnackBar('Logs copied to clipboard');
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

