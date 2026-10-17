import 'package:flutter/material.dart';
import 'auth_service.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phone;

  const EmployeeProfileScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _jobCount = 0;
  List<dynamic> _recentJobs = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final stats = await AuthService.getUserProfileStats(widget.phone, 'Employee');
    if (mounted) {
      setState(() {
        _jobCount = stats['job_count'] ?? 0;
        final rating = stats['average_rating'];
        if (rating is int) {
           _averageRating = rating.toDouble();
        } else if (rating is double) {
           _averageRating = rating;
        }
        if (stats['recent_jobs'] != null && stats['recent_jobs'] is List) {
           _recentJobs = stats['recent_jobs'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = '${widget.firstName.isNotEmpty ? widget.firstName[0] : ''}${widget.lastName.isNotEmpty ? widget.lastName[0] : ''}'.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF111827);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışan Profili', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: isDark ? const Color(0xFF1E232B) : const Color(0xFF111827).withOpacity(0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.firstName} ${widget.lastName}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade600, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Onaylı Çalışan',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF4ADE80) : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildProfileInfoCard(
              icon: Icons.phone_android,
              title: 'İletişim Numarası',
              value: widget.phone,
            ),
            const SizedBox(height: 16),
            
            _buildProfileInfoCard(
              icon: Icons.star_rounded,
              title: 'Ortalama Puan',
              value: _averageRating > 0 ? '${_averageRating.toStringAsFixed(1)} / 5.0' : 'Henüz değerlendirme yok',
              valueColor: _averageRating > 0 ? Colors.amber.shade700 : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            _buildProfileInfoCard(
              icon: Icons.work_history,
              title: 'Tamamlanan İş',
              value: '$_jobCount',
              valueColor: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
            ),
            
            const SizedBox(height: 40),
            
            if (_recentJobs.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Yorumlar ve Değerlendirmeler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              ..._recentJobs.where((j) => (j['rating'] != null && j['rating'] > 0) || (j['comment'] != null && j['comment'].isNotEmpty)).map((job) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16191E) : Colors.white,
                    border: Border.all(color: isDark ? const Color(0xFF282F3A) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job['title'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 15,
                                color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                              ),
                            ),
                          ),
                          if (job['rating'] != null && job['rating'] > 0)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  job['rating'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (job['comment'] != null && job['comment'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${job['comment']}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic, 
                            color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16191E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF282F3A) : Colors.transparent),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232B) : const Color(0xFF111827).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? (isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
