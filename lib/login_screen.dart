import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<bool> _selections = [true, false];
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  int _failedAttempts = 0; // Hatalı giriş limiti sayacı

  void _login() async {
    if (_failedAttempts >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Çok fazla hatalı giriş yaptınız. Lütfen daha sonra tekrar deneyiniz veya şifrenizi sıfırlayınız.',
          ),
        ),
      );
      return;
    }

    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen telefon ve şifrenizi girin.')),
      );
      return;
    }

    if (!Validators.isValidPhone(_phoneController.text)) {
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
    final role = _selections[0] ? 'Employer' : 'Employee';

    bool isSuccess = await AuthService.login(
      _phoneController.text,
      _passwordController.text,
      _rememberMe,
      role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      _failedAttempts = 0;
      final prefs = await SharedPreferences.getInstance();
      int isComplete = prefs.getInt('is_profile_complete') ?? 0;

      if (role == 'Employee' && isComplete == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeOnboardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(role: role)),
        );
      }
    } else {
      setState(() {
        _failedAttempts++;
      });
      int remaining = 5 - _failedAttempts;
      if (remaining > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hatalı giriş yaptınız. Kalan hakkınız: $remaining'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5 hatalı deneme hakkınız doldu. Giriş engellendi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isButtonDisabled = _failedAttempts >= 5;

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: _selections,
                onPressed: (index) {
                  setState(() {
                    _selections = [index == 0, index == 1];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
                children: const [Text('İşveren'), Text('Çalışan')],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  // Şifremi unuttum butonu
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
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isButtonDisabled ? null : _login,
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 18),
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
            ],
          ),
        ),
      ),
    );
  }
}
