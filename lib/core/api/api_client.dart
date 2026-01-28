
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'models.dart';
import '../../models/server.dart';
import '../../models/stats.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = http.Client();

  String get _apiBase => baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_apiBase$path'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: '无法连接到内核服务');
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: '请求超时');
    }
  }

  Future<Map<String, dynamic>> post(String path,
      [Map<String, dynamic>? body]) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiBase$path'),
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: '无法连接到内核服务');
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: '请求超时');
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$_apiBase$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: '无法连接到内核服务');
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: '请求超时');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$_apiBase$path'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(statusCode: 0, message: '无法连接到内核服务');
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: '请求超时');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _parseError(response.body),
    );
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error'] as String? ?? 'Unknown error';
    } catch (_) {
      return body.isNotEmpty ? body : 'Unknown error';
    }
  }

  // ============ 高级 API 方法 ============

  /// 获取连接状态
  Future<StatusResponse> getStatus() async {
    final data = await get('/api/status');
    return StatusResponse.fromJson(data);
  }

  /// 获取统计数据
  Future<Stats> getStats() async {
    final data = await get('/api/stats');
    return Stats.fromJson(data);
  }

  /// 连接服务器
  Future<bool> connect() async {
    try {
      await post('/api/connect');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 断开连接
  Future<bool> disconnect() async {
    try {
      await post('/api/disconnect');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 设置服务器配置
  Future<bool> setServerConfig(Server server) async {
    try {
      await put('/api/config/server', ServerConfigRequest(
        address: server.address,
        tcpPort: server.tcpPort,
        udpPort: server.udpPort,
        psk: server.psk,
        mode: server.mode,
        tlsEnabled: server.tls.enabled,
        serverName: server.tls.serverName ?? server.address,
        skipVerify: server.tls.skipVerify,
      ).toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 获取完整配置
  Future<Map<String, dynamic>> getConfig() async {
    return await get('/api/config');
  }

  /// 设置系统代理
  Future<bool> setSystemProxy(bool enable) async {
    try {
      await post('/api/sysproxy', SysProxyRequest(enable: enable).toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 获取系统代理状态
  Future<bool> getSystemProxyStatus() async {
    try {
      final data = await get('/api/sysproxy');
      return SysProxyResponse.fromJson(data).enabled;
    } catch (_) {
      return false;
    }
  }

  /// 检查内核是否运行
  Future<bool> isRunning() async {
    try {
      await getStatus();
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode] $message';

  bool get isConnectionError => statusCode == 0;
}


