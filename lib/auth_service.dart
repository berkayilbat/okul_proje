import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';
import 'utils/network_helper.dart';

class AuthService {
  static const String _keyPhone = 'user_phone';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRole = 'user_role';

  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyCompanyName = 'company_name';
  static const String _keyTcKimlikNo = 'tc_kimlik_no';
  static const String _keyProfileImage = 'profile_image';

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
      'profile_image': prefs.getString(_keyProfileImage),
    };
  }

  static String? getFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '$_baseUrl/$cleanPath';
  }

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
    bool rememberMe,
  ) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      final parsed = NetworkHelper.parseResponse(response);
      if (parsed['is_rate_limited'] == true) {
        return {
          'success': false,
          'is_network_error': false,
          'is_rate_limited': true,
          'retry_after': parsed['retry_after'],
          'message': parsed['message'],
        };
      }

      if (response.statusCode == 200) {
        final data = parsed;
        if (data['status'] == 'success') {
          // Giriş Başarılı
          final prefs = await SharedPreferences.getInstance();
          final userMap = data['user'] ?? {};
          final String userRole = userMap['role']?.toString() ?? '';
          
          await prefs.setString(_keyRole, userRole);

          if (userMap['first_name'] != null) {
            await prefs.setString(
              _keyFirstName,
              userMap['first_name'].toString(),
            );
          }
          if (userMap['last_name'] != null) {
            await prefs.setString(
              _keyLastName,
              userMap['last_name'].toString(),
            );
          }
          if (userMap['company_name'] != null) {
            await prefs.setString(
              _keyCompanyName,
              userMap['company_name'].toString(),
            );
          }
          if (userMap['tc_kimlik_no'] != null) {
            await prefs.setString(
              _keyTcKimlikNo,
              userMap['tc_kimlik_no'].toString(),
            );
          }
          if (userMap['profile_image'] != null && userMap['profile_image'].toString().isNotEmpty) {
            await prefs.setString(
              _keyProfileImage,
              userMap['profile_image'].toString(),
            );
          } else {
            await prefs.remove(_keyProfileImage);
          }
            
          int isComplete = 0;
          if (userMap['is_profile_complete'] != null) {
            isComplete = int.tryParse(userMap['is_profile_complete'].toString()) ?? 0;
          }
          await prefs.setInt('is_profile_complete', isComplete);

          await prefs.setString(_keyPhone, phone);
          await prefs.setBool(_keyRememberMe, rememberMe);

          return {
            'success': true,
            'role': userRole,
            'is_profile_complete': isComplete,
            'user': userMap,
          };
        } else {
          return {
            'success': false,
            'is_network_error': false,
            'is_rate_limited': false,
            'message': data['message'] ?? 'Giriş başarısız',
          };
        }
      }
      return {
        'success': false,
        'is_network_error': false,
        'is_rate_limited': false,
        'message': parsed['message'] ?? 'HTTP Hatası: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }

  static Future<bool> setUserRole(String phone, String role) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/set_user_role.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'role': role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyRole, role);
          return true;
        }
      }
    } catch (_) {}
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
      final response = await NetworkHelper.postWithRetry(
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

      return NetworkHelper.parseResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }

  static Future<Map<String, dynamic>> getUserProfileStats(String phone, String role) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/get_user_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'role': role}),
      );

      final parsed = NetworkHelper.parseResponse(response);
      if (parsed['is_rate_limited'] == true) {
        return {
          'wallet_balance': 0.0,
          'job_count': 0,
          'average_rating': 0.0,
          'has_error': true,
          'is_rate_limited': true,
          'is_network_error': false,
          'message': parsed['message'],
        };
      }

      if (response.statusCode == 200) {
        final data = parsed;
        if (data['status'] == 'success') {
          return {
            ...data['data'],
            'has_error': false,
          };
        }
      }
    } catch (e) {
      return {
        'wallet_balance': 0.0,
        'job_count': 0,
        'average_rating': 0.0,
        'has_error': true,
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
    return {
      'wallet_balance': 0.0,
      'job_count': 0,
      'average_rating': 0.0,
      'has_error': false,
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

      var streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
           await prefs.setInt('is_profile_complete', 1);
        }
        return data;
      } else {
        return {'status': 'error', 'is_network_error': false, 'message': 'Hata kodu: ${response.statusCode}'};
      }
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }

  static Future<Map<String, dynamic>> getProfileDetails(String phone) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/get_profile_details.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['data'] ?? {},
          };
        }
      }
      return {'success': false, 'message': 'Profil bilgileri alınamadı.'};
    } catch (e) {
      return {
        'success': false,
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
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
      final response = await NetworkHelper.postWithRetry(
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

      final data = NetworkHelper.parseResponse(response);
      if (data['is_rate_limited'] == true) {
        return data;
      }

      if (response.statusCode == 200) {
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
          'is_network_error': false,
          'message': data['message'] ?? 'HTTP Hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar({
    required String phone,
    required String filePath,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload_avatar.php');
      final request = http.MultipartRequest('POST', uri);
      request.fields['phone'] = phone;
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      final parsed = NetworkHelper.parseResponse(response);
      if (parsed['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        final imagePath = parsed['profile_image']?.toString();
        if (imagePath != null && imagePath.isNotEmpty) {
          await prefs.setString(_keyProfileImage, imagePath);
        }
      }
      return parsed;
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAvatar({required String phone}) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/upload_avatar.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'action': 'delete'}),
      );

      final parsed = NetworkHelper.parseResponse(response);
      if (parsed['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyProfileImage);
      }
      return parsed;
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
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
    await prefs.remove(_keyProfileImage);
    await prefs.remove('is_profile_complete');
  }
}
