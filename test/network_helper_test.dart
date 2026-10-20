import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/utils/network_helper.dart';

void main() {
  group('NetworkHelper Unit Tests', () {
    test('identifies network exceptions correctly', () {
      expect(NetworkHelper.isNetworkException(const SocketException('Failed host lookup')), isTrue);
      expect(NetworkHelper.isNetworkException(TimeoutException('Request timed out')), isTrue);
      expect(NetworkHelper.isNetworkException(http.ClientException('Connection closed')), isTrue);
      expect(NetworkHelper.isNetworkException(const HttpException('Connection reset')), isTrue);
      expect(NetworkHelper.isNetworkException(Exception('SocketException: OS Error: connection refused')), isTrue);

      // Non-network exceptions
      expect(NetworkHelper.isNetworkException(const FormatException('Bad JSON')), isFalse);
      expect(NetworkHelper.isNetworkException(ArgumentError('Invalid argument')), isFalse);
      expect(NetworkHelper.isNetworkException(Exception('Bilinmeyen bir hata oluştu')), isFalse);
    });

    test('generates user-friendly Turkish error messages', () {
      final socketMsg = NetworkHelper.getFriendlyErrorMessage(const SocketException('No route to host'));
      expect(socketMsg, contains('İnternet veya sunucu bağlantısı kurulamadı'));

      final timeoutMsg = NetworkHelper.getFriendlyErrorMessage(TimeoutException('timed out'));
      expect(timeoutMsg, contains('Zaman aşımı'));

      final customMsg = NetworkHelper.getFriendlyErrorMessage(Exception('Özel hata mesajı'));
      expect(customMsg, contains('Özel hata mesajı'));
    });

    test('executeWithRetry succeeds on first attempt', () async {
      int callCount = 0;
      final result = await NetworkHelper.executeWithRetry(() async {
        callCount++;
        return 'success';
      });

      expect(result, 'success');
      expect(callCount, 1);
    });

    test('executeWithRetry succeeds after transient network error', () async {
      int callCount = 0;
      final result = await NetworkHelper.executeWithRetry(() async {
        callCount++;
        if (callCount == 1) {
          throw const SocketException('Temporary glitch');
        }
        return 'recovered';
      }, maxRetries: 2, delay: const Duration(milliseconds: 10));

      expect(result, 'recovered');
      expect(callCount, 2);
    });

    test('executeWithRetry throws when retries exhausted', () async {
      int callCount = 0;
      await expectLater(
        () => NetworkHelper.executeWithRetry(() async {
          callCount++;
          throw const SocketException('Persistent failure');
        }, maxRetries: 2, delay: const Duration(milliseconds: 10)),
        throwsA(isA<SocketException>()),
      );
      expect(callCount, 3);
    });

    test('executeWithRetry does not retry non-network exceptions', () async {
      int callCount = 0;
      await expectLater(
        () => NetworkHelper.executeWithRetry(() async {
          callCount++;
          throw const FormatException('Data parse error');
        }, maxRetries: 2, delay: const Duration(milliseconds: 10)),
        throwsA(isA<FormatException>()),
      );

      // Should fail immediately without retrying non-network error
      expect(callCount, 1);
    });
  });
}
