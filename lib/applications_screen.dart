import 'widgets/app_toast.dart';
import 'utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'job_service.dart';
import 'qr_generate_screen.dart';
import 'qr_scan_screen.dart';
import 'widgets/review_dialog.dart';
import 'widgets/network_error_view.dart';
import 'widgets/app_refresh_indicator.dart';
import 'widgets/empty_state_view.dart';
import 'widgets/shimmer_loading.dart';
import 'widgets/app_avatar.dart';

class ApplicationsScreen extends StatefulWidget {
  final bool isEmployer;
  final bool isHistory;
  final VoidCallback? onExploreJobs;

  const ApplicationsScreen({
    super.key,
    required this.isEmployer,
    this.isHistory = false,
    this.onExploreJobs,
  });

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  bool _hasNetworkError = false;
  String? _networkErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
      _networkErrorMessage = null;
    });

    final appsRes = await JobService.fetchApplications(widget.isEmployer);
    if (!mounted) return;

    if (appsRes['success'] != true && (appsRes['is_network_error'] == true || _applications.isEmpty)) {
      setState(() {
        _hasNetworkError = true;
        _networkErrorMessage = appsRes['message']?.toString();
        _isLoading = false;
      });
      return;
    }

    final apps = (appsRes['data'] as List?) ?? [];
    setState(() {
      if (widget.isHistory) {
        _applications = apps.where((app) => app['app_status'] == 'completed').toList();
      } else {
        _applications = apps.where((app) => app['app_status'] != 'completed').toList();
      }
      _hasNetworkError = false;
      _isLoading = false;
    });
  }

  Future<bool> _manageApplication(String id, String action) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await JobService.manageApplication(id, action);
    if (!mounted) return false;
    Navigator.pop(context);

    if (result['status'] == 'success') {
      AppToast.showSuccess(context, result['message'] ?? 'İşlem yapıldı');
    } else {
      AppToast.showError(
        context,
        result['message'] ?? 'İşlem başarısız',
        onRetry: result['is_network_error'] == true ? () => _manageApplication(id, action) : null,
      );
    }
    if (result['status'] == 'success') {
      _fetchApplications();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SkeletonListView.applications();
    }

    if (_hasNetworkError && _applications.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: _fetchApplications,
        child: NetworkErrorView(
          message: _networkErrorMessage,
          onRetry: _fetchApplications,
        ),
      );
    }

    return AppRefreshIndicator(
      onRefresh: _fetchApplications,
      child: _applications.isEmpty ? _buildEmptyState() : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    if (widget.isHistory) {
      return EmptyStateView.noHistory(
        message: 'Geçmişte tamamladığınız veya sonuçlanan bir iş başvurunuz bulunmuyor.',
      );
    }
    return EmptyStateView.noApplications(
      onExploreJobs: widget.onExploreJobs,
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        return _buildApplicationCard(app);
      },
    );
  }

  Widget _buildApplicationCard(dynamic app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16191E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF282F3A) : Colors.transparent;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final textBody = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800;

    final status = app['app_status'];
    Color statusColor;
    String statusText;

    switch (status) {
      case 'applied':
        statusColor = Colors.orange;
        statusText = 'Bekleniyor';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Kabul Edildi';
        break;
      case 'in_progress':
        statusColor = Colors.purple;
        statusText = 'İş Başladı (Devam Ediyor)';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Tamamlandı';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Reddedildi';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Bilinmiyor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    app['title'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (widget.isEmployer)
              Row(
                children: [
                   AppAvatar(
                     radius: 12,
                     imageUrl: (app['employee_avatar'] ?? app['profile_image'])?.toString(),
                     name: '${app['first_name']} ${app['last_name']}',
                     foregroundColor: primaryColor,
                     backgroundColor: textSecondary.withOpacity(0.12),
                   ),
                   const SizedBox(width: 8),
                   Text(
                     'Başvuran: ${app['first_name']} ${app['last_name']}',
                     style: TextStyle(color: textBody, fontSize: 16, fontWeight: FontWeight.w500),
                   ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // İşveren Aksiyon Butonları
            if (widget.isEmployer && status == 'applied')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _manageApplication(app['application_id'].toString(), 'reject'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0),
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _manageApplication(app['application_id'].toString(), 'accept'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Kabul Et'),
                    ),
                  ),
                ],
              ),

            // EĞER ÇALIŞAN İSE (isEmployer = false)
            if (!widget.isEmployer && status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('İşe Başlama QR Göster', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: () async {
                    // İşe Başlama QR: START|id
                    final res = await Navigator.push(
                      context,
                      AppPageRoute.slideUp(QRGenerateScreen(qrData: 'START|${app['application_id']}')),
                    );
                    if (res == 'in_progress' || res != null) {
                      _fetchApplications();
                    }
                  },
                ),
              ),

            if (!widget.isEmployer && status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('İşverenin QR\'ını Okut (Bitir)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: () async {
                    // İşçi, işverenin oluşturduğu FINISH|id barkodunu arıyor
                    final result = await Navigator.push(
                      context,
                      AppPageRoute.fadeThrough(const QRScanScreen()),
                    );
                    
                    if (result != null && result.toString() == 'FINISH|${app['application_id']}') {
                        bool success = await _manageApplication(app['application_id'].toString(), 'complete');
                        if (success && mounted) {
                           _showRatingDialog(app['application_id'].toString(), app);
                        }
                    } else if (result != null) {
                        AppToast.showError(context, 'Yanlış veya Geçersiz QR kod!');
                    }
                  },
                ),
              ),

            if (!widget.isEmployer && status == 'completed') ...[
              const SizedBox(height: 12),
              if (app['employer_rating'] == null || app['employer_rating'].toString() == '0')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.star),
                    label: const Text('İşvereni Puanla ve Değerlendir', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () {
                      _showRatingDialog(app['application_id'].toString(), app);
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E232B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF282F3A) : Colors.grey.shade200),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Değerlendirmeniz',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < int.parse(app['employer_rating'].toString()) ? Icons.star : Icons.star_border,
                                    color: Colors.amber, 
                                    size: 16
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (app['employer_review_comment'] != null && app['employer_review_comment'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '"${app['employer_review_comment']}"',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(String applicationId, dynamic app) {
    ReviewDialog.show(
      context,
      title: 'İşvereni Değerlendir',
      onSubmit: (rating, comment) async {
        final res = await JobService.submitEmployerReview(applicationId, rating, comment);
        if (!mounted) return;
        if (res['status'] == 'success') {
          AppToast.showSuccess(context, res['message'] ?? 'Değerlendirme kaydedildi');
        } else {
          AppToast.showError(context, res['message'] ?? 'Hata oluştu');
        }
        if (res['status'] == 'success') {
          _fetchApplications();
        }
      },
    );
  }
}
