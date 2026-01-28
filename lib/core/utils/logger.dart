
import 'dart:developer' as developer;

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 简单日志工具
class AppLogger {
  static LogLevel _minLevel = LogLevel.debug;

  static set minLevel(LogLevel level) => _minLevel = level;

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (level.index < _minLevel.index) return;

    final prefix = _levelPrefix(level);
    final fullMessage = error != null ? '$message: $error' : message;

    developer.log(
      '$prefix $fullMessage',
      name: 'Phantom',
      error: error,
      stackTrace: stackTrace,
      level: _levelValue(level),
    );
  }

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }

  static int _levelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
