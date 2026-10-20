import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Ağ hatalarını tespit eden, kullanıcı dostu mesajlar üreten ve
/// geçici ağ kopmalarında otomatik yeniden deneme (retry) sağlayan yardımcı sınıf.
class NetworkHelper {
  static const Duration defaultTimeout = Duration(seconds: 8);

  /// Verilen hatanın bir ağ / bağlantı hatası olup olmadığını denetler.
  static bool isNetworkException(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HttpException ||
        error is HandshakeException) {
      return true;
    }

    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('connection refused') ||
        str.contains('connection reset') ||
        str.contains('connection closed') ||
        str.contains('network is unreachable') ||
        str.contains('clientexception') ||
        str.contains('timeoutexception') ||
        str.contains('timed out') ||
        str.contains('handshake');
  }

  /// Teknik hata mesajını son kullanıcı için anlaşılır Türkçe mesaja dönüştürür.
  static String getFriendlyErrorMessage(Object error) {
    if (error is TimeoutException || error.toString().toLowerCase().contains('timeoutexception') || error.toString().toLowerCase().contains('timed out')) {
      return 'Sunucu yanıt vermedi (Zaman aşımı). Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    }

    if (isNetworkException(error)) {
      return 'İnternet veya sunucu bağlantısı kurulamadı. Lütfen ağ bağlantınızı kontrol edin.';
    }

    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return 'Bir bağlantı hatası oluştu: $msg';
  }

  /// Belirtilen işlemi, ağ hatası durumunda [maxRetries] defa aralıklarla otomatik yeniden dener.
  static Future<T> executeWithRetry<T>(
    Future<T> Function() action, {
    int maxRetries = 2,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts > maxRetries || !isNetworkException(e)) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
  }

  /// HTTP POST isteğini otomatik zaman aşımı ve geçici ağ kopmalarında
  /// otomatik yeniden deneme ile gerçekleştirir.
  static Future<http.Response> postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
    int maxRetries = 1,
  }) async {
    return await executeWithRetry(
      () => http
          .post(url, headers: headers, body: body, encoding: encoding)
          .timeout(timeout),
      maxRetries: maxRetries,
    );
  }

  /// HTTP GET isteğini otomatik zaman aşımı ve geçici ağ kopmalarında
  /// otomatik yeniden deneme ile gerçekleştirir.
  static Future<http.Response> getWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = defaultTimeout,
    int maxRetries = 1,
  }) async {
    return await executeWithRetry(
      () => http.get(url, headers: headers).timeout(timeout),
      maxRetries: maxRetries,
    );
  }

  /// HTTP yanıtının 429 Too Many Requests (Rate Limit) olup olmadığını denetler.
  static bool isRateLimited(http.Response response) {
    if (response.statusCode == 429) return true;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['is_rate_limited'] == true) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Rate limit durumunda sunucunun belirttiği bekleme süresini (saniye) döndürür.
  static int parseRetryAfter(http.Response response, {int fallback = 60}) {
    // 1. Retry-After HTTP başlığını denetle
    final headerVal = response.headers['retry-after'];
    if (headerVal != null) {
      final parsed = int.tryParse(headerVal.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    // 2. JSON gövdesindeki 'retry_after' alanını denetle
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['retry_after'] != null) {
        final parsed = int.tryParse(decoded['retry_after'].toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}
    return fallback;
  }

  /// Rate limit yanıtından kullanıcı dostu mesaj üretir veya sunucu mesajını alır.
  static String getRateLimitMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['message'] != null &&
          decoded['message'].toString().trim().isNotEmpty) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    final retryAfter = parseRetryAfter(response);
    return 'Çok fazla istek gönderdiniz. Lütfen $retryAfter saniye sonra tekrar deneyiniz.';
  }

  /// Bir HTTP yanıtını güvenli biçimde Map olarak ayrıştırır; 429 veya hata durumlarını standart formata dönüştürür.
  static Map<String, dynamic> parseResponse(http.Response response) {
    if (isRateLimited(response)) {
      final retryAfter = parseRetryAfter(response);
      final msg = getRateLimitMessage(response);
      return {
        'status': 'error',
        'success': false,
        'code': 429,
        'is_rate_limited': true,
        'is_network_error': false,
        'retry_after': retryAfter,
        'message': msg,
      };
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode == 200) {
      return {
        'status': 'success',
        'success': true,
        'message': response.body,
      };
    }

    return {
      'status': 'error',
      'success': false,
      'code': response.statusCode,
      'is_network_error': false,
      'message': 'Sunucu hatası: HTTP ${response.statusCode}',
    };
  }
}
