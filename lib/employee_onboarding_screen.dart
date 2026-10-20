import 'utils/app_page_route.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';
import 'widgets/app_snackbar.dart';
import 'theme/app_theme.dart';
import 'home_screen.dart';

class EmployeeOnboardingScreen extends StatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  State<EmployeeOnboardingScreen> createState() => _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends State<EmployeeOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  final _addressController = TextEditingController();
  final _professionsController = TextEditingController();

  List<String> _certificatePaths = [];
  List<String> _workplacePaths = [];

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(bool isCertificate) async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        if (isCertificate) {
          _certificatePaths.addAll(images.map((e) => e.path));
        } else {
          _workplacePaths.addAll(images.map((e) => e.path));
        }
      });
    }
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      AppSnackbar.showWarning(
        context,
        'Lütfen işaretli zorunlu alanları doldurun.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.uploadEmployeeProfile(
      address: _addressController.text.trim(),
      professions: _professionsController.text.trim(),
      certificatePaths: _certificatePaths,
      workplacePaths: _workplacePaths,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      AppSnackbar.showSuccess(context, 'Profiliniz başarıyla oluşturuldu!');
      Navigator.pushReplacement(context, AppPageRoute.fadeThrough(const HomeScreen(role: 'Employee')));
    } else {
      AppSnackbar.showError(
        context,
        result['message'] ?? 'Hata oluştu.',
      );
    }
  }

  Widget _buildImageGrid(List<String> paths, bool isCertificate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isCertificate ? 'Sertifika ve Belgeler' : 'Önceden Çalışılan Yerler (Kanıtlar)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: () => _pickImages(isCertificate),
              icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF0A49A6)),
              label: const Text('Ekle', style: TextStyle(color: Color(0xFF0A49A6))),
            )
          ],
        ),
        if (paths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: paths.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 8),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(paths[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isCertificate) {
                              _certificatePaths.removeAt(index);
                            } else {
                              _workplacePaths.removeAt(index);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: const Center(child: Text('Henüz fotoğraf eklenmedi', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilini Tamamla', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A49A6),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0A49A6)),
                  SizedBox(height: 16),
                  Text('Bilgileriniz yükleniyor, lütfen bekleyin...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sizi daha iyi tanıyabilmemiz ve işverenlerimize doğru sunabilmemiz için aşağıdaki bilgileri eksiksiz doldurun.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Lütfen oturduğunuz adresi girin.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Oturduğunuz Adres (Zorunlu)',
                        border: OutlineInputBorder(),
                        errorStyle: TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _professionsController,
                      maxLines: 2,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Lütfen en az bir meslek belirtin.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Aradığınız / Çalışabileceğiniz Meslekler (Zorunlu)',
                        border: OutlineInputBorder(),
                        hintText: 'Örn: Garson, Kasiyer, Temizlik Görevlisi...',
                        errorStyle: TextStyle(color: AppColors.error),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  _buildImageGrid(_certificatePaths, true),
                  const SizedBox(height: 24),
                  
                  _buildImageGrid(_workplacePaths, false),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A49A6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Profili Tamamla ve Uygulamaya Geç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
