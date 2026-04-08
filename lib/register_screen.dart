import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'validators.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  List<bool> _selections = [true, false];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _companyController = TextEditingController();
  final _taxNoController = TextEditingController();
  final _tcController = TextEditingController();

  bool _isLoading = false;

  void _register() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen zorunlu alanları doldurun.')));
        return;
    }

    if (RegExp(r'[0-9]').hasMatch(_firstNameController.text) || RegExp(r'[0-9]').hasMatch(_lastNameController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad ve Soyad alanlarında sadece harf kullanılabilir (rakam girilemez).')));
        return;
    }
    
    if (!Validators.isValidPhone(_phoneController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefon numaranız 0 ile başlamalı, 11 hane olmalı ve sadece rakam içermelidir.')));
        return;
    }

    if (!Validators.isValidPassword(_passwordController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifreniz en az 8, en fazla 20 karakter uzunluğunda olmalı; ve mutlaka harf ile özel karakter içermelidir.')));
        return;
    }

    bool isEmployer = _selections[0];
    
    if (isEmployer && (_companyController.text.isEmpty || _taxNoController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şirket Adı ve Vergi Kimlik No gereklidir.')));
        return;
    }

    if (isEmployer && !Validators.isValidIdNumber(_taxNoController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vergi Kimlik Numarası tam 11 haneli olmak zorundadır ve algoritma kuralına uymalıdır.')));
        return;
    }

    if (!isEmployer && _tcController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TC Kimlik No gereklidir.')));
        return;
    }
    
    if (!isEmployer && !Validators.isValidIdNumber(_tcController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TC Kimlik Numarası tam 11 haneli olmak zorundadır ve algoritma kuralına uymalıdır.')));
        return;
    }

    setState(() => _isLoading = true);

    await AuthService.register(
      role: isEmployer ? 'Employer' : 'Employee',
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      tcKimlikNo: _tcController.text,
      companyName: _companyController.text,
      taxNo: _taxNoController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isEmployer = _selections[0];

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ToggleButtons(
                isSelected: _selections,
                onPressed: (index) {
                  setState(() {
                    _selections = [index == 0, index == 1];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
                children: const [
                  Text('İşveren'),
                  Text('Çalışan'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController, 
              maxLength: 30, 
              decoration: const InputDecoration(labelText: 'Ad', border: OutlineInputBorder(), counterText: ''),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController, 
              maxLength: 30, 
              decoration: const InputDecoration(labelText: 'Soyad', border: OutlineInputBorder(), counterText: ''),
            ),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, maxLength: 11, decoration: const InputDecoration(labelText: 'Telefon Numarası', border: OutlineInputBorder(), counterText: ''), keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, maxLength: 20, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(), counterText: ''), obscureText: true),
            const SizedBox(height: 24),
            
            if (isEmployer) ...[
              TextField(controller: _companyController, maxLength: 50, decoration: const InputDecoration(labelText: 'Şirket/Mekan Adı', border: OutlineInputBorder(), counterText: '')),
              const SizedBox(height: 16),
              TextField(controller: _taxNoController, maxLength: 11, decoration: const InputDecoration(labelText: 'Vergi Kimlik No (11 Hane)', border: OutlineInputBorder(), counterText: ''), keyboardType: TextInputType.number),
            ] else ...[
              TextField(controller: _tcController, maxLength: 11, decoration: const InputDecoration(labelText: 'TC Kimlik No (11 Hane)', border: OutlineInputBorder(), counterText: ''), keyboardType: TextInputType.number),
            ],
            
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _register,
                    child: const Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
                  ),
                ),
          ],
        )
      )
    );
  }
}
