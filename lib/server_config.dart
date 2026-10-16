import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ServerConfig {
  static String? _baseUrl;

  static String get baseUrl {
    return _baseUrl ?? (kIsWeb ? 'http://127.0.0.1/backend' : 'http://10.0.2.2/backend');
  }

  static Future<void> discoverServer() async {
    if (kIsWeb) {
      _baseUrl = 'http://127.0.0.1/backend';
      return;
    }

    // Hizli kontrol: Emulator
    if (Platform.isAndroid || Platform.isIOS) {
       try {
         final res = await http.get(Uri.parse('http://10.0.2.2/backend/ping.php'))
              .timeout(const Duration(milliseconds: 500));
         if (res.statusCode == 200 && res.body.contains('my_app')) {
            _baseUrl = 'http://10.0.2.2/backend';
            return;
         }
       } catch (_) {}
    }

    // Ag taramasi
    String? localIp;
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
             localIp = addr.address;
             break;
          }
        }
        if (localIp != null) break;
      }
    } catch (_) {}

    if (localIp != null && localIp.contains('.')) {
      final parts = localIp.split('.');
      final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
      
      for (int i = 1; i <= 254; i += 50) {
         if (_baseUrl != null) break;
         List<Future<void>> batch = [];
         for (int j = i; j < i + 50 && j <= 254; j++) {
            batch.add((() async {
               if (_baseUrl != null) return;
               final testIp = '$prefix.$j';
               try {
                 final socket = await Socket.connect(testIp, 80, timeout: const Duration(milliseconds: 300));
                 socket.destroy();
                 
                 if (_baseUrl == null) {
                   final res = await http.get(Uri.parse('http://$testIp/backend/ping.php'))
                        .timeout(const Duration(milliseconds: 500));
                   if (res.statusCode == 200 && res.body.contains('my_app')) {
                     _baseUrl = 'http://$testIp/backend';
                   }
                 }
               } catch (_) {}
            })());
         }
         await Future.wait(batch);
      }
    }

    // Bulunamazsa varsayilan
    _baseUrl ??= (Platform.isAndroid || Platform.isIOS) ? 'http://10.0.2.2/backend' : 'http://127.0.0.1/backend';
  }
}
