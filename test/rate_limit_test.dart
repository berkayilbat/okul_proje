import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/utils/network_helper.dart';

http.Response utf8Response(String body, int statusCode, {Map<String, String>? headers}) {
  final Map<String, String> allHeaders = {
    'content-type': 'application/json; charset=utf-8',
    ...?headers,
  };
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: allHeaders,
  );
}

void main() {
  group('Rate Limiting Client Helper Tests (Item 1.8)', () {
    test('isRateLimited returns true for HTTP 429 status code', () {
      final response = http.Response('Too Many Requests', 429);
      expect(NetworkHelper.isRateLimited(response), isTrue);
    });

    test('isRateLimited returns true for JSON with is_rate_limited: true', () {
      final response = utf8Response(
        jsonEncode({'status': 'error', 'is_rate_limited': true, 'message': 'Sınır aşıldı'}),
        200,
      );
      expect(NetworkHelper.isRateLimited(response), isTrue);
    });

    test('isRateLimited returns false for normal HTTP 200 success response', () {
      final response = utf8Response(
        jsonEncode({'status': 'success', 'data': []}),
        200,
      );
      expect(NetworkHelper.isRateLimited(response), isFalse);
    });

    test('parseRetryAfter extracts seconds from Retry-After HTTP header', () {
      final response = utf8Response(
        'Too Many Requests',
        429,
        headers: {'retry-after': '45'},
      );
      expect(NetworkHelper.parseRetryAfter(response), 45);
    });

    test('parseRetryAfter extracts seconds from JSON retry_after field when header is absent', () {
      final response = utf8Response(
        jsonEncode({'status': 'error', 'retry_after': 30}),
        429,
      );
      expect(NetworkHelper.parseRetryAfter(response), 30);
    });

    test('parseRetryAfter uses fallback when no duration is specified', () {
      final response = utf8Response('Rate limit exceeded', 429);
      expect(NetworkHelper.parseRetryAfter(response, fallback: 60), 60);
    });

    test('getRateLimitMessage extracts backend Turkish message', () {
      final response = utf8Response(
        jsonEncode({
          'status': 'error',
          'is_rate_limited': true,
          'retry_after': 60,
          'message': 'Çok fazla istek gönderdiniz. Lütfen 60 saniye sonra tekrar deneyiniz.'
        }),
        429,
      );
      expect(
        NetworkHelper.getRateLimitMessage(response),
        'Çok fazla istek gönderdiniz. Lütfen 60 saniye sonra tekrar deneyiniz.',
      );
    });

    test('parseResponse transforms 429 response into uniform rate limit map', () {
      final response = utf8Response(
        jsonEncode({
          'status': 'error',
          'code': 429,
          'is_rate_limited': true,
          'retry_after': 120,
          'message': 'Çok fazla istek gönderdiniz. Lütfen 120 saniye sonra tekrar deneyiniz.'
        }),
        429,
        headers: {'retry-after': '120'},
      );

      final result = NetworkHelper.parseResponse(response);

      expect(result['status'], 'error');
      expect(result['code'], 429);
      expect(result['is_rate_limited'], isTrue);
      expect(result['is_network_error'], isFalse);
      expect(result['retry_after'], 120);
      expect(result['message'], contains('120 saniye sonra tekrar deneyiniz'));
    });

    test('parseResponse parses standard successful JSON response', () {
      final response = utf8Response(
        jsonEncode({'status': 'success', 'data': [{'id': 1, 'title': 'Garson'}]}),
        200,
      );

      final result = NetworkHelper.parseResponse(response);

      expect(result['status'], 'success');
      expect(result['data'], isNotEmpty);
      expect(result['is_rate_limited'], isNull);
    });
  });
}
