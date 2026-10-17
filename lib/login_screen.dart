import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_onboarding_screen.dart';
import 'role_selection_screen.dart';
import 'server_config.dart';
import 'job_service.dart';
import 'widgets/animated_theme_toggle.dart';
import 'theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ===========================================================================
  // TEST MODU BAYPAS AYARI:
  // true  -> Sunucuya ulaşılamazsa dahi mock kullanıcıyla girişe izin verir.
  // false -> Tamamen sunucu doğrulaması devrededir.
  // ===========================================================================
  static const bool _bypassAuthForTesting = false;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isSeeding = false;
  bool? _isServerConnected;

  int _failedAttempts = 0; // Hatalı giriş limiti sayacı

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    final ok = await ServerConfig.testConnection();
    if (mounted) {
      setState(() {
        _isServerConnected = ok;
      });
    }
  }

  void _quickDemoLogin(String phone, String password) {
    _phoneController.text = phone;
    _passwordController.text = password;
    _login();
  }

  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    final res = await JobService.seedDatabase();
    if (!mounted) return;
    setState(() => _isSeeding = false);

    final isSuccess = res['status'] == 'success';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? (isSuccess ? 'Demo verileri yüklendi!' : 'Hata oluştu')),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    _checkServerStatus();
  }

  void _showServerConfigDialog() {
    final hostController = TextEditingController(text: ServerConfig.activeHost);
    bool testing = false;
    String? testResult;
    Color testColor = Colors.grey;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.wifi_tethering, color: Color(0xFF111827)),
                SizedBox(width: 8),
                Text('Sunucu / IP Ayarı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İki telefon arasında demo yaparken bilgisayarınızın yerel IP adresini girin (Bilgisayar ve telefonlar aynı Wi-Fi/Hotspot üzerinde olmalıdır):',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hostController,
                    decoration: const InputDecoration(
                      labelText: 'Sunucu Host / IP',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Hızlı Seçim:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('192.168.1.7 (Yerel Ağ)', style: TextStyle(fontSize: 11)),
                        onPressed: () => setStateSB(() => hostController.text = '192.168.1.7'),
                      ),
                      ActionChip(
                        label: const Text('10.0.2.2 (Emülatör)', style: TextStyle(fontSize: 11)),
                        onPressed: () => setStateSB(() => hostController.text = '10.0.2.2'),
                      ),
                      ActionChip(
                        label: const Text('127.0.0.1 (Web / PC)', style: TextStyle(fontSize: 11)),
                        onPressed: () => setStateSB(() => hostController.text = '127.0.0.1'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                        ),
                        icon: testing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.network_ping, size: 16),
                        label: const Text('Test Et', style: TextStyle(fontSize: 12)),
                        onPressed: testing
                            ? null
                            : () async {
                                setStateSB(() {
                                  testing = true;
                                  testResult = null;
                                });
                                final ok = await ServerConfig.testConnection(hostController.text);
                                setStateSB(() {
                                  testing = false;
                                  if (ok) {
                                    testResult = '✅ Bağlantı Başarılı!';
                                    testColor = Colors.green;
                                  } else {
                                    testResult = '❌ Ulaşılamadı (IP veya XAMPP kontrol edin)';
                                    testColor = Colors.red;
                                  }
                                });
                              },
                      ),
                      const SizedBox(width: 12),
                      if (testResult != null)
                        Expanded(
                          child: Text(
                            testResult!,
                            style: TextStyle(color: testColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await ServerConfig.setCustomHost(hostController.text);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _checkServerStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sunucu adresi güncellendi: ${ServerConfig.baseUrl}')),
                  );
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (_failedAttempts >= 5 && !_bypassAuthForTesting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Çok fazla hatalı giriş yaptınız. Lütfen daha sonra tekrar deneyiniz veya şifrenizi sıfırlayınız.',
          ),
        ),
      );
      return;
    }

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen telefon ve şifrenizi girin.')),
      );
      return;
    }

    if (!Validators.isValidPhone(phone) && !_bypassAuthForTesting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Geçerli bir telefon numarası giriniz (0 ile başlayan, toplam 11 hane).',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final loginRes = await AuthService.login(phone, password, _rememberMe);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (loginRes['success'] == true) {
      _failedAttempts = 0;
      final String role = (loginRes['role'] ?? '').toString();
      final int isComplete = loginRes['is_profile_complete'] ?? 0;

      // 1. ROL HENÜZ BELİRLENMEMİŞSE -> İLK GİRİŞ ROL SEÇİM EKRANI
      if (role.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionScreen(phone: phone),
          ),
        );
        return;
      }

      // 2. ÇALIŞAN VE PROFİLİ EKSİKSE -> ONBOARDING EKRANI
      if (role == 'Employee' && isComplete == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeOnboardingScreen()),
        );
        return;
      }

      // 3. ROLÜ BELLİ İSE -> DOĞRUDAN İLGİLİ ANA SAYFA (İŞVEREN VEYA ÇALIŞAN)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(role: role)),
      );
    } else {
      // Giriş Başarısız
      if (_bypassAuthForTesting) {
        // Test modunda sunucu kapalıysa bile devam et
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', phone);
        await prefs.setString('first_name', 'Test');
        await prefs.setString('last_name', 'Kullanıcı');
        await prefs.setInt('is_profile_complete', 1);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionScreen(phone: phone),
          ),
        );
        return;
      }

      setState(() {
        _failedAttempts++;
      });
      int remaining = 5 - _failedAttempts;
      final errorMsg = loginRes['message'] ?? 'Giriş yapılamadı.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMsg ${remaining > 0 ? "Kalan hakkınız: $remaining" : "Giriş engellendi."}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isButtonDisabled = !_bypassAuthForTesting && _failedAttempts >= 5;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_bypassAuthForTesting ? 'Giriş Yap (Test Modu)' : 'Giriş Yap'),
        actions: [
          // Ağ ve Sunucu Ayarı Butonu (Yeşil/Kırmızı göstergeli)
          IconButton(
            tooltip: 'Sunucu / IP Ayarları',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.wifi_tethering),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isServerConnected == true
                          ? Colors.green
                          : (_isServerConnected == false ? Colors.red : Colors.orange),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: _showServerConfigDialog,
          ),
          // Hızlı Demo Veri Yükleme Butonu
          IconButton(
            tooltip: 'Hazır Veri Yükle (Seed Data)',
            icon: _isSeeding
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_sync),
            onPressed: _isSeeding ? null : _seedDemoData,
          ),
          // Karanlık / Açık Mod Animasyonlu Kapsül Switch
          const Padding(
            padding: EdgeInsets.only(right: 12.0, left: 4.0),
            child: AnimatedThemeToggle(width: 60, height: 30),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HIZLI CANLI DEMO KARTI (Otomatik Rol Tespiti ile)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : null,
                  gradient: isDark
                      ? null
                      : LinearGradient(
                          colors: [const Color(0xFF111827).withValues(alpha: 0.08), Colors.blue.shade50],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFF111827).withValues(alpha: 0.2),
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Tek Tıkla Canlı Demo Girişi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.darkSecondary : const Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _isSeeding ? null : _seedDemoData,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 14,
                                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isSeeding ? 'Yükleniyor...' : 'Verileri Sıfırla',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.business_center, size: 18),
                            label: const Text('1. Telefon:\nİşveren Gir', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                            onPressed: () => _quickDemoLogin('05445073525', '123'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.person, size: 18),
                            label: const Text('2. Telefon:\nÇalışan Gir', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                            onPressed: () => _quickDemoLogin('05438296484', '123'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // GİRİŞ ALANLARI (Sade ve Rol Seçimsiz!)
              TextField(
                controller: _phoneController,
                maxLength: _bypassAuthForTesting ? null : 11,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '05XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: _bypassAuthForTesting ? TextInputType.text : TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                maxLength: _bypassAuthForTesting ? null : 20,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kayıtlı numaranıza sıfırlama linki gönderildi.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Şifremi Unuttum'),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (val) =>
                        setState(() => _rememberMe = val ?? false),
                  ),
                  const Text('Beni Hatırla'),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isButtonDisabled ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                          foregroundColor: isDark ? const Color(0xFF111827) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  'Hesabın yok mu? Kayıt Ol',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),
              // Aktif Sunucu Bilgi Çubuğu
              InkWell(
                onTap: _showServerConfigDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: _isServerConnected == true
                            ? Colors.green
                            : (_isServerConnected == false ? Colors.red : Colors.orange),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sunucu: ${ServerConfig.activeHost} (Ayarlar için tıkla)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
