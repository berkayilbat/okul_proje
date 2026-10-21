import 'utils/job_helpers.dart';
import 'utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'add_job_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final dynamic job;
  final bool isEmployer;
  final bool hasApplied;
  final VoidCallback? onApply;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.isEmployer = false,
    this.hasApplied = false,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16191E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF282F3A) : Colors.grey.shade200;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final textBody = isDark ? const Color(0xFFE2E8F0) : Colors.grey.shade800;

    final jobId = job['id']?.toString() ?? '0';
    final title = job['title']?.toString() ?? 'İlan Başlığı';
    final wage = job['wage']?.toString() ?? '0';
    final location = job['location']?.toString() ?? 'Konum Belirtilmemiş';
    final workingHours = job['working_hours']?.toString() ?? 'Esnek Saatler';
    final dates = job['dates']?.toString() ?? 'Belirtilmemiş';
    final description = job['description']?.toString() ?? 'Açıklama bulunmuyor.';
    final employerPhone = job['employer_phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (isEmployer && (job['status'] == null || job['status'] == 'open'))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'İlanı Düzenle',
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  AppPageRoute.slideUp(AddJobScreen(jobToEdit: job)),
                );
                if (updated == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // HERO HEADER KARTI (Kart Genişlemesi)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E232B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF282F3A) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                JobCategoryHelper.getCategoryIcon(title),
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'job-title-$jobId',
                                    flightShuttleBuilder: AppHeroHelper.flightShuttleBuilder,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Text(
                                        title.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                            const SizedBox(width: 10),
                            Hero(
                              tag: 'job-wage-$jobId',
                              flightShuttleBuilder: AppHeroHelper.flightShuttleBuilder,
                              child: Material(
                                type: MaterialType.transparency,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                        '$wage₺',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
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
                                          fontSize: 10,
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
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // TEMEL DETAYLAR KARTI (GRID)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Çalışma Saatleri',
                          value: workingHours,
                          iconColor: Colors.blue,
                          textColor: textBody,
                          subColor: textSecondary,
                        ),
                        Divider(color: cardBorder, height: 20),
                        _buildDetailRow(
                          icon: Icons.calendar_month_rounded,
                          label: 'Çalışma Tarihi',
                          value: dates,
                          iconColor: Colors.indigo,
                          textColor: textBody,
                          subColor: textSecondary,
                        ),
                        Divider(color: cardBorder, height: 20),
                        _buildDetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Ödeme Güvencesi',
                          value: 'İş Bitiminde Anında Hesaba',
                          iconColor: const Color(0xFF10B981),
                          textColor: textBody,
                          subColor: textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // İŞ AÇIKLAMASI
                  Text(
                    'İş Açıklaması',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: textBody,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // İŞVEREN BİLGİ ROZETİ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E232B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.15) : Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            color: isDark ? AppColors.darkPrimary : Colors.blue.shade800,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'İşletme / İşveren',
                                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                employerPhone.isNotEmpty ? employerPhone : 'Yetkili İlanı',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 14),
                              SizedBox(width: 4),
                              Text('Onaylı', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // ALT AKSİYON BUTONU
          if (!isEmployer)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: hasApplied ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasApplied ? Colors.grey : primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      hasApplied ? 'Bu İlana Başvuruldu' : 'Hemen Başvur ($wage₺)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            )
          else if (job['status'] == null || job['status'] == 'open')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: const Text('İlanı Düzenle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        AppPageRoute.slideUp(AddJobScreen(jobToEdit: job)),
                      );
                      if (updated == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
