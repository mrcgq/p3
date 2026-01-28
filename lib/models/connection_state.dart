
// 连接状态枚举
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

// 连接状态信息
class ConnectionState {
  final ConnectionStatus status;
  final String? errorMessage;
  final DateTime? connectedAt;
  final String? serverAddress;
  final String? mode;
  final bool muxEnabled;
  final bool fecEnabled;
  final String? fecMode;
  final int currentParity;
  final double lossRate;
  final int streamCount;

  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.errorMessage,
    this.connectedAt,
    this.serverAddress,
    this.mode,
    this.muxEnabled = false,
    this.fecEnabled = false,
    this.fecMode,
    this.currentParity = 0,
    this.lossRate = 0.0,
    this.streamCount = 0,
  });

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get hasError => status == ConnectionStatus.error;

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? errorMessage,
    DateTime? connectedAt,
    String? serverAddress,
    String? mode,
    bool? muxEnabled,
    bool? fecEnabled,
    String? fecMode,
    int? currentParity,
    double? lossRate,
    int? streamCount,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      serverAddress: serverAddress ?? this.serverAddress,
      mode: mode ?? this.mode,
      muxEnabled: muxEnabled ?? this.muxEnabled,
      fecEnabled: fecEnabled ?? this.fecEnabled,
      fecMode: fecMode ?? this.fecMode,
      currentParity: currentParity ?? this.currentParity,
      lossRate: lossRate ?? this.lossRate,
      streamCount: streamCount ?? this.streamCount,
    );
  }

  factory ConnectionState.fromStatusResponse(Map<String, dynamic> json) {
    return ConnectionState(
      status: json['connected'] == true
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected,
      serverAddress: json['server_addr'] as String?,
      mode: json['mode'] as String?,
      muxEnabled: json['mux_enabled'] as bool? ?? false,
      fecEnabled: json['fec_enabled'] as bool? ?? false,
      fecMode: json['fec_mode'] as String?,
      currentParity: json['current_parity'] as int? ?? 0,
      lossRate: (json['loss_rate'] as num?)?.toDouble() ?? 0.0,
      streamCount: json['stream_count'] as int? ?? 0,
    );
  }
}
