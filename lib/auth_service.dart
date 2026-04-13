import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static const String _keyPhone = 'user_phone';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRole = 'user_role';

  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyCompanyName = 'company_name';
  static const String _keyTcKimlikNo = 'tc_kimlik_no';

  // Bilgisayarınızın güncel yerel (Wi-Fi/Ethernet) IP Adresi. 
  // Gerçek telefon üzerinden test ederken XAMPP'a bu adresle ulaşabilirsiniz.
  static const String _baseUrl = 'http://172.20.10.11/backend';

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

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'first_name': prefs.getString(_keyFirstName),
      'last_name': prefs.getString(_keyLastName),
      'company_name': prefs.getString(_keyCompanyName),
      'tc_kimlik_no': prefs.getString(_keyTcKimlikNo),
      'role': prefs.getString(_keyRole),
    };
  }

  static Future<bool> login(
    String phone,
    String password,
    bool rememberMe,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password, 'role': role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Giriş Başarılı
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyRole, role);

          final userMap = data['user'];
          if (userMap['first_name'] != null)
            await prefs.setString(
              _keyFirstName,
              userMap['first_name'].toString(),
            );
          if (userMap['last_name'] != null)
            await prefs.setString(
              _keyLastName,
              userMap['last_name'].toString(),
            );
          if (userMap['company_name'] != null)
            await prefs.setString(
              _keyCompanyName,
              userMap['company_name'].toString(),
            );
          if (userMap['tc_kimlik_no'] != null)
            await prefs.setString(
              _keyTcKimlikNo,
              userMap['tc_kimlik_no'].toString(),
            );

          if (rememberMe) {
            await prefs.setBool(_keyRememberMe, true);
            await prefs.setString(_keyPhone, phone);
          } else {
            await prefs.setBool(_keyRememberMe, false);
            await prefs.remove(_keyPhone);
          }
          return true;
        } else {
          // Giriş Başarısız (Hatalı şifre, numara veya rol)
          print('Giriş Hatası: ${data['message']}');
          return false;
        }
      }
    } catch (e) {
      print('HTTP İstek Hatası (Login): $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>> register({
    required String role,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? tcKimlikNo,
    String? companyName,
    String? taxNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'password': password,
          'tc_kimlik_no': tcKimlikNo,
          'company_name': companyName,
          'tax_no': taxNo,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('HTTP İstek Hatası (Register): $e');
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyFirstName);
    await prefs.remove(_keyLastName);
    await prefs.remove(_keyCompanyName);
    await prefs.remove(_keyTcKimlikNo);
  }
}
