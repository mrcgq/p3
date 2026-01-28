
/// API 响应基类
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);
  factory ApiResponse.failure(String error) =>
      ApiResponse(success: false, error: error);
}

/// 状态响应 - 对应 /api/status
class StatusResponse {
  final bool connected;
  final String serverAddr;
  final String mode;
  final bool muxEnabled;
  final bool fecEnabled;
  final String fecMode;
  final int currentParity;
  final double lossRate;
  final int streamCount;

  StatusResponse({
    required this.connected,
    required this.serverAddr,
    required this.mode,
    required this.muxEnabled,
    required this.fecEnabled,
    required this.fecMode,
    required this.currentParity,
    required this.lossRate,
    required this.streamCount,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      connected: json['connected'] as bool? ?? false,
      serverAddr: json['server_addr'] as String? ?? '',
      mode: json['mode'] as String? ?? 'udp',
      muxEnabled: json['mux_enabled'] as bool? ?? false,
      fecEnabled: json['fec_enabled'] as bool? ?? false,
      fecMode: json['fec_mode'] as String? ?? 'adaptive',
      currentParity: json['current_parity'] as int? ?? 0,
      lossRate: (json['loss_rate'] as num?)?.toDouble() ?? 0.0,
      streamCount: json['stream_count'] as int? ?? 0,
    );
  }
}

/// 服务器配置请求 - 对应 /api/config/server
class ServerConfigRequest {
  final String address;
  final int tcpPort;
  final int udpPort;
  final String psk;
  final String mode;
  final bool tlsEnabled;
  final String serverName;
  final bool skipVerify;

  ServerConfigRequest({
    required this.address,
    required this.tcpPort,
    required this.udpPort,
    required this.psk,
    required this.mode,
    required this.tlsEnabled,
    required this.serverName,
    this.skipVerify = false,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'tcp_port': tcpPort,
        'udp_port': udpPort,
        'psk': psk,
        'mode': mode,
        'tls_enabled': tlsEnabled,
        'server_name': serverName,
        'skip_verify': skipVerify,
      };
}

/// 系统代理请求 - 对应 /api/sysproxy
class SysProxyRequest {
  final bool enable;

  SysProxyRequest({required this.enable});

  Map<String, dynamic> toJson() => {'enable': enable};
}

/// 系统代理响应
class SysProxyResponse {
  final bool enabled;

  SysProxyResponse({required this.enabled});

  factory SysProxyResponse.fromJson(Map<String, dynamic> json) {
    return SysProxyResponse(enabled: json['enabled'] as bool? ?? false);
  }
}

/// WebSocket 消息类型
class WsMessageType {
  static const String stats = 'stats';
  static const String connectResult = 'connect_result';
  static const String disconnectResult = 'disconnect_result';
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String getStats = 'get_stats';
}

/// WebSocket 消息
class WsMessage {
  final String type;
  final Map<String, dynamic>? data;
  final bool? success;
  final String? error;

  WsMessage({
    required this.type,
    this.data,
    this.success,
    this.error,
  });

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      success: json['success'] as bool?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type};
    if (data != null) map['data'] = data;
    return map;
  }
}

