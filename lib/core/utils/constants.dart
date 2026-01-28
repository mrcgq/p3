
/// 应用常量
class AppConstants {
  // 版本信息
  static const String appName = 'Phantom';
  static const String appVersion = '1.1.0';
  static const String coreVersion = '1.1.0';

  // 默认端口
  static const int defaultSocksPort = 1080;
  static const int defaultHttpPort = 1081;
  static const int defaultApiPort = 19080;
  static const int defaultTcpPort = 443;
  static const int defaultUdpPort = 54321;

  // 超时设置
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration pingTimeout = Duration(seconds: 5);

  // 内核可执行文件名
  static const List<String> coreExecutableNames = [
    'phantom-core',
    'phantom-core.exe',
  ];

  // 分享链接前缀
  static const String shareLinkPrefix = 'phantom://';

  // GitHub 链接
  static const String githubUrl = 'https://github.com/anthropics/phantom';
  static const String issuesUrl = 'https://github.com/anthropics/phantom/issues';
}

/// 内核进程参数
class CoreArgs {
  static List<String> build({
    required String apiAddr,
    required String socksAddr,
    required String httpAddr,
    String logLevel = 'info',
  }) {
    return [
      '-api', apiAddr,
      '-socks', socksAddr,
      '-http', httpAddr,
      '-log', logLevel,
    ];
  }
}


