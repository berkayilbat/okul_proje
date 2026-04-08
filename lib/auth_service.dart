import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyPhone = 'user_phone';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRole = 'user_role';
  static const String _keyPassword = 'user_password';
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool(_keyRememberMe) ?? false;
    final phone = prefs.getString(_keyPhone);
    return isRemembered && phone != null;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole) ?? 'Employee';
  }

  static Future<bool> login(String phone, String password, bool rememberMe, String role) async {
    await Future.delayed(const Duration(seconds: 1)); 

    final prefs = await SharedPreferences.getInstance();
    
    // Şifre eşleştirme kontrolü (Giriş hakkı tükenmesi mekanizması için)
    final savedPhone = prefs.getString(_keyPhone);
    final savedPassword = prefs.getString(_keyPassword);

    if (savedPassword != null) {
      if (savedPassword != password || savedPhone != phone) {
        return false; // Hatalı şifre veya numara durumu simülasyonu
      }
    }

    await prefs.setString(_keyRole, role);

    if (rememberMe) {
      await prefs.setBool(_keyRememberMe, true);
      await prefs.setString(_keyPhone, phone);
    } else {
      await prefs.setBool(_keyRememberMe, false);
      // Şifreyi güvenlik gereği silebilir veya _keyRememberMe'ye bağlı olduğu için koruyabiliriz.
      // Cihazdan numarasını unutmasını sağladığımız için:
      await prefs.remove(_keyPhone);
    }
    
    return true;
  }

  static Future<void> register({
    required String role,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? tcKimlikNo,
    String? companyName,
    String? taxNo,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); 
    final prefs = await SharedPreferences.getInstance();
    
    // Kayıt olan kullanıcının bilgilerini cihaza kaydediyoruz.
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyPassword, password);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyRole);
    // Güvenlik için tutulan şifreyi de kaldırabiliriz ancak simüle için bırakılabilir.
  }
}
