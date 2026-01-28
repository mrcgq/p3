// ============================================================
// lib/core/services/core_service.dart (修复)
// ============================================================

import 'dart:async';
import 'dart:io';

import '../api/api_client.dart';
import '../api/websocket_client.dart';
import '../api/models.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'config_service.dart';
import '../../models/server.dart';
import '../../models/stats.dart';
import '../../models/connection_state.dart';

/// 内核服务状态
enum CoreStatus {
  stopped,
  starting,
  running,
  stopping,
  error,
}

/// 内核服务 - 管理与 phantom-core 的通信
class CoreService {
  final ConfigService _configService;
  
  late ApiClient _apiClient;
  late WebSocketClient _wsClient;
  Process? _coreProcess;
  
  CoreStatus _status = CoreStatus.stopped;
  String? _lastError;
  
  // 流控制器
  final _statsController = StreamController<Stats>.broadcast();
  final _connectionController = StreamController<AppConnectionState>.broadcast();
  final _coreStatusController = StreamController<CoreStatus>.broadcast();
  
  // 当前状态
  AppConnectionState _connectionState = const AppConnectionState();
  Stats _currentStats = const Stats();

  // Getters
  CoreStatus get status => _status;
  String? get lastError => _lastError;
  bool get isRunning => _status == CoreStatus.running;
  bool get isStopped => _status == CoreStatus.stopped;
  AppConnectionState get connectionState => _connectionState;
  Stats get currentStats => _currentStats;

  // Streams
  Stream<Stats> get statsStream => _statsController.stream;
  Stream<AppConnectionState> get connectionStream => _connectionController.stream;
  Stream<CoreStatus> get coreStatusStream => _coreStatusController.stream;

  CoreService(this._configService);

  /// 初始化
  Future<void> init() async {
    final settings = _configService.settings;
    
    _apiClient = ApiClient(baseUrl: 'http://${settings.apiAddr}');
    _wsClient = WebSocketClient(url: 'ws://${settings.apiAddr}/ws');

    // 监听 WebSocket 消息
    _wsClient.statsStream.listen(_onStats);
    _wsClient.connectResult.listen(_onConnectResult);
    _wsClient.connectionStatus.listen(_onWsConnectionStatus);

    // 启动内核
    await _startCore();
    
    AppLogger.info('CoreService initialized');
  }

  /// 启动内核进程
  Future<void> _startCore() async {
    if (_status == CoreStatus.running || _status == CoreStatus.starting) {
      return;
    }

    _setStatus(CoreStatus.starting);

    try {
      // 查找内核可执行文件
      final corePath = await _findCorePath();
      if (corePath == null) {
        throw Exception('Core executable not found. Please ensure phantom-core is in the same directory.');
      }

      final settings = _configService.settings;

      // 构建启动参数
      final args = CoreArgs.build(
        apiAddr: settings.apiAddr,
        socksAddr: settings.socksAddr,
        httpAddr: settings.httpAddr,
        logLevel: settings.logLevel,
      );

      AppLogger.info('Starting core: $corePath ${args.join(' ')}');

      // 启动进程
      _coreProcess = await Process.start(corePath, args);

      // 监听进程输出
      _coreProcess!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        AppLogger.debug('Core stdout: $data');
      });

      _coreProcess!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        AppLogger.warning('Core stderr: $data');
      });

      // 监听进程退出
      _coreProcess!.exitCode.then((code) {
        AppLogger.info('Core process exited with code: $code');
        if (_status != CoreStatus.stopping) {
          _setStatus(CoreStatus.stopped);
          _lastError = 'Core process exited unexpectedly (code: $code)';
        }
      });

      // 等待内核启动
      await _waitForCoreReady();

      // 连接 WebSocket
      await _wsClient.connect();

      _setStatus(CoreStatus.running);
      AppLogger.info('Core started successfully');

    } catch (e, stack) {
      AppLogger.error('Failed to start core', e, stack);
      _lastError = e.toString();
      _setStatus(CoreStatus.error);
      rethrow;
    }
  }

  /// 等待内核就绪
  Future<void> _waitForCoreReady() async {
    const maxAttempts = 20;
    const delay = Duration(milliseconds: 250);

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(delay);
      
      try {
        if (await _apiClient.isRunning()) {
          return;
        }
      } catch (_) {
        // 继续等待
      }
    }

    throw Exception('Core failed to start within timeout');
  }

  /// 查找内核可执行文件
  Future<String?> _findCorePath() async {
    // 获取当前执行目录
    final execDir = File(Platform.resolvedExecutable).parent.path;
    
    // 搜索路径列表
    final searchPaths = [
      execDir,
      Directory.current.path,
      '$execDir/core',
      '.',
      './core',
      '../phantom-core/build',
    ];

    for (final dir in searchPaths) {
      for (final name in AppConstants.coreExecutableNames) {
        final path = '$dir/$name';
        if (await File(path).exists()) {
          return path;
        }
      }
    }

    return null;
  }

  void _setStatus(CoreStatus status) {
    _status = status;
    _coreStatusController.add(status);
  }

  void _onStats(Stats stats) {
    _currentStats = stats;
    _statsController.add(stats);

    // 更新连接状态
    if (stats.connected != _connectionState.isConnected) {
      _connectionState = _connectionState.copyWith(
        status: stats.connected
            ? ConnectionStatus.connected
            : ConnectionStatus.disconnected,
      );
      _connectionController.add(_connectionState);
    }
  }

  void _onConnectResult(bool success) {
    _connectionState = _connectionState.copyWith(
      status: success
          ? ConnectionStatus.connected
          : ConnectionStatus.error,
      errorMessage: success ? null : 'Connection failed',
    );
    _connectionController.add(_connectionState);
  }

  void _onWsConnectionStatus(bool connected) {
    if (!connected && _status == CoreStatus.running) {
      AppLogger.warning('WebSocket disconnected, attempting reconnect...');
    }
  }

  // ============ Public API ============

  /// 连接到服务器
  Future<bool> connect(Server server) async {
    if (!isRunning) {
      _lastError = 'Core is not running';
      return false;
    }

    try {
      _connectionState = _connectionState.copyWith(
        status: ConnectionStatus.connecting,
        errorMessage: null,
      );
      _connectionController.add(_connectionState);

      // 设置服务器配置
      final configSuccess = await _apiClient.setServerConfig(server);
      if (!configSuccess) {
        throw Exception('Failed to set server config');
      }

      // 发起连接
      final connectSuccess = await _apiClient.connect();
      if (!connectSuccess) {
        throw Exception('Failed to connect');
      }

      _connectionState = _connectionState.copyWith(
        status: ConnectionStatus.connected,
        serverAddress: '${server.address}:${server.activePort}',
        mode: server.mode,
        muxEnabled: server.mux.enabled,
        fecEnabled: server.fec.enabled,
        fecMode: server.fec.mode,
      );
      _connectionController.add(_connectionState);

      AppLogger.info('Connected to ${server.name}');
      return true;

    } catch (e, stack) {
      AppLogger.error('Connect failed', e, stack);
      _lastError = e.toString();
      
      _connectionState = _connectionState.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
      _connectionController.add(_connectionState);
      
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (!isRunning) return;

    try {
      _connectionState = _connectionState.copyWith(
        status: ConnectionStatus.disconnected,
      );
      _connectionController.add(_connectionState);

      await _apiClient.disconnect();
      
      AppLogger.info('Disconnected');
    } catch (e) {
      AppLogger.warning('Disconnect error', e);
    }
  }

  /// 获取状态
  Future<StatusResponse?> getStatus() async {
    if (!isRunning) return null;
    
    try {
      return await _apiClient.getStatus();
    } catch (e) {
      AppLogger.warning('Get status failed', e);
      return null;
    }
  }

  /// 获取统计
  Future<Stats> getStats() async {
    if (!isRunning) return const Stats();
    
    try {
      return await _apiClient.getStats();
    } catch (e) {
      AppLogger.warning('Get stats failed', e);
      return const Stats();
    }
  }

  /// 设置系统代理
  Future<bool> setSystemProxy(bool enable) async {
    if (!isRunning) return false;
    
    try {
      return await _apiClient.setSystemProxy(enable);
    } catch (e) {
      AppLogger.warning('Set system proxy failed', e);
      return false;
    }
  }

  /// 获取系统代理状态
  Future<bool> getSystemProxyStatus() async {
    if (!isRunning) return false;
    
    try {
      return await _apiClient.getSystemProxyStatus();
    } catch (e) {
      return false;
    }
  }

  /// Ping 服务器
  Future<int?> pingServer(Server server) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final socket = await Socket.connect(
        server.address,
        server.activePort,
        timeout: AppConstants.pingTimeout,
      );
      
      stopwatch.stop();
      await socket.close();
      
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      AppLogger.debug('Ping failed for ${server.address}', e);
      return null;
    }
  }

  /// 重启内核
  Future<void> restart() async {
    AppLogger.info('Restarting core...');
    await shutdown();
    await Future.delayed(const Duration(milliseconds: 500));
    await _startCore();
  }

  /// 关闭内核
  Future<void> shutdown() async {
    if (_status == CoreStatus.stopped || _status == CoreStatus.stopping) {
      return;
    }

    _setStatus(CoreStatus.stopping);

    try {
      // 断开连接
      await disconnect();

      // 关闭 WebSocket
      await _wsClient.disconnect();

      // 终止进程
      if (_coreProcess != null) {
        _coreProcess!.kill(ProcessSignal.sigterm);
        
        // 等待进程退出，最多5秒
        try {
          await _coreProcess!.exitCode.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              _coreProcess!.kill(ProcessSignal.sigkill);
              return -1;
            },
          );
        } catch (_) {}
        
        _coreProcess = null;
      }

      _setStatus(CoreStatus.stopped);
      AppLogger.info('Core stopped');
      
    } catch (e, stack) {
      AppLogger.error('Shutdown error', e, stack);
      _setStatus(CoreStatus.error);
    }
  }

  /// 释放资源
  void dispose() {
    shutdown();
    _statsController.close();
    _connectionController.close();
    _coreStatusController.close();
    _wsClient.dispose();
    _apiClient.dispose();
  }
}
