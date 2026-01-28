// ============================================================
// lib/models/server.dart (兼容服务端和GUI格式)
// ============================================================

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

  /// 从 phantom:// 分享链接解析（兼容服务端简化格式和GUI完整格式）
  static Server? fromShareLink(String link) {
    try {
      if (!link.startsWith('phantom://')) return null;

      var data = link.substring('phantom://'.length);
      String? name;

      // 提取 fragment 中的名称（#后面的部分）
      final hashIndex = data.indexOf('#');
      if (hashIndex != -1) {
        name = Uri.decodeComponent(data.substring(hashIndex + 1));
        data = data.substring(0, hashIndex);
      }

      // Base64 解码
      String jsonStr;
      try {
        jsonStr = utf8.decode(base64Decode(data));
      } catch (e) {
        // 尝试 URL-safe Base64
        final normalBase64 = data.replaceAll('-', '+').replaceAll('_', '/');
        jsonStr = utf8.decode(base64Decode(normalBase64));
      }
      
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // ========== 兼容服务端格式 ==========
      
      // 地址：服务端用 "server"，GUI用 "address"
      final address = json['address'] as String? ?? 
                      json['server'] as String? ?? 
                      '';
      
      if (address.isEmpty) {
        throw Exception('缺少服务器地址');
      }

      // PSK
      final psk = json['psk'] as String? ?? '';
      if (psk.isEmpty) {
        throw Exception('缺少PSK');
      }

      // 端口
      final tcpPort = json['tcp_port'] as int? ?? 443;
      final udpPort = json['udp_port'] as int? ?? 54321;

      // 模式：服务端格式没有此字段，默认 udp
      final mode = json['mode'] as String? ?? 'udp';

      // ========== TLS 配置 ==========
      // 服务端格式：tls: true/false（布尔值）
      // GUI格式：tls: {enabled: true, server_name: "...", skip_verify: false}（对象）
      bool tlsEnabled = true;
      String? serverName;
      bool skipVerify = false;
      
      final tlsValue = json['tls'];
      if (tlsValue == null) {
        tlsEnabled = true;
        serverName = address;
      } else if (tlsValue is bool) {
        // 服务端简化格式
        tlsEnabled = tlsValue;
        serverName = address;
      } else if (tlsValue is Map<String, dynamic>) {
        // GUI完整格式
        tlsEnabled = tlsValue['enabled'] as bool? ?? true;
        serverName = tlsValue['server_name'] as String? ?? address;
        skipVerify = tlsValue['skip_verify'] as bool? ?? false;
      }

      // ========== FEC 配置 ==========
      // 服务端格式：fec: "adaptive"/"static"（字符串）或 true/false（布尔值）
      // GUI格式：fec: {enabled: true, mode: "adaptive", ...}（对象）
      bool fecEnabled = true;
      String fecMode = 'adaptive';
      int dataShards = 10;
      int fecShards = 3;
      int minParity = 1;
      int maxParity = 8;
      double targetLoss = 0.01;
      
      final fecValue = json['fec'];
      if (fecValue == null) {
        fecEnabled = true;
        fecMode = 'adaptive';
      } else if (fecValue is String) {
        // 服务端格式：直接是模式字符串
        fecEnabled = true;
        fecMode = fecValue;
      } else if (fecValue is bool) {
        // 服务端格式：布尔值
        fecEnabled = fecValue;
        fecMode = 'adaptive';
      } else if (fecValue is Map<String, dynamic>) {
        // GUI完整格式
        fecEnabled = fecValue['enabled'] as bool? ?? true;
        fecMode = fecValue['mode'] as String? ?? 'adaptive';
        dataShards = fecValue['data_shards'] as int? ?? 10;
        fecShards = fecValue['fec_shards'] as int? ?? 3;
        minParity = fecValue['min_parity'] as int? ?? 1;
        maxParity = fecValue['max_parity'] as int? ?? 8;
        targetLoss = (fecValue['target_loss'] as num?)?.toDouble() ?? 0.01;
      }

      // ========== MUX 配置 ==========
      // 服务端格式：mux: true/false（布尔值）
      // GUI格式：mux: {enabled: true, max_streams: 256}（对象）
      bool muxEnabled = true;
      int maxStreams = 256;
      int streamBuffer = 65536;
      
      final muxValue = json['mux'];
      if (muxValue == null) {
        muxEnabled = true;
      } else if (muxValue is bool) {
        // 服务端简化格式
        muxEnabled = muxValue;
      } else if (muxValue is Map<String, dynamic>) {
        // GUI完整格式
        muxEnabled = muxValue['enabled'] as bool? ?? true;
        maxStreams = muxValue['max_streams'] as int? ?? 256;
        streamBuffer = muxValue['stream_buffer'] as int? ?? 65536;
      }

      // 使用地址作为默认名称
      final serverName2 = name ?? json['name'] as String? ?? address;

      return Server(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: serverName2,
        address: address,
        tcpPort: tcpPort,
        udpPort: udpPort,
        psk: psk,
        mode: mode,
        tls: TLSConfig(
          enabled: tlsEnabled,
          serverName: serverName,
          skipVerify: skipVerify,
        ),
        fec: FECConfig(
          enabled: fecEnabled,
          mode: fecMode,
          dataShards: dataShards,
          fecShards: fecShards,
          minParity: minParity,
          maxParity: maxParity,
          targetLoss: targetLoss,
        ),
        mux: MuxConfig(
          enabled: muxEnabled,
          maxStreams: maxStreams,
          streamBuffer: streamBuffer,
        ),
      );
    } catch (e) {
      print('解析分享链接失败: $e');
      return null;
    }
  }

  /// 生成 phantom:// 分享链接（GUI完整格式）
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

  /// 生成服务端兼容的简化分享链接
  String toSimpleShareLink() {
    final json = {
      'version': 1,
      'server': address,
      'tcp_port': tcpPort,
      'udp_port': udpPort,
      'psk': psk,
      'tls': tls.enabled,
      'fec': fec.enabled ? fec.mode : false,
      'mux': mux.enabled,
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
