import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_screen.dart';
import 'employee_onboarding_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String phone;

  const RoleSelectionScreen({super.key, required this.phone});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole; // 'Employer' veya 'Employee'
  bool _isLoading = false;

  Future<void> _saveRoleAndProceed() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen devam etmek için bir rol seçin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthService.setUserRole(widget.phone, _selectedRole!);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (_selectedRole == 'Employer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(role: 'Employer')),
        );
      } else {
        // Çalışan için onboarding ekranı
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeOnboardingScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol kaydedilemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hesap Rolü'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Başlık ve Açıklama
              const Text(
                'Aramıza Hoş Geldiniz! 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A49A6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'GigJet platformunu nasıl kullanmak istersiniz?\nLütfen size uygun rolü seçin:',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ROL 1: İŞVEREN
              _buildRoleCard(
                roleKey: 'Employer',
                icon: Icons.business_center,
                title: 'İşverenim (İlan Vermek İstiyorum)',
                subtitle: 'İşletmeniz, etkinliğiniz veya organizasyonlarınız için güvenilir çalışma arkadaşları bulun ve ilan yayınlayın.',
                badgeText: 'İşletmeler & Organizatörler',
                badgeColor: const Color(0xFF0A49A6),
              ),

              const SizedBox(height: 20),

              // ROL 2: ÇALIŞAN
              _buildRoleCard(
                roleKey: 'Employee',
                icon: Icons.badge,
                title: 'Çalışanım (İş Aramak İstiyorum)',
                subtitle: 'Garson, vale, barista, fuar hostu gibi günlük veya etkinlik bazlı ilanlara başvurun, ödemenizi anında alın.',
                badgeText: 'Öğrenciler & Serbest Çalışanlar',
                badgeColor: Colors.teal.shade700,
              ),

              const Spacer(),

              // Devam Et Butonu
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedRole == null ? null : _saveRoleAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A49A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Devam Et',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    final isSelected = _selectedRole == roleKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = roleKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A49A6) : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0A49A6).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 8,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0A49A6)
                        : const Color(0xFF0A49A6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected ? Colors.white : const Color(0xFF0A49A6),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: roleKey,
                  groupValue: _selectedRole,
                  activeColor: const Color(0xFF0A49A6),
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
