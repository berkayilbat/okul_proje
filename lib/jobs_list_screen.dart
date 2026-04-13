import 'package:flutter/material.dart';
import 'job_service.dart';
import 'employee_profile_screen.dart';
import 'qr_generate_screen.dart';
import 'qr_scan_screen.dart';

class JobsListScreen extends StatefulWidget {
  final bool isEmployer;
  
  const JobsListScreen({super.key, required this.isEmployer});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  List<dynamic> _jobs = [];
  List<dynamic> _applications = []; // İşveren ise başvuru verisi 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    final jobs = await JobService.getJobs(widget.isEmployer);
    // Her iki rol için de kendi başvurularını / kendisine gelen başvuruları çekeriz
    final apps = await JobService.getApplications(widget.isEmployer);
    
    if (mounted) {
      setState(() {
        _jobs = jobs;
        _applications = apps;
        _isLoading = false;
      });
    }
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? (result['status'] == 'success' ? 'Başvuru başarılı!' : 'Bir hata oluştu')),
        backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _manageApplication(String id, String action) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await JobService.manageApplication(id, action);
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'İşlem yapıldı'),
        backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
    if (result['status'] == 'success') {
      _fetchJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A148C)))
        : RefreshIndicator(
            onRefresh: _fetchJobs,
            color: const Color(0xFF4A148C),
            child: _jobs.isEmpty ? _buildEmptyState() : _buildJobsList(),
          );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              widget.isEmployer ? 'Henüz hiç ilan açmadınız' : 'Şu an aktif açık ilan bulunmuyor',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(dynamic job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
                    job['title'].toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${job['wage']}₺',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  job['location'].toString(),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  job['working_hours'].toString(),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.date_range, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    job['dates'].toString(),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job['description'].toString(),
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            
            // Çalışan ise başvuru durumuna göre aksiyon, İşveren ise Başvuranlar Listesi
            _buildJobCardAction(job),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCardAction(dynamic job) {
    if (!widget.isEmployer) {
      final myApp = _applications.where((app) => app['job_id'].toString() == job['id'].toString()).firstOrNull;
      
      if (myApp == null) {
        // Henüz başvurulmamış ilan
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _applyForJob(job['id'].toString()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Bu İlana Başvur', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRGenerateScreen(qrData: 'START|${myApp['application_id']}'),
                  ),
                );
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
                backgroundColor: const Color(0xFF4A148C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScanScreen()),
                );
                if (result != null && result.toString() == 'FINISH|${myApp['application_id']}') {
                    _manageApplication(myApp['application_id'].toString(), 'complete');
                } else if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yanlış veya Geçersiz QR kod!'), backgroundColor: Colors.red),
                    );
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
    // Bu ilana ait başvuruları bul
    final jobApps = _applications.where((app) => app['job_id'].toString() == jobId).toList();

    if (jobApps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: jobStatus == 'open' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          jobStatus == 'open' ? 'İlan Aktif (Henüz başvuru yok)' : 'İlan Kapalı',
          style: TextStyle(
            color: jobStatus == 'open' ? Colors.blue.shade700 : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gelen Başvurular:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A148C)),
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
              border: Border.all(color: Colors.grey.shade300),
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
                            MaterialPageRoute(
                              builder: (context) => EmployeeProfileScreen(
                                firstName: app['first_name'].toString(),
                                lastName: app['last_name'].toString(),
                                phone: app['employee_phone'].toString(),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 18, color: Color(0xFF4A148C)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${app['first_name']} ${app['last_name']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 15, 
                                    color: Color(0xFF4A148C),
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _manageApplication(app['application_id'].toString(), 'accept'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Onayla'),
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
                          MaterialPageRoute(builder: (_) => const QRScanScreen()),
                        );
                        
                        if (result != null && result.toString() == 'START|${app['application_id']}') {
                            _manageApplication(app['application_id'].toString(), 'start_work');
                        } else if (result != null) {
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
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // İşveren Bitirme QR'ı oluşturur (FINISH|id)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QRGenerateScreen(qrData: 'FINISH|${app['application_id']}'),
                          ),
                        );
                      },
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
