
class Stats {
  final int upload;
  final int download;
  final int uploadSpeed;
  final int downloadSpeed;
  final int connections;
  final int uptime;
  final bool connected;
  
  // FEC 相关统计
  final int fecRecovered;
  final int fecFailed;
  final int currentParity;
  final double lossRate;

  const Stats({
    this.upload = 0,
    this.download = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.connections = 0,
    this.uptime = 0,
    this.connected = false,
    this.fecRecovered = 0,
    this.fecFailed = 0,
    this.currentParity = 0,
    this.lossRate = 0.0,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      upload: json['upload'] as int? ?? 0,
      download: json['download'] as int? ?? 0,
      uploadSpeed: json['upload_speed'] as int? ?? 0,
      downloadSpeed: json['download_speed'] as int? ?? 0,
      connections: json['connections'] as int? ?? 0,
      uptime: json['uptime'] as int? ?? 0,
      connected: json['connected'] as bool? ?? false,
      fecRecovered: json['fec_recovered'] as int? ?? 0,
      fecFailed: json['fec_failed'] as int? ?? 0,
      currentParity: json['current_parity'] as int? ?? 0,
      lossRate: (json['loss_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'upload': upload,
        'download': download,
        'upload_speed': uploadSpeed,
        'download_speed': downloadSpeed,
        'connections': connections,
        'uptime': uptime,
        'connected': connected,
        'fec_recovered': fecRecovered,
        'fec_failed': fecFailed,
        'current_parity': currentParity,
        'loss_rate': lossRate,
      };

  Stats copyWith({
    int? upload,
    int? download,
    int? uploadSpeed,
    int? downloadSpeed,
    int? connections,
    int? uptime,
    bool? connected,
    int? fecRecovered,
    int? fecFailed,
    int? currentParity,
    double? lossRate,
  }) {
    return Stats(
      upload: upload ?? this.upload,
      download: download ?? this.download,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      connections: connections ?? this.connections,
      uptime: uptime ?? this.uptime,
      connected: connected ?? this.connected,
      fecRecovered: fecRecovered ?? this.fecRecovered,
      fecFailed: fecFailed ?? this.fecFailed,
      currentParity: currentParity ?? this.currentParity,
      lossRate: lossRate ?? this.lossRate,
    );
  }

  // 格式化方法
  String get formattedUpload => _formatBytes(upload);
  String get formattedDownload => _formatBytes(download);
  String get formattedUploadSpeed => '${_formatBytes(uploadSpeed)}/s';
  String get formattedDownloadSpeed => '${_formatBytes(downloadSpeed)}/s';

  String get formattedUptime {
    if (uptime < 60) return '${uptime}s';
    if (uptime < 3600) return '${uptime ~/ 60}m ${uptime % 60}s';
    final hours = uptime ~/ 3600;
    final minutes = (uptime % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get formattedLossRate => '${(lossRate * 100).toStringAsFixed(2)}%';

  /// FEC 恢复率
  double get fecRecoveryRate {
    final total = fecRecovered + fecFailed;
    if (total == 0) return 0.0;
    return fecRecovered / total;
  }

  String get formattedFecRecoveryRate =>
      '${(fecRecoveryRate * 100).toStringAsFixed(1)}%';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}


