import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/api/api_client.dart';
import 'package:my_app/api/token_store.dart';

class MemoryTokenStore implements TokenStore {
  String? token;
  MemoryTokenStore([this.token]);
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String t) async => token = t;
  @override
  Future<void> clear() async => token = null;
}

ApiClient make(MockClient mock, {String? token, void Function()? onUnauth}) =>
    ApiClient(
      client: mock,
      tokenStore: MemoryTokenStore(token),
      baseUrl: () => 'http://test/api',
      onUnauthorized: onUnauth,
    );

void main() {
  test('token varsa Bearer başlığı gider, yoksa gitmez', () async {
    final seen = <http.Request>[];
    final mock = MockClient((r) async {
      seen.add(r);
      return http.Response(jsonEncode({'status': 'success'}), 200);
    });
    await make(mock, token: 'abc').post('jobs', body: {'a': 1});
    await make(mock).get('jobs', query: {'page': 2});
    expect(seen[0].headers['Authorization'], 'Bearer abc');
    expect(seen[0].url.toString(), 'http://test/api/jobs');
    expect(seen[1].headers.containsKey('Authorization'), isFalse);
    expect(seen[1].url.query, 'page=2');
  });

  test('429 standart rate limit haritasına dönüşür', () async {
    final mock = MockClient((_) async => http.Response('{}', 429,
        headers: {'retry-after': '30'}));
    final res = await make(mock).get('x');
    expect(res['is_rate_limited'], true);
    expect(res['retry_after'], 30);
    expect(res['status'], 'error');
  });

  test('ağ hatası is_network_error döndürür ve yeniden dener', () async {
    var calls = 0;
    final mock = MockClient((_) async {
      calls++;
      throw const SocketException('down');
    });
    final res = await make(mock).get('x');
    expect(res['is_network_error'], true);
    expect(res['status'], 'error');
    expect(calls, 2);
  });

  test('401 onUnauthorized çağrısını bir kez tetikler', () async {
    var count = 0;
    final mock = MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401));
    final res = await make(mock, token: 't', onUnauth: () => count++).get('x');
    expect(count, 1);
    expect(res['code'], 401);
    expect(res['status'], 'error');
  });

  test('multipart Bearer başlığı ve alanları gönderir', () async {
    late http.BaseRequest sent;
    final mock = MockClient.streaming((req, body) async {
      sent = req;
      return http.StreamedResponse(
          Stream.value(utf8.encode('{"status":"success"}')), 200);
    });
    final res = await make(mock, token: 'abc')
        .multipart('avatar', fields: {'k': 'v'});
    expect(res['status'], 'success');
    expect(sent.headers['Authorization'], 'Bearer abc');
    expect(sent.method, 'POST');
  });
}
