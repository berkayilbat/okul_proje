import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_config.dart';
import '../utils/network_helper.dart';
import 'token_store.dart';

/// Tüm API istekleri için tek giriş noktası: Bearer token ekler, yeniden deneme
/// ve zaman aşımını [NetworkHelper] ile uygular, yanıtı standart Map biçiminde döndürür.
class ApiClient {
  final http.Client _client;
  final TokenStore tokenStore;
  final String Function() _baseUrl;
  final Duration timeout;

  /// 401 yanıtında (token geçersiz/süresi dolmuş) bir kez tetiklenir.
  FutureOr<void> Function()? onUnauthorized;

  ApiClient({
    http.Client? client,
    TokenStore? tokenStore,
    String Function()? baseUrl,
    this.onUnauthorized,
    this.timeout = NetworkHelper.defaultTimeout,
  })  : _client = client ?? http.Client(),
        tokenStore = tokenStore ?? SharedPrefsTokenStore(),
        _baseUrl = baseUrl ?? (() => ServerConfig.baseUrl);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('${_baseUrl()}/$clean');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await tokenStore.read();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query, int maxRetries = 1}) {
    return _run(() async {
      final headers = await _headers();
      return NetworkHelper.executeWithRetry(
        () => _client.get(_uri(path, query), headers: headers).timeout(timeout),
        maxRetries: maxRetries,
      );
    });
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, int maxRetries = 1}) {
    return _run(() async {
      final headers = await _headers(json: true);
      return NetworkHelper.executeWithRetry(
        () => _client
            .post(_uri(path), headers: headers, body: jsonEncode(body ?? {}))
            .timeout(timeout),
        maxRetries: maxRetries,
      );
    });
  }

  /// Çok parçalı yükleme. Gövde tek kullanımlık olduğundan her denemede
  /// [files] içindeki dosyalar yeniden okunarak yeni bir istek kurulur.
  /// [files]: alan adı -> dosya yolu listesi (örn. `{'avatar': [path]}`).
  Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, String>? fields,
    Map<String, List<String>>? files,
    int maxRetries = 0,
    Duration? uploadTimeout,
  }) {
    return _run(() async {
      final headers = await _headers();
      return NetworkHelper.executeWithRetry(() async {
        final request = http.MultipartRequest('POST', _uri(path))
          ..headers.addAll(headers)
          ..fields.addAll(fields ?? {});
        for (final entry in (files ?? {}).entries) {
          for (final filePath in entry.value) {
            request.files
                .add(await http.MultipartFile.fromPath(entry.key, filePath));
          }
        }
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      }, maxRetries: maxRetries)
          .timeout(uploadTimeout ?? const Duration(seconds: 60));
    });
  }

  Future<Map<String, dynamic>> _run(
      Future<http.Response> Function() send) async {
    try {
      final response = await send();
      final parsed = NetworkHelper.parseResponse(response);
      if (response.statusCode == 401) {
        await onUnauthorized?.call();
        return {
          ...parsed,
          'status': 'error',
          'success': false,
          'code': 401,
          'is_unauthorized': true,
          'is_network_error': false,
          'is_rate_limited': false,
        };
      }
      parsed.putIfAbsent('is_network_error', () => false);
      parsed.putIfAbsent('is_rate_limited', () => false);
      return parsed;
    } catch (e) {
      return {
        'status': 'error',
        'success': false,
        'is_network_error': NetworkHelper.isNetworkException(e),
        'is_rate_limited': false,
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }
}
