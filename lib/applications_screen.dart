import 'package:flutter/material.dart';
import 'job_service.dart';
import 'qr_generate_screen.dart';
import 'qr_scan_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final bool isEmployer;
  final bool isHistory;

  const ApplicationsScreen({super.key, required this.isEmployer, this.isHistory = false});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    final apps = await JobService.getApplications(widget.isEmployer);
    if (mounted) {
      setState(() {
        // Geçmiş filtresiyse (sadece tamamlanmış ya da reddedilmiş işler)
        if (widget.isHistory) {
          _applications = apps.where((app) => app['app_status'] == 'completed').toList();
        } else {
          // Aktif başvurular
          _applications = apps.where((app) => app['app_status'] != 'completed').toList();
        }
        _isLoading = false;
      });
    }
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
      _fetchApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A148C)))
        : RefreshIndicator(
            onRefresh: _fetchApplications,
            color: const Color(0xFF4A148C),
            child: _applications.isEmpty ? _buildEmptyState() : _buildList(),
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
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              widget.isHistory ? 'Geçmiş işleminiz bulunmuyor.' : 'Hiç başvuru yok.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
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
                    app['title'].toString().toUpperCase(),
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
                   Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                   const SizedBox(width: 4),
                   Text(
                     'Başvuran: ${app['first_name']} ${app['last_name']}',
                     style: TextStyle(color: Colors.grey.shade800, fontSize: 16, fontWeight: FontWeight.w500),
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
                  onPressed: () {
                    // İşe Başlama QR: START|id
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRGenerateScreen(qrData: 'START|${app['application_id']}'),
                      ),
                    );
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
                    backgroundColor: const Color(0xFF4A148C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: () async {
                    // İşçi, işverenin oluşturduğu FINISH|id barkodunu arıyor
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScanScreen()),
                    );
                    
                    if (result != null && result.toString() == 'FINISH|${app['application_id']}') {
                        _manageApplication(app['application_id'].toString(), 'complete');
                    } else if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yanlış veya Geçersiz QR kod!'), backgroundColor: Colors.red),
                        );
                    }
                  },
                ),
              ),

          ],
        ),
      ),
    );
  }
}
