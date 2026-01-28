
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models.dart';
import '../../models/stats.dart';

class WebSocketClient {
  final String url;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // 消息流控制器
  final _messageController = StreamController<WsMessage>.broadcast();
  Stream<WsMessage> get messages => _messageController.stream;

  // 统计数据流
  final _statsController = StreamController<Stats>.broadcast();
  Stream<Stats> get statsStream => _statsController.stream;

  // 连接状态流
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionController.stream;

  // 连接结果流
  final _connectResultController = StreamController<bool>.broadcast();
  Stream<bool> get connectResult => _connectResultController.stream;

  bool get isConnected => _isConnected;

  WebSocketClient({required this.url});

  String get _wsUrl => url.startsWith('ws') ? url : 'ws://$url';

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (error) {
          print('WebSocket error: $error');
          _onDisconnected();
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _startHeartbeat();

      // 连接后立即请求统计数据
      sendGetStats();
    } catch (e) {
      print('WebSocket connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WsMessage.fromJson(json);

      // 发送到通用消息流
      _messageController.add(message);

      // 根据类型分发到特定流
      switch (message.type) {
        case WsMessageType.stats:
          if (message.data != null) {
            final stats = Stats.fromJson(message.data!);
            _statsController.add(stats);
          }
          break;

        case WsMessageType.connectResult:
          final success = message.success ?? false;
          _connectResultController.add(success);
          break;

        case WsMessageType.disconnectResult:
          _connectResultController.add(false);
          break;
      }
    } catch (e) {
      print('WebSocket message parse error: $e');
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
    _stopHeartbeat();

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached');
      return;
    }

    // 指数退避重连
    final delay = Duration(
      seconds: (1 << _reconnectAttempts.clamp(0, 5)),
    );

    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && !_isConnected) {
        _reconnectAttempts++;
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        sendGetStats();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('WebSocket send error: $e');
      }
    }
  }

  void sendConnect() {
    send(WsMessage(type: WsMessageType.connect).toJson());
  }

  void sendDisconnect() {
    send(WsMessage(type: WsMessageType.disconnect).toJson());
  }

  void sendGetStats() {
    send(WsMessage(type: WsMessageType.getStats).toJson());
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();

    await _subscription?.cancel();
    await _channel?.sink.close();

    _isConnected = false;
    _connectionController.add(false);
  }

  void resetReconnect() {
    _shouldReconnect = true;
    _reconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statsController.close();
    _connectionController.close();
    _connectResultController.close();
  }
}

