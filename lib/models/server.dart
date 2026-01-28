
import 'dart:convert';

class Server {
  final String id;
  final String name;
  final String address;
  final int tcpPort;
  final int udpPort;
  final String psk;
  final String mode; // 'udp' or 'tcp'
  final TLSConfig tls;
  final FECConfig fec;
  final MuxConfig mux;
  final DateTime createdAt;
  final int? latency;

  Server({
    required this.id,
    required this.name,
    required this.address,
    this.tcpPort = 443,
    this.udpPort = 54321,
    required this.psk,
    this.mode = 'udp',
    TLSConfig? tls,
    FECConfig? fec,
    MuxConfig? mux,
    DateTime? createdAt,
    this.latency,
  })  : tls = tls ?? TLSConfig(),
        fec = fec ?? FECConfig(),
        mux = mux ?? MuxConfig(),
        createdAt = createdAt ?? DateTime.now();

  /// 获取当前模式对应的端口
  int get activePort => mode == 'tcp' ? tcpPort : udpPort;

  Server copyWith({
    String? id,
    String? name,
    String? address,
    int? tcpPort,
    int? udpPort,
    String? psk,
    String? mode,
    TLSConfig? tls,
    FECConfig? fec,
    MuxConfig? mux,
    DateTime? createdAt,
    int? latency,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      tcpPort: tcpPort ?? this.tcpPort,
      udpPort: udpPort ?? this.udpPort,
      psk: psk ?? this.psk,
      mode: mode ?? this.mode,
      tls: tls ?? this.tls,
      fec: fec ?? this.fec,
      mux: mux ?? this.mux,
      createdAt: createdAt ?? this.createdAt,
      latency: latency ?? this.latency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'tcp_port': tcpPort,
      'udp_port': udpPort,
      'psk': psk,
      'mode': mode,
      'tls': tls.toJson(),
      'fec': fec.toJson(),
      'mux': mux.toJson(),
      'created_at': createdAt.toIso8601String(),
      'latency': latency,
    };
  }

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      tcpPort: json['tcp_port'] as int? ?? 443,
      udpPort: json['udp_port'] as int? ?? 54321,
      psk: json['psk'] as String,
      mode: json['mode'] as String? ?? 'udp',
      tls: json['tls'] != null
          ? TLSConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : TLSConfig(),
      fec: json['fec'] != null
          ? FECConfig.fromJson(json['fec'] as Map<String, dynamic>)
          : FECConfig(),
      mux: json['mux'] != null
          ? MuxConfig.fromJson(json['mux'] as Map<String, dynamic>)
          : MuxConfig(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      latency: json['latency'] as int?,
    );
  }

  /// 从 phantom:// 分享链接解析
  static Server? fromShareLink(String link) {
    try {
      if (!link.startsWith('phantom://')) return null;

      var data = link.substring('phantom://'.length);
      String? name;

      // 提取 fragment 中的名称
      final hashIndex = data.indexOf('#');
      if (hashIndex != -1) {
        name = Uri.decodeComponent(data.substring(hashIndex + 1));
        data = data.substring(0, hashIndex);
      }

      // Base64 解码
      final json = jsonDecode(utf8.decode(base64Decode(data)));

      return Server(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? json['address'] ?? 'Imported Server',
        address: json['address'] as String,
        tcpPort: json['tcp_port'] as int? ?? 443,
        udpPort: json['udp_port'] as int? ?? 54321,
        psk: json['psk'] as String,
        mode: json['mode'] as String? ?? 'udp',
        tls: TLSConfig(
          enabled: json['tls']?['enabled'] as bool? ?? true,
          serverName: json['tls']?['server_name'] as String?,
          skipVerify: json['tls']?['skip_verify'] as bool? ?? false,
        ),
        fec: FECConfig(
          enabled: json['fec']?['enabled'] as bool? ?? true,
          mode: json['fec']?['mode'] as String? ?? 'adaptive',
          dataShards: json['fec']?['data_shards'] as int? ?? 10,
          fecShards: json['fec']?['fec_shards'] as int? ?? 3,
          minParity: json['fec']?['min_parity'] as int? ?? 1,
          maxParity: json['fec']?['max_parity'] as int? ?? 8,
        ),
        mux: MuxConfig(
          enabled: json['mux']?['enabled'] as bool? ?? true,
          maxStreams: json['mux']?['max_streams'] as int? ?? 256,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// 生成 phantom:// 分享链接
  String toShareLink() {
    final json = {
      'address': address,
      'tcp_port': tcpPort,
      'udp_port': udpPort,
      'psk': psk,
      'mode': mode,
      'tls': {
        'enabled': tls.enabled,
        'server_name': tls.serverName ?? address,
        'skip_verify': tls.skipVerify,
      },
      'fec': {
        'enabled': fec.enabled,
        'mode': fec.mode,
        'data_shards': fec.dataShards,
        'fec_shards': fec.fecShards,
        'min_parity': fec.minParity,
        'max_parity': fec.maxParity,
      },
      'mux': {
        'enabled': mux.enabled,
        'max_streams': mux.maxStreams,
      },
    };

    final encoded = base64Encode(utf8.encode(jsonEncode(json)));
    return 'phantom://$encoded#${Uri.encodeComponent(name)}';
  }

  /// 转换为内核API需要的服务器配置格式
  Map<String, dynamic> toApiConfig() {
    return {
      'address': address,
      'tcp_port': tcpPort,
      'udp_port': udpPort,
      'psk': psk,
      'mode': mode,
      'time_window': 30,
      'tls_enabled': tls.enabled,
      'server_name': tls.serverName ?? address,
      'skip_verify': tls.skipVerify,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Server && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// TLS 配置
class TLSConfig {
  final bool enabled;
  final String? serverName;
  final bool skipVerify;

  TLSConfig({
    this.enabled = true,
    this.serverName,
    this.skipVerify = false,
  });

  TLSConfig copyWith({
    bool? enabled,
    String? serverName,
    bool? skipVerify,
  }) {
    return TLSConfig(
      enabled: enabled ?? this.enabled,
      serverName: serverName ?? this.serverName,
      skipVerify: skipVerify ?? this.skipVerify,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'server_name': serverName,
        'skip_verify': skipVerify,
      };

  factory TLSConfig.fromJson(Map<String, dynamic> json) => TLSConfig(
        enabled: json['enabled'] as bool? ?? true,
        serverName: json['server_name'] as String?,
        skipVerify: json['skip_verify'] as bool? ?? false,
      );
}

/// FEC 配置
class FECConfig {
  final bool enabled;
  final String mode; // 'static' or 'adaptive'
  final int dataShards;
  final int fecShards;
  final int minParity;
  final int maxParity;
  final double targetLoss;

  FECConfig({
    this.enabled = true,
    this.mode = 'adaptive',
    this.dataShards = 10,
    this.fecShards = 3,
    this.minParity = 1,
    this.maxParity = 8,
    this.targetLoss = 0.01,
  });

  FECConfig copyWith({
    bool? enabled,
    String? mode,
    int? dataShards,
    int? fecShards,
    int? minParity,
    int? maxParity,
    double? targetLoss,
  }) {
    return FECConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      dataShards: dataShards ?? this.dataShards,
      fecShards: fecShards ?? this.fecShards,
      minParity: minParity ?? this.minParity,
      maxParity: maxParity ?? this.maxParity,
      targetLoss: targetLoss ?? this.targetLoss,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'mode': mode,
        'data_shards': dataShards,
        'fec_shards': fecShards,
        'min_parity': minParity,
        'max_parity': maxParity,
        'target_loss': targetLoss,
      };

  factory FECConfig.fromJson(Map<String, dynamic> json) => FECConfig(
        enabled: json['enabled'] as bool? ?? true,
        mode: json['mode'] as String? ?? 'adaptive',
        dataShards: json['data_shards'] as int? ?? 10,
        fecShards: json['fec_shards'] as int? ?? 3,
        minParity: json['min_parity'] as int? ?? 1,
        maxParity: json['max_parity'] as int? ?? 8,
        targetLoss: (json['target_loss'] as num?)?.toDouble() ?? 0.01,
      );

  bool get isAdaptive => mode == 'adaptive';
}

/// 多路复用配置
class MuxConfig {
  final bool enabled;
  final int maxStreams;
  final int streamBuffer;

  MuxConfig({
    this.enabled = true,
    this.maxStreams = 256,
    this.streamBuffer = 65536,
  });

  MuxConfig copyWith({
    bool? enabled,
    int? maxStreams,
    int? streamBuffer,
  }) {
    return MuxConfig(
      enabled: enabled ?? this.enabled,
      maxStreams: maxStreams ?? this.maxStreams,
      streamBuffer: streamBuffer ?? this.streamBuffer,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'max_streams': maxStreams,
        'stream_buffer': streamBuffer,
      };

  factory MuxConfig.fromJson(Map<String, dynamic> json) => MuxConfig(
        enabled: json['enabled'] as bool? ?? true,
        maxStreams: json['max_streams'] as int? ?? 256,
        streamBuffer: json['stream_buffer'] as int? ?? 65536,
      );
}
