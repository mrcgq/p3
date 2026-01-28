
import 'dart:async';
import 'package:flutter/material.dart';

import '../core/services/core_service.dart';
import '../core/services/tray_service.dart';
import '../core/utils/logger.dart';
import '../models/server.dart';
import '../models/connection_state.dart';
import 'servers_provider.dart';

/// 连接状态管理
class ConnectionProvider extends ChangeNotifier {
  final CoreService _coreService;
  final ServersProvider _serversProvider;
  TrayService? _trayService;

  ConnectionState _state = const ConnectionState();
  StreamSubscription? _connectionSubscription;
  DateTime? _connectedAt;

  // Getters
  ConnectionState get state => _state;
  ConnectionStatus get status => _state.status;
  String? get errorMessage => _state.errorMessage;
  
  bool get isConnected => _state.isConnected;
  bool get isConnecting => _state.isConnecting;
  bool get isDisconnected => _state.isDisconnected;
  bool get hasError => _state.hasError;
  
  bool get canConnect => isDisconnected && _serversProvider.selectedServer != null;
  bool get canDisconnect => isConnected || isConnecting;
  
  Server? get currentServer => _serversProvider.selectedServer;
  Duration? get connectionDuration =>
      _connectedAt != null ? DateTime.now().difference(_connectedAt!) : null;

  ConnectionProvider(this._coreService, this._serversProvider) {
    _connectionSubscription = _coreService.connectionStream.listen(_onStateChange);
  }

  /// 设置托盘服务引用
  void setTrayService(TrayService trayService) {
    _trayService = trayService;
  }

  void _onStateChange(ConnectionState newState) {
    final wasConnected = _state.isConnected;
    _state = newState;

    if (newState.isConnected && !wasConnected) {
      _connectedAt = DateTime.now();
    } else if (!newState.isConnected && wasConnected) {
      _connectedAt = null;
    }

    // 更新托盘状态
    _trayService?.updateConnectionStatus(newState.isConnected);

    notifyListeners();
  }

  /// 连接
  Future<bool> connect() async {
    final server = _serversProvider.selectedServer;
    if (server == null) {
      _state = _state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'No server selected',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(
      status: ConnectionStatus.connecting,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final success = await _coreService.connect(server);
      
      if (success) {
        _state = _state.copyWith(
          status: ConnectionStatus.connected,
          serverAddress: '${server.address}:${server.activePort}',
          mode: server.mode,
          muxEnabled: server.mux.enabled,
          fecEnabled: server.fec.enabled,
          fecMode: server.fec.mode,
        );
        _connectedAt = DateTime.now();
        AppLogger.info('Connected to ${server.name}');
      } else {
        _state = _state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: _coreService.lastError ?? 'Connection failed',
        );
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _state = _state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (!canDisconnect) return;

    _state = _state.copyWith(status: ConnectionStatus.disconnected);
    notifyListeners();

    await _coreService.disconnect();
    _connectedAt = null;

    AppLogger.info('Disconnected');
  }

  /// 切换连接状态
  Future<void> toggle() async {
    if (isConnected || isConnecting) {
      await disconnect();
    } else if (canConnect) {
      await connect();
    }
  }

  /// 重新连接
  Future<bool> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    return await connect();
  }

  /// 清除错误
  void clearError() {
    if (_state.hasError) {
      _state = _state.copyWith(
        status: ConnectionStatus.disconnected,
        errorMessage: null,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

