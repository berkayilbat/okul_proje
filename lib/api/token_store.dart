import 'package:shared_preferences/shared_preferences.dart';

/// Erişim token'ının nerede saklanacağını soyutlar.
/// İleride güvenli depolamaya geçildiğinde yalnızca yeni bir uygulama yazılır.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Şimdilik token'ı SharedPreferences içinde tutar.
class SharedPrefsTokenStore implements TokenStore {
  static const String _key = 'access_token';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
