import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const String _prefKeyHost = 'saved_server_host';
  static const String defaultLocalIp = '192.168.1.7';

  /// Eğer fiziksel cihazda test ediyorsanız buraya bilgisayarınızın yerel IP'sini yazabilirsiniz.
  static String? customHost;

  /// Aktif host adresi (örn: 192.168.1.7 veya 10.0.2.2)
  static String get activeHost {
    if (customHost != null && customHost!.isNotEmpty) {
      return customHost!;
    }
    return defaultLocalIp;
  }

  static String get baseUrl {
    return 'http://$activeHost/backend';
  }

  /// Uygulama açılışında kayıtlı sunucu host bilgisini yükler
  static Future<void> discoverServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyHost);
      if (saved != null && saved.trim().isNotEmpty) {
        customHost = saved.trim();
      } else {
        customHost = defaultLocalIp;
      }
    } catch (_) {
      customHost = defaultLocalIp;
    }
  }

  /// Yeni host belirler ve SharedPreferences'a kaydeder
  static Future<void> setCustomHost(String host) async {
    customHost = host.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyHost, customHost!);
    } catch (_) {}
  }

  static String? lastTestError;

  /// Belirtilen host veya aktif host için bağlantı testi yapar
  static Future<bool> testConnection([String? hostToTest]) async {
    lastTestError = null;
    final host = (hostToTest != null && hostToTest.trim().isNotEmpty) ? hostToTest.trim() : activeHost;
    if (host.isEmpty) {
      lastTestError = 'Host adresi boş';
      return false;
    }

    try {
      final url = Uri.parse('http://$host/backend/ping.php');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.contains('my_app')) {
        return true;
      } else {
        lastTestError = 'HTTP ${res.statusCode}: ${res.body.trim().isEmpty ? "Boş yanıt" : res.body.trim()}';
        return false;
      }
    } catch (e) {
      lastTestError = e.toString();
      debugPrint('testConnection error ($host): $e');
      return false;
    }
  }
}
