import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_config.dart';
import 'utils/network_helper.dart';

class JobService {
  static String get _baseUrl => ServerConfig.baseUrl;

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

      final response = await NetworkHelper.postWithRetry(
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

      return NetworkHelper.parseResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }

  // İlan Güncelleme (İşveren)
  static Future<Map<String, dynamic>> updateJob({
    required String jobId,
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

      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/update_job.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'employer_phone': phone,
          'title': title,
          'location': location,
          'working_hours': workingHours,
          'wage': wage,
          'description': description,
          'dates': dates,
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

  // İlan Silme (İşveren)
  static Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/delete_job.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'job_id': jobId}),
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

  // İlanları Getirme (Detaylı durum ve hata bilgisi içeren güvenli metod)
  static Future<Map<String, dynamic>> fetchJobs(bool isEmployer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/get_jobs.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': isEmployer ? 'employer_jobs' : 'all',
          'employer_phone': isEmployer ? phone : '',
        }),
      );

      final parsed = NetworkHelper.parseResponse(response);
      if (parsed['is_rate_limited'] == true) {
        return {
          'success': false,
          'has_error': true,
          'is_rate_limited': true,
          'is_network_error': false,
          'data': [],
          'message': parsed['message'],
        };
      }

      if (response.statusCode == 200) {
        final data = parsed;
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['data'] ?? [],
          };
        }
        return {
          'success': false,
          'has_error': true,
          'is_network_error': false,
          'message': data['message'] ?? 'İlanlar alınamadı.',
        };
      }
      return {
        'success': false,
        'has_error': true,
        'is_network_error': false,
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

  // İlanları Getirme (Geriye dönük uyumluluk)
  static Future<List<dynamic>> getJobs(bool isEmployer) async {
    final res = await fetchJobs(isEmployer);
    if (res['success'] == true && res['data'] is List) {
      return res['data'];
    }
    return [];
  }

  // Başvuruları Getirme (Detaylı durum ve hata bilgisi içeren güvenli metod)
  static Future<Map<String, dynamic>> fetchApplications(bool isEmployer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/get_applications.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': isEmployer ? 'employer_apps' : 'employee_apps',
          'employer_phone': isEmployer ? phone : '',
          'employee_phone': !isEmployer ? phone : '',
        }),
      );

      final parsed = NetworkHelper.parseResponse(response);
      if (parsed['is_rate_limited'] == true) {
        return {
          'success': false,
          'has_error': true,
          'is_rate_limited': true,
          'is_network_error': false,
          'data': [],
          'message': parsed['message'],
        };
      }

      if (response.statusCode == 200) {
        final data = parsed;
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['data'] ?? [],
          };
        }
        return {
          'success': false,
          'has_error': true,
          'is_network_error': false,
          'message': data['message'] ?? 'Başvurular alınamadı.',
        };
      }
      return {
        'success': false,
        'has_error': true,
        'is_network_error': false,
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

  // Başvuruları Getirme (Geriye dönük uyumluluk)
  static Future<List<dynamic>> getApplications(bool isEmployer) async {
    final res = await fetchApplications(isEmployer);
    if (res['success'] == true && res['data'] is List) {
      return res['data'];
    }
    return [];
  }

  // İlana Başvur (Çalışan)
  static Future<Map<String, dynamic>> applyJob(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/apply_job.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'job_id': jobId, 'employee_phone': phone}),
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

  // Başvuru Durumunu Değiştir veya Tamamla (İşveren)
  static Future<Map<String, dynamic>> manageApplication(
    String applicationId,
    String action,
  ) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/manage_application.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'application_id': applicationId,
          'action': action, // 'accept', 'reject', 'complete'
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

  // Değerlendirme gönder (Puan ve Yorum)
  static Future<Map<String, dynamic>> submitReview(
    String applicationId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/submit_review.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'application_id': applicationId,
          'rating': rating,
          'comment': comment,
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

  // İşvereni Değerlendir (Çalışan)
  static Future<Map<String, dynamic>> submitEmployerReview(
    String applicationId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await NetworkHelper.postWithRetry(
        Uri.parse('$_baseUrl/submit_employer_review.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'application_id': applicationId,
          'rating': rating,
          'comment': comment,
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

  // Tek tıkla demo verilerini yükleme / sıfırlama
  static Future<Map<String, dynamic>> seedDatabase() async {
    try {
      final response = await NetworkHelper.getWithRetry(
        Uri.parse('$_baseUrl/seed.php'),
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'status': 'error',
        'is_network_error': false,
        'message': 'HTTP Hatası: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'status': 'error',
        'is_network_error': NetworkHelper.isNetworkException(e),
        'message': NetworkHelper.getFriendlyErrorMessage(e),
      };
    }
  }
}
