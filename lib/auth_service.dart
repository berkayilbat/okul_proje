import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'server_config.dart';

class AuthService {
  static const String _keyPhone = 'user_phone';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRole = 'user_role';

  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyCompanyName = 'company_name';
  static const String _keyTcKimlikNo = 'tc_kimlik_no';

  static String get _baseUrl => ServerConfig.baseUrl;

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
      'phone': prefs.getString(_keyPhone),
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
            
          if (userMap['is_profile_complete'] != null) {
            await prefs.setInt('is_profile_complete', int.tryParse(userMap['is_profile_complete'].toString()) ?? 0);
          } else {
            await prefs.setInt('is_profile_complete', 0);
          }

          // Her oturumda telefon numarasına ihtiyacımız var (API çağrıları için)
          await prefs.setString(_keyPhone, phone);
          
          if (rememberMe) {
            await prefs.setBool(_keyRememberMe, true);
          } else {
            await prefs.setBool(_keyRememberMe, false);
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
    required String birthDate,
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
          'birth_date': birthDate,
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

  static Future<Map<String, dynamic>> getUserProfileStats(String phone, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_user_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'role': role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
    } catch (e) {
      print('HTTP İstek Hatası (Profile Stats): $e');
    }
    return {
      'wallet_balance': 0.0,
      'job_count': 0,
      'average_rating': 0.0
    };
  }

  static Future<Map<String, dynamic>> uploadEmployeeProfile({
    required String address,
    required String professions,
    required List<String> certificatePaths,
    required List<String> workplacePaths,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(_keyPhone);
      
      if (phone == null || phone.isEmpty) {
        return {'status': 'error', 'message': 'Telefon numarası bulunamadı'};
      }

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/update_employee_profile.php'));
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['professions'] = professions;

      for (var path in certificatePaths) {
        request.files.add(await http.MultipartFile.fromPath('certificates[]', path));
      }
      for (var path in workplacePaths) {
        request.files.add(await http.MultipartFile.fromPath('past_workplaces[]', path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
           await prefs.setInt('is_profile_complete', 1);
        }
        return data;
      } else {
        return {'status': 'error', 'message': 'Hata kodu: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı Hatası: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfileDetails(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_profile_details.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
    } catch (e) {
      print('HTTP İstek Hatası (Profile Details): $e');
    }
    return {};
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String oldPhone,
    required String phone,
    String? address,
    String? professions,
    String? firstName,
    String? lastName,
    String? taxNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'old_phone': oldPhone,
          'phone': phone,
          'address': address,
          'professions': professions,
          'first_name': firstName,
          'last_name': lastName,
          'tax_no': taxNo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
           final prefs = await SharedPreferences.getInstance();
           if (oldPhone != phone) {
               await prefs.setString(_keyPhone, phone);
           }
           if (firstName != null) await prefs.setString(_keyFirstName, firstName);
           if (lastName != null) await prefs.setString(_keyLastName, lastName);
        }
        return data;
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('HTTP İstek Hatası (Update Profile): $e');
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
    await prefs.remove('is_profile_complete');
  }
}

