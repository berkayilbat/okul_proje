import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'validators.dart';
import 'package:flutter/services.dart';
import 'widgets/phone_input_formatter.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_theme_toggle.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Doğrulama Anahtarları
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  AutovalidateMode _autoValidateStep2 = AutovalidateMode.disabled;
  AutovalidateMode _autoValidateStep3 = AutovalidateMode.disabled;

  // Rol Seçimi: true -> İşveren, false -> Çalışan (Varsayılan: Çalışan)
  bool _isEmployer = false;

  // Form Kontrolcüleri - Kişisel & Kurumsal Bilgiler (Adım 2)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _tcController = TextEditingController();
  final _companyController = TextEditingController();
  final _taxNoController = TextEditingController();
  DateTime? _selectedBirthDate;

  // Form Kontrolcüleri - İletişim & Güvenlik (Adım 3)
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;

  String get _cleanPhone => PhoneInputFormatter.toDbFormat(_phoneController.text);

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _tcController.dispose();
    _companyController.dispose();
    _taxNoController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- DOĞUM TARİHİ SEÇİCİ ---
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Doğum Tarihinizi Seçin',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
      });
      // Seçildiğinde in-line validasyonu tetikle
      _formKeyStep2.currentState?.validate();
    }
  }

  // --- ADIM BAZLI DOĞRULAMA (IN-LINE VALIDATION) ---
  bool _validateStep(int step) {
    if (step == 0) {
      // 1. Adım: Rol seçimi her zaman geçerlidir
      return true;
    } else if (step == 1) {
      setState(() => _autoValidateStep2 = AutovalidateMode.onUserInteraction);
      return _formKeyStep2.currentState?.validate() ?? false;
    } else if (step == 2) {
      setState(() => _autoValidateStep3 = AutovalidateMode.onUserInteraction);
      return _formKeyStep3.currentState?.validate() ?? false;
    }
    return true;
  }

  // --- CANLI TC / VERGİ NO DOĞRULAMA İKONU ---
  Widget? _buildIdSuffixIcon(String text) {
    final clean = text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return null;

    if (clean.length == 11) {
      final isValid = Validators.isValidIdNumber(clean);
      return Icon(
        isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: isValid ? AppColors.success : AppColors.error,
        size: 20,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        '${clean.length}/11',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // --- ADIMLAR ARASI GEÇİŞ ---
  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _register();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- KAYIT İŞLEMİ ---
  Future<void> _register() async {
    if (!_validateStep(2)) return;

    setState(() => _isLoading = true);

    final birthDateStr =
        "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}";

    final role = _isEmployer ? 'Employer' : 'Employee';
    final firstName = _firstNameController.text.trim();

    final result = await AuthService.register(
      role: role,
      firstName: firstName,
      lastName: _lastNameController.text.trim(),
      phone: _cleanPhone,
      password: _passwordController.text,
      birthDate: birthDateStr,
      tcKimlikNo: _isEmployer ? null : _tcController.text.trim(),
      companyName: _isEmployer ? _companyController.text.trim() : null,
      taxNo: _isEmployer ? _taxNoController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      _showSuccessDialog(role, firstName);
    } else {
      String errMsg = result['message'] ?? 'Kayıt başarısız oldu.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- BAŞARILI KAYIT DİYALOĞU ---
  void _showSuccessDialog(String role, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 46,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tebrikler, Kaydınız Tamamlandı!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Aramıza hoş geldin $name!\n${role == "Employer" ? "İşveren" : "Çalışan"} hesabınız başarıyla oluşturuldu. Şimdi belirlediğiniz telefon numaranızla giriş yapabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Diyaloğu kapat
                  Navigator.pop(context); // Giriş ekranına dön
                },
                child: const Text(
                  'Giriş Ekranına Git',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: AnimatedThemeToggle(width: 58, height: 28),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // ÜST ADIM GÖSTERGESİ (PROGRESS STEPPER)
            _buildStepIndicator(isDark),
            const SizedBox(height: 8),

            // ÇOKLU PENCERE / SAYFA ALANI (PAGEVIEW)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildStep1RoleSelection(isDark),
                  _buildStep2PersonalDetails(isDark),
                  _buildStep3SecurityAndContact(isDark),
                ],
              ),
            ),

            // ALT AKSİYON BAR (GERİ & DEVAM ET / KAYIT OL)
            _buildBottomActionBar(isDark),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: ÜST ADIM İLERLEME GÖSTERGESİ
  // ===========================================================================
  Widget _buildStepIndicator(bool isDark) {
    final steps = ['Rol Seçimi', 'Kimlik & Bilgi', 'İletişim & Şifre'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = _currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            );
          } else {
            final stepIndex = index ~/ 2;
            final isActive = _currentStep == stepIndex;
            final isCompleted = _currentStep > stepIndex;

            Color circleColor;
            Color textColor;

            if (isActive) {
              circleColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
              textColor = isDark ? Colors.black : Colors.white;
            } else if (isCompleted) {
              circleColor = AppColors.success;
              textColor = Colors.white;
            } else {
              circleColor = isDark ? AppColors.darkInput : AppColors.lightBorder;
              textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                    border: Border.all(
                      color: isActive
                          ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  // ===========================================================================
  // 1. ADIM: ROL SEÇİMİ (BÜYÜK KARTLAR İLE KARŞILAMA)
  // ===========================================================================
  Widget _buildStep1RoleSelection(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hesap Tipinizi Seçin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Uygulamayı hangi amaçla kullanacağınızı belirtin. Bu seçime göre kayıt formunuz şekillendirilecektir.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ÇALIŞAN KARTI
          _buildRoleCard(
            title: 'Çalışanım / İş Arıyorum',
            description:
                'Esnek vardiyalara ve part-time iş ilanlarına başvur, QR kod ile mesai başlat ve ödemelerini takip et.',
            icon: Icons.person_search_rounded,
            isSelected: !_isEmployer,
            onTap: () => setState(() => _isEmployer = false),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // İŞVEREN KARTI
          _buildRoleCard(
            title: 'İşverenim / Mekan Sahibiyim',
            description:
                'İşletmenize anlık personel bulun, vardiyalı iş ilanları yayınlayın ve QR kod ile katılımı doğrulayın.',
            icon: Icons.storefront_rounded,
            isSelected: _isEmployer,
            onTap: () => setState(() => _isEmployer = true),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBorderColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveBorderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark
        ? (isSelected ? AppColors.darkInput : AppColors.darkCard)
        : (isSelected ? Colors.blue.shade50.withValues(alpha: 0.5) : AppColors.lightCard);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBorderColor : inactiveBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        .withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkInput : AppColors.lightInput),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. ADIM: KİŞİSEL BİLGİLER VE KİMLİK / KURUMSAL VERİLER (IN-LINE VALIDATION)
  // ===========================================================================
  Widget _buildStep2PersonalDetails(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKeyStep2,
        autovalidateMode: _autoValidateStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEmployer ? 'İşveren & Şirket Bilgileri' : 'Kişisel & Kimlik Bilgileri',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lütfen resmi kimlik kayıtlarınızla uyuşan doğru bilgileri girin.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // AD ALANI
            TextFormField(
              controller: _firstNameController,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ad',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ad alanı zorunludur.';
                if (RegExp(r'[0-9]').hasMatch(val)) return 'Ad alanında rakam kullanılamaz.';
                if (val.trim().length < 2) return 'En az 2 karakter giriniz.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // SOYAD ALANI
            TextFormField(
              controller: _lastNameController,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Soyad',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Soyad alanı zorunludur.';
                if (RegExp(r'[0-9]').hasMatch(val)) return 'Soyad alanında rakam kullanılamaz.';
                if (val.trim().length < 2) return 'En az 2 karakter giriniz.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // DOĞUM TARİHİ ALANI
            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _selectBirthDate,
              decoration: const InputDecoration(
                labelText: 'Doğum Tarihi (En az 18 Yaş)',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (_selectedBirthDate == null || val == null || val.isEmpty) {
                  return 'Lütfen doğum tarihinizi seçin.';
                }
                final today = DateTime.now();
                final adultDate = DateTime(
                  _selectedBirthDate!.year + 18,
                  _selectedBirthDate!.month,
                  _selectedBirthDate!.day,
                );
                if (today.isBefore(adultDate)) {
                  return 'Kayıt olabilmek için en az 18 yaşında olmalısınız.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ROLE GÖRE ÖZEL ALANLAR
            if (_isEmployer) ...[
              // ŞİRKET / MEKAN ADI
              TextFormField(
                controller: _companyController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Şirket / Mekan Adı',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Şirket / Mekan Adı zorunludur.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // VERGİ KİMLİK NUMARASI (CANLI GERİ BİLDİRİM İLE)
              TextFormField(
                controller: _taxNoController,
                maxLength: 11,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Vergi Kimlik Numarası (11 Hane)',
                  hintText: '11 haneli vergi no',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                  suffixIcon: _buildIdSuffixIcon(_taxNoController.text),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vergi Kimlik Numarası zorunludur.';
                  }
                  if (val.trim().length != 11) {
                    return 'Vergi Kimlik No tam 11 haneli olmalıdır.';
                  }
                  if (!Validators.isValidIdNumber(val.trim())) {
                    return 'Vergi Kimlik Numarası algoritmaya uymuyor.';
                  }
                  return null;
                },
              ),
            ] else ...[
              // T.C. KİMLİK NUMARASI (CANLI GERİ BİLDİRİM İLE)
              TextFormField(
                controller: _tcController,
                maxLength: 11,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'T.C. Kimlik Numarası (11 Hane)',
                  hintText: '11 haneli T.C. Kimlik No',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  suffixIcon: _buildIdSuffixIcon(_tcController.text),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'T.C. Kimlik Numarası zorunludur.';
                  }
                  if (val.trim().length != 11) {
                    return 'T.C. Kimlik No tam 11 haneli olmalıdır.';
                  }
                  if (!Validators.isValidIdNumber(val.trim())) {
                    return 'T.C. Kimlik Numarası algoritmaya uymuyor.';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ADIM: İLETİŞİM & GÜVENLİK (TELEFON, ŞİFRE, ONAY - IN-LINE VALIDATION)
  // ===========================================================================
  Widget _buildStep3SecurityAndContact(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKeyStep3,
        autovalidateMode: _autoValidateStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İletişim & Hesap Güvenliği',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Uygulamaya giriş yapmak için kullanacağınız telefon numaranızı ve güçlü bir şifre belirleyin.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // TELEFON NUMARASI (MASKE VE DOĞRULAMA)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneInputFormatter(),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Telefon Numarası',
                hintText: '05XX XXX XX XX',
                prefixIcon: const Icon(Icons.phone_android_outlined),
                suffixIcon: Validators.isValidPhone(_phoneController.text)
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
                    : null,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              validator: (val) {
                if (_cleanPhone.isEmpty) {
                  return 'Telefon numarası zorunludur.';
                }
                if (!Validators.isValidPhone(_cleanPhone)) {
                  return 'Geçerli bir telefon numarası giriniz (Örn: 05XX XXX XX XX).';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ŞİFRE ALANI
            TextFormField(
              controller: _passwordController,
              maxLength: 20,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Şifre',
                helperText: '8-20 karakter, harf ve özel karakter içermelidir',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Şifre zorunludur.';
                if (!Validators.isValidPassword(val)) {
                  return 'En az 8 karakter, harf ve özel karakter içermelidir.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ŞİFRE TEKRAR ALANI
            TextFormField(
              controller: _confirmPasswordController,
              maxLength: 20,
              obscureText: _obscureConfirmPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Şifre Tekrar',
                prefixIcon: const Icon(Icons.lock_clock_outlined),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_confirmPasswordController.text.isNotEmpty &&
                        _confirmPasswordController.text == _passwordController.text)
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ],
                ),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Şifre tekrarı zorunludur.';
                if (val != _passwordController.text) return 'Girilen şifreler eşleşmiyor.';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ALT AKSİYON BUTONLARI (GERİ & DEVAM ET / KAYIT OL)
  // ===========================================================================
  Widget _buildBottomActionBar(bool isDark) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // GERİ BUTONU
          if (!isFirstStep) ...[
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _prevStep,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Geri'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // DEVAM ET VEYA KAYIT OL BUTONU
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep ? 'Kayıt Ol' : 'Devam Et',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Geriye dönük uyumluluk için alias
typedef TurkishPhoneInputFormatter = PhoneInputFormatter;
