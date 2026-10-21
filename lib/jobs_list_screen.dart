import 'widgets/app_toast.dart';
import 'theme/app_theme.dart';
import 'utils/job_helpers.dart';
import 'package:flutter/material.dart';
import 'job_service.dart';
import 'employee_profile_screen.dart';
import 'job_detail_screen.dart';
import 'utils/app_page_route.dart';
import 'qr_generate_screen.dart';
import 'qr_scan_screen.dart';
import 'add_job_screen.dart';
import 'widgets/review_dialog.dart';
import 'widgets/network_error_view.dart';
import 'widgets/app_refresh_indicator.dart';
import 'widgets/empty_state_view.dart';
import 'widgets/shimmer_loading.dart';
import 'widgets/app_avatar.dart';

class JobsListScreen extends StatefulWidget {
  final bool isEmployer;
  final bool isHistory;
  final Set<String> jobFilters;
  final Set<String> locationFilters;
  final VoidCallback? onClearFilters;
  
  const JobsListScreen({
    super.key,
    required this.isEmployer,
    this.isHistory = false,
    this.jobFilters = const {},
    this.locationFilters = const {},
    this.onClearFilters,
  });

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  List<dynamic> _jobs = [];
  List<dynamic> _applications = []; // İşveren ise başvuru verisi 
  bool _isLoading = true;
  bool _hasNetworkError = false;
  String? _networkErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
      _networkErrorMessage = null;
    });

    final jobsRes = await JobService.fetchJobs(widget.isEmployer);
    final appsRes = await JobService.fetchApplications(widget.isEmployer);

    if (!mounted) return;

    if (jobsRes['success'] != true && (jobsRes['is_network_error'] == true || _jobs.isEmpty)) {
      setState(() {
        _hasNetworkError = true;
        _networkErrorMessage = jobsRes['message']?.toString();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _jobs = (jobsRes['data'] as List?) ?? [];
      _applications = (appsRes['data'] as List?) ?? [];
      _hasNetworkError = false;
      _isLoading = false;
    });
  }

  Future<void> _applyForJob(String jobId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await JobService.applyJob(jobId);
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result['status'] == 'success') {
      AppToast.showSuccess(context, result['message'] ?? 'Başvuru başarılı!');
    } else {
      AppToast.showError(
        context,
        result['message'] ?? 'Bir hata oluştu',
        onRetry: result['is_network_error'] == true ? () => _applyForJob(jobId) : null,
      );
    }
    if (result['status'] == 'success') {
      _fetchJobs();
    }
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
      _fetchJobs();
      return true;
    }
    return false;
  }

  void _showRatingDialog(String applicationId, Map<String, dynamic> app) {
    ReviewDialog.show(
      context,
      title: '${app['first_name'] ?? ''} ${app['last_name'] ?? ''} Adlı Çalışanı Değerlendir'.trim(),
      onSubmit: (rating, comment) async {
        final result = await JobService.submitReview(applicationId, rating, comment);
        if (!mounted) return;
        if (result['status'] == 'success') {
          AppToast.showSuccess(context, result['message'] ?? 'Değerlendirme kaydedildi!');
        } else {
          AppToast.showError(context, result['message'] ?? 'Hata oluştu');
        }
        if (result['status'] == 'success') {
          _fetchJobs();
        }
      },
    );
  }

  void _showEmployerRatingDialog(String applicationId, Map<String, dynamic> app) {
    ReviewDialog.show(
      context,
      title: 'İşvereni Değerlendir',
      onSubmit: (rating, comment) async {
        final res = await JobService.submitEmployerReview(applicationId, rating, comment);
        if (!mounted) return;
        if (res['status'] == 'success') {
          AppToast.showSuccess(context, res['message'] ?? 'İşlem tamamlandı');
        } else {
          AppToast.showError(context, res['message'] ?? 'Hata oluştu');
        }
        if (res['status'] == 'success') {
          _fetchJobs();
        }
      },
    );
  }

  bool _passesFilters(dynamic job) {
    bool passJobType = true;
    if (widget.jobFilters.isNotEmpty) {
      final titleText = job['title']?.toString().trim().toLowerCase() ?? '';
      passJobType = widget.jobFilters.any((f) => f.trim().toLowerCase() == titleText);
    }

    bool passDistrict = true;
    if (widget.locationFilters.isNotEmpty) {
      final locText = job['location']?.toString().toLowerCase() ?? '';
      passDistrict = widget.locationFilters.any((loc) => locText.contains(loc.toLowerCase().trim()));
    }

    return passJobType && passDistrict;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SkeletonListView.jobs();
    }

    if (_hasNetworkError && _jobs.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: _fetchJobs,
        child: NetworkErrorView(
          message: _networkErrorMessage,
          onRetry: _fetchJobs,
        ),
      );
    }
    
    if (!widget.isEmployer) {
      final filteredJobs = _jobs.where((job) => _passesFilters(job)).toList();

      return AppRefreshIndicator(
        onRefresh: _fetchJobs,
        child: filteredJobs.isEmpty ? _buildEmptyState() : _buildJobsList(filteredJobs),
      );
    }
    
    // Employer view filtering based on isHistory
    final targetJobs = _jobs.where((job) {
      if (!_passesFilters(job)) return false;

      final jobApps = _applications.where((app) => app['job_id'].toString() == job['id'].toString()).toList();
      bool hasUnratedCompleted = jobApps.any((app) => 
          app['app_status'] == 'completed' && 
          (app['rating'] == null || app['rating'].toString() == '0')
      );
      
      if (widget.isHistory) {
         // Past jobs: MUST be closed AND have NO unrated completed workers
         if (job['status'] != 'closed') return false;
         return !hasUnratedCompleted;
      } else {
         // Active jobs: NOT closed OR (closed BUT has unrated completed workers)
         if (job['status'] != 'closed') return true;
         return hasUnratedCompleted;
      }
    }).toList();

    return AppRefreshIndicator(
      onRefresh: _fetchJobs,
      child: targetJobs.isEmpty ? _buildEmptyState() : _buildJobsList(targetJobs),
    );
  }

  Future<void> _navigateToCreateJob() async {
    final result = await Navigator.push(
      context,
      AppPageRoute.slideUp(const AddJobScreen()),
    );
    if (result == true) {
      _fetchJobs();
    }
  }

  Widget _buildEmptyState() {
    final bool hasActiveFilters = widget.jobFilters.isNotEmpty || widget.locationFilters.isNotEmpty;

    if (widget.isEmployer) {
      if (widget.isHistory) {
        return EmptyStateView.noHistory(
          message: 'Geçmişte kapanan veya tamamlanan bir ilanınız bulunmuyor.',
        );
      }
      if (hasActiveFilters) {
        return EmptyStateView.noMatchingJobs(
          onClearFilters: widget.onClearFilters,
        );
      }
      return EmptyStateView.noEmployerJobs(
        onAddJob: _navigateToCreateJob,
      );
    }

    if (hasActiveFilters) {
      return EmptyStateView.noMatchingJobs(
        onClearFilters: widget.onClearFilters,
      );
    }

    return EmptyStateView.noJobs(
      onRefresh: _fetchJobs,
    );
  }

  void _openJobDetail(dynamic job) async {
    final myApp = _applications.where((app) => app['job_id'].toString() == job['id'].toString()).firstOrNull;
    final result = await Navigator.push(
      context,
      AppPageRoute.hero(
        JobDetailScreen(
          job: job,
          isEmployer: widget.isEmployer,
          hasApplied: myApp != null,
          onApply: () {
            Navigator.pop(context);
            _applyForJob(job['id'].toString());
          },
        ),
      ),
    );
    if (result == true && mounted) {
      _fetchJobs();
    }
  }

  Widget _buildJobsList(List<dynamic> targetJobs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: targetJobs.length,
      itemBuilder: (context, index) {
        final job = targetJobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? iconColor,
    Color? textColor,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? (isDark ? const Color(0xFF1E232B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: borderColor ?? (isDark ? const Color(0xFF282F3A) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16191E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF282F3A) : Colors.transparent;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final textBody = isDark ? const Color(0xFFE2E8F0) : Colors.grey.shade800;

    final workerCount = int.tryParse(job['worker_count']?.toString() ?? '1') ?? 1;
    final jobApps = _applications.where((app) => app['job_id'].toString() == job['id'].toString()).toList();
    final localAcceptedCount = jobApps.where((app) => ['accepted', 'in_progress', 'completed'].contains(app['app_status'])).length;
    final backendAcceptedCount = int.tryParse(job['accepted_count']?.toString() ?? '0') ?? 0;
    final acceptedCount = localAcceptedCount > 0 ? localAcceptedCount : backendAcceptedCount;
    final isQuotaFull = acceptedCount >= workerCount;

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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openJobDetail(job),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori İkon Squircle
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E232B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF282F3A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        JobCategoryHelper.getCategoryIcon(job['title'].toString()),
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    // Başlık ve Güvenilirlik Alt Metni
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'job-title-${job['id']}',
                            createRectTween: AppHeroHelper.fadeInPlaceRectTween,
                            flightShuttleBuilder: AppHeroHelper.flightShuttleBuilder,
                            placeholderBuilder: (context, heroSize, child) => child,
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                job['title'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                  color: primaryColor,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                'Yömyeci Onaylı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                              const SizedBox(width: 2),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ücret Vurgusu Mega-Rozeti
                    Hero(
                      tag: 'job-wage-${job['id']}',
                      createRectTween: AppHeroHelper.fadeInPlaceRectTween,
                      flightShuttleBuilder: AppHeroHelper.flightShuttleBuilder,
                      placeholderBuilder: (context, heroSize, child) => child,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${job['wage']}₺',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GÜNLÜK NET',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Metadata Çipleri Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(
                      icon: Icons.location_on_rounded,
                      label: job['location'].toString(),
                      isDark: isDark,
                      iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                    _buildMetaChip(
                      icon: Icons.access_time_rounded,
                      label: job['working_hours'].toString(),
                      isDark: isDark,
                    ),
                    _buildMetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: job['dates'].toString(),
                      isDark: isDark,
                    ),
                    _buildMetaChip(
                      icon: Icons.people_outline_rounded,
                      label: isQuotaFull
                          ? 'Kontenjan Doldu ($acceptedCount/$workerCount)'
                          : (acceptedCount > 0
                              ? 'Kontenjan: $acceptedCount/$workerCount'
                              : (workerCount > 1 ? '$workerCount Kişi Aranıyor' : '1 Kişi Aranıyor')),
                      isDark: isDark,
                      iconColor: isQuotaFull
                          ? Colors.orange
                          : (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  job['description'].toString(),
                  style: TextStyle(color: textBody, height: 1.45, fontSize: 13.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Çalışan ise başvuru durumuna göre aksiyon, İşveren ise Başvuranlar Listesi
                _buildJobCardAction(job),
              ],
            ),
      ),
    ),
    ),
    );
  }

  Widget _buildJobCardAction(dynamic job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);

    final workerCount = int.tryParse(job['worker_count']?.toString() ?? '1') ?? 1;
    final jobApps = _applications.where((app) => app['job_id'].toString() == job['id'].toString()).toList();
    final localAcceptedCount = jobApps.where((app) => ['accepted', 'in_progress', 'completed'].contains(app['app_status'])).length;
    final backendAcceptedCount = int.tryParse(job['accepted_count']?.toString() ?? '0') ?? 0;
    final acceptedCount = localAcceptedCount > 0 ? localAcceptedCount : backendAcceptedCount;
    final isQuotaFull = acceptedCount >= workerCount;

    if (!widget.isEmployer) {
      final myApp = _applications.where((app) => app['job_id'].toString() == job['id'].toString()).firstOrNull;
      
      if (myApp == null) {
        // Kontenjan dolmuşsa başvuru butonunu devre dışı bırakıp durum rozeti göster
        if (isQuotaFull) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_outlined, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Kontenjan Doldu ($acceptedCount/$workerCount)',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Henüz başvurulmamış açık ilan
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _applyForJob(job['id'].toString()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Hemen Başvur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        );
      } else {
        // Önceden başvurulmuş
        final status = myApp['app_status'];
        if (status == 'applied') {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('Başvurunuz Değerlendiriliyor', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          );
        } else if (status == 'accepted') {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('İşe Başlama QR Göster', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  AppPageRoute.slideUp(QRGenerateScreen(qrData: 'START|${myApp['application_id']}')),
                );
                if (res == 'in_progress' || res != null) {
                  _fetchJobs();
                }
              },
            ),
          );
        } else if (status == 'in_progress') {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('İşverenin QR\'ını Okut (Bitir)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  AppPageRoute.fadeThrough(const QRScanScreen()),
                );
                if (result != null && result.toString() == 'FINISH|${myApp['application_id']}') {
                    bool success = await _manageApplication(myApp['application_id'].toString(), 'complete');
                    if (success && mounted) {
                       _showEmployerRatingDialog(myApp['application_id'].toString(), myApp);
                    }
                } else if (result != null) {
                    if (!mounted) return;
                    AppToast.showError(context, 'Yanlış veya Geçersiz QR kod!');
                }
              },
            ),
          );
        } else if (status == 'completed') {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('İş Tamamlandı (Ücret Ödendi)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          );
        } else if (status == 'rejected') {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('Başvuru Reddedildi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          );
        }
        return const SizedBox.shrink(); // bilinmeyen durum
      }
    } else {
      return _buildJobApplicationsList(job['id'].toString(), job['status'].toString());
    }
  }

  Widget _buildJobApplicationsList(String jobId, String jobStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF111827);

    // Bu ilana ait başvuruları bul
    final jobApps = _applications.where((app) => app['job_id'].toString() == jobId).toList();

    final targetJob = _jobs.where((j) => j['id'].toString() == jobId).firstOrNull;
    final workerCount = int.tryParse(targetJob?['worker_count']?.toString() ?? '1') ?? 1;
    final acceptedCount = jobApps.where((app) => ['accepted', 'in_progress', 'completed'].contains(app['app_status'])).length;
    final isQuotaFull = acceptedCount >= workerCount;

    if (jobApps.isEmpty) {
      if (jobStatus == 'open') {
        return EmptyStateView.noApplicants();
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E232B) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF282F3A) : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'İlan Kapalı',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isQuotaFull
                ? Colors.amber.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF1E232B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isQuotaFull
                  ? Colors.amber.withValues(alpha: 0.4)
                  : (isDark ? const Color(0xFF282F3A) : Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isQuotaFull ? Icons.check_circle_outline : Icons.people_outline,
                size: 16,
                color: isQuotaFull ? Colors.amber.shade800 : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
              ),
              const SizedBox(width: 8),
              Text(
                'Kontenjan Durumu: $acceptedCount / $workerCount Kişi Onaylandı',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isQuotaFull
                      ? (isDark ? Colors.amber.shade300 : Colors.amber.shade900)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
        Text(
          'Gelen Başvurular:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
        ),
        const SizedBox(height: 12),
        ...jobApps.map((app) {
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232B) : Colors.transparent,
              border: Border.all(color: isDark ? const Color(0xFF282F3A) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageRoute.hero(
                              EmployeeProfileScreen(
                                firstName: app['first_name'].toString(),
                                lastName: app['last_name'].toString(),
                                phone: app['employee_phone'].toString(),
                                avatarUrl: (app['employee_avatar'] ?? app['profile_image'])?.toString(),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Row(
                            children: [
                              AppAvatar(
                                radius: 12,
                                imageUrl: (app['employee_avatar'] ?? app['profile_image'])?.toString(),
                                name: '${app['first_name']} ${app['last_name']}',
                                heroTag: 'employee-avatar-${app['employee_phone']}',
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Hero(
                                  tag: 'employee-name-${app['employee_phone']}',
                                  createRectTween: AppHeroHelper.fadeInPlaceRectTween,
                                  flightShuttleBuilder: AppHeroHelper.flightShuttleBuilder,
                                  placeholderBuilder: (context, heroSize, child) => child,
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Text(
                                      '${app['first_name']} ${app['last_name']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 15, 
                                        color: primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                if (status == 'applied') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _manageApplication(app['application_id'].toString(), 'reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _manageApplication(app['application_id'].toString(), 'accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'accepted') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('İşçinin QR\'ını Okut (Başlat)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          AppPageRoute.fadeThrough(const QRScanScreen()),
                        );
                        
                        if (result != null && result.toString() == 'START|${app['application_id']}') {
                            _manageApplication(app['application_id'].toString(), 'start_work');
                        } else if (result != null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Yanlış veya Geçersiz QR kod!'), backgroundColor: Colors.red),
                            );
                        }
                      },
                    ),
                  ),
                ],

                if (status == 'in_progress') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('İşi Bitirme QR Göster (Öde)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // İşveren Bitirme QR'ı oluşturur (FINISH|id)
                        final result = await Navigator.push(
                          context,
                          AppPageRoute.slideUp(QRGenerateScreen(qrData: 'FINISH|${app['application_id']}')),
                        );
                        
                        if (result == 'completed') {
                           await _fetchJobs(); // verileri yenile
                           
                           // Ekrana başarı mesajı ve direkt rating popupı
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('İş tamamlandı! Lütfen değerlendirin.'), backgroundColor: Colors.green),
                             );
                             _showRatingDialog(app['application_id'].toString(), app);
                           }
                        }
                      },
                    ),
                  ),
                ]
                else if (status == 'completed') ...[
                  const SizedBox(height: 12),
                  if (app['rating'] == null || app['rating'].toString() == '0')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.star),
                        label: const Text('İşçiyi Puanla ve Değerlendir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
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
                                        index < int.parse(app['rating'].toString()) ? Icons.star : Icons.star_border,
                                        color: Colors.amber, 
                                        size: 16
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (app['review_comment'] != null && app['review_comment'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '"${app['review_comment']}"',
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
          );
        }).toList(),
      ],
    );
  }
}
