
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';

import '../core/services/core_service.dart';
import '../models/stats.dart';

/// 统计数据管理
class StatsProvider extends ChangeNotifier {
  final CoreService _coreService;
  
  Stats _stats = const Stats();
  StreamSubscription? _subscription;

  // 历史数据（用于图表）
  static const int _historyLength = 60;
  final Queue<double> _uploadSpeedHistory = Queue<double>();
  final Queue<double> _downloadSpeedHistory = Queue<double>();
  final Queue<double> _lossRateHistory = Queue<double>();

  // Getters
  Stats get stats => _stats;
  bool get isConnected => _stats.connected;

  List<double> get uploadSpeedHistory => _uploadSpeedHistory.toList();
  List<double> get downloadSpeedHistory => _downloadSpeedHistory.toList();
  List<double> get lossRateHistory => _lossRateHistory.toList();

  // 便捷访问
  String get formattedUpload => _stats.formattedUpload;
  String get formattedDownload => _stats.formattedDownload;
  String get formattedUploadSpeed => _stats.formattedUploadSpeed;
  String get formattedDownloadSpeed => _stats.formattedDownloadSpeed;
  String get formattedUptime => _stats.formattedUptime;
  String get formattedLossRate => _stats.formattedLossRate;
  String get formattedFecRecoveryRate => _stats.formattedFecRecoveryRate;

  int get connections => _stats.connections;
  int get currentParity => _stats.currentParity;
  double get lossRate => _stats.lossRate;

  // 峰值速度
  double _peakUploadSpeed = 0;
  double _peakDownloadSpeed = 0;
  
  double get peakUploadSpeed => _peakUploadSpeed;
  double get peakDownloadSpeed => _peakDownloadSpeed;

  StatsProvider(this._coreService) {
    _initHistory();
    _subscription = _coreService.statsStream.listen(_onStats);
  }

  void _initHistory() {
    for (var i = 0; i < _historyLength; i++) {
      _uploadSpeedHistory.add(0);
      _downloadSpeedHistory.add(0);
      _lossRateHistory.add(0);
    }
  }

  void _onStats(Stats stats) {
    _stats = stats;

    // 更新历史
    _uploadSpeedHistory.removeFirst();
    _uploadSpeedHistory.add(stats.uploadSpeed.toDouble());
    
    _downloadSpeedHistory.removeFirst();
    _downloadSpeedHistory.add(stats.downloadSpeed.toDouble());
    
    _lossRateHistory.removeFirst();
    _lossRateHistory.add(stats.lossRate);

    // 更新峰值
    if (stats.uploadSpeed > _peakUploadSpeed) {
      _peakUploadSpeed = stats.uploadSpeed.toDouble();
    }
    if (stats.downloadSpeed > _peakDownloadSpeed) {
      _peakDownloadSpeed = stats.downloadSpeed.toDouble();
    }

    notifyListeners();
  }

  /// 重置统计
  void reset() {
    _stats = const Stats();
    _peakUploadSpeed = 0;
    _peakDownloadSpeed = 0;
    
    _uploadSpeedHistory.clear();
    _downloadSpeedHistory.clear();
    _lossRateHistory.clear();
    _initHistory();
    
    notifyListeners();
  }

  /// 获取图表数据点
  List<ChartDataPoint> getChartData(SpeedType type) {
    final history = type == SpeedType.upload
        ? _uploadSpeedHistory
        : _downloadSpeedHistory;

    return history.toList().asMap().entries.map((entry) {
      return ChartDataPoint(
        x: entry.key.toDouble(),
        y: entry.value / 1024 / 1024, // 转换为 MB/s
      );
    }).toList();
  }

  /// 获取当前最大速度（用于图表Y轴）
  double getMaxSpeed() {
    final maxUpload = _uploadSpeedHistory.reduce((a, b) => a > b ? a : b);
    final maxDownload = _downloadSpeedHistory.reduce((a, b) => a > b ? a : b);
    final max = maxUpload > maxDownload ? maxUpload : maxDownload;
    return max > 0 ? max / 1024 / 1024 * 1.2 : 1; // 转换为 MB/s，增加 20% 边距
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// 速度类型
enum SpeedType { upload, download }

/// 图表数据点
class ChartDataPoint {
  final double x;
  final double y;

  ChartDataPoint({required this.x, required this.y});
}


