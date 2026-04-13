import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class JobService {
  // Aynı IP adresini alıyoruz
  static const String _baseUrl = 'http://172.20.10.11/backend';

  // İlan Gönderme (İşveren)
  static Future<Map<String, dynamic>> addJob({
    required String title,
    required String location,
    required String workingHours,
    required String wage,
    required String description,
    required String dates,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await http.post(
        Uri.parse('$_baseUrl/add_job.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employer_phone': phone,
          'title': title,
          'location': location,
          'working_hours': workingHours,
          'wage': wage,
          'description': description,
          'dates': dates,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'HTTP Hatası: ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }

  // İlanları Getirme (İşveren kendi açtığı, Çalışan tüm açık ilanları)
  static Future<List<dynamic>> getJobs(bool isEmployer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await http.post(
        Uri.parse('$_baseUrl/get_jobs.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': isEmployer ? 'employer_jobs' : 'all',
          'employer_phone': isEmployer ? phone : '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
    } catch (e) {
      print('İlanları çekerken hata: $e');
    }
    return [];
  }

  // Başvuruları Getirme
  static Future<List<dynamic>> getApplications(bool isEmployer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await http.post(
        Uri.parse('$_baseUrl/get_applications.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': isEmployer ? 'employer_apps' : 'employee_apps',
          'employer_phone': isEmployer ? phone : '',
          'employee_phone': !isEmployer ? phone : '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
    } catch (e) {
      print('Başvuruları çekerken hata: $e');
    }
    return [];
  }

  // İlana Başvur (Çalışan)
  static Future<Map<String, dynamic>> applyJob(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await http.post(
        Uri.parse('$_baseUrl/apply_job.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'employee_phone': phone,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }

  // Başvuru Durumunu Değiştir veya Tamamla (İşveren)
  static Future<Map<String, dynamic>> manageApplication(String applicationId, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/manage_application.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'application_id': applicationId,
          'action': action, // 'accept', 'reject', 'complete'
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }
}
