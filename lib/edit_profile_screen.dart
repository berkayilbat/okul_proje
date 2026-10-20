import 'package:flutter/material.dart';
import 'constants.dart';
import 'auth_service.dart';
import 'validators.dart';
import 'widgets/phone_input_formatter.dart';
import 'widgets/app_snackbar.dart';
import 'widgets/network_error_view.dart';
import 'widgets/app_refresh_indicator.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final String userPhone;
  final String role;

  const EditProfileScreen({super.key, required this.userPhone, required this.role});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _taxNoController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasLoadError = false;
  String? _errorMessage;

  final List<String> _availableProfessions = List.from(AppConstants.availableProfessions);

  Set<String> _selectedProfessions = {};

  Widget? _buildTaxSuffixIcon(String text) {
    final clean = text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return null;

    if (clean.length == 10) {
      final isValid = Validators.isValidTaxNumber(clean);
      return Icon(
        isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: isValid ? AppColors.success : AppColors.error,
        size: 20,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        '${clean.length}/10',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _errorMessage = null;
    });

    final res = await AuthService.getProfileDetails(widget.userPhone);
    if (!mounted) return;

    if (res['success'] != true) {
      setState(() {
        _hasLoadError = true;
        _errorMessage = res['message']?.toString() ?? 'Profil bilgileri alınamadı.';
        _isLoading = false;
      });
      return;
    }

    final details = (res['data'] as Map<String, dynamic>?) ?? {};
    if (details.isNotEmpty) {
      _phoneController.text = PhoneInputFormatter.format(details['phone']?.toString() ?? '');
      _addressController.text = details['address']?.toString() ?? '';
      _firstNameController.text = details['first_name']?.toString() ?? '';
      _lastNameController.text = details['last_name']?.toString() ?? '';
      _taxNoController.text = details['tax_no']?.toString() ?? '';
      
      final profs = details['professions']?.toString() ?? '';
      if (profs.isNotEmpty) {
         final profList = profs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
         _selectedProfessions = profList.toSet();
         
         for (var prof in profList) {
           if (!_availableProfessions.contains(prof)) {
             _availableProfessions.add(prof);
           }
         }
      }
    }
    
    setState(() {
      _hasLoadError = false;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      AppSnackbar.showWarning(
        context,
        'Lütfen formdaki hatalı alanları kontrol edin.',
      );
      return;
    }

    if (widget.role == 'Employee' && _selectedProfessions.isEmpty) {
      AppSnackbar.showWarning(context, 'Lütfen en az bir meslek seçin.');
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final newPhone = PhoneInputFormatter.toDbFormat(rawPhone);
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    setState(() => _isSaving = true);

    final professionsStr = _selectedProfessions.join(', ');
    
    final result = await AuthService.updateProfile(
      oldPhone: widget.userPhone,
      phone: newPhone,
      firstName: Validators.sanitizeText(firstName),
      lastName: Validators.sanitizeText(lastName),
      taxNo: widget.role == 'Employer' ? Validators.sanitizeText(_taxNoController.text.trim()) : null,
      address: widget.role == 'Employee' ? Validators.sanitizeText(_addressController.text.trim()) : null,
      professions: widget.role == 'Employee' ? Validators.sanitizeText(professionsStr) : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['status'] == 'success') {
      AppSnackbar.showSuccess(context, 'Profil başarıyla güncellendi!');
      Navigator.pop(context, newPhone);
    } else {
      AppSnackbar.showError(
        context,
        result['message'] ?? 'Güncelleme hatası.',
        onRetry: result['is_network_error'] == true ? _saveProfile : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmployee = widget.role == 'Employee';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF111827);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilimi Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _hasLoadError
            ? AppRefreshIndicator(
                onRefresh: _loadProfileDetails,
                child: NetworkErrorView(
                  message: _errorMessage,
                  onRetry: _loadProfileDetails,
                ),
              )
            : AppRefreshIndicator(
                onRefresh: _loadProfileDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kişisel Bilgiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                inputFormatters: [Validators.nameInputFormatter, LengthLimitingTextInputFormatter(50)],
                                validator: (val) {
                                  final text = val?.trim() ?? '';
                                  if (text.isEmpty) return 'Ad zorunludur.';
                                  if (!Validators.isValidName(text)) return 'Sadece harf giriniz.';
                                  if (text.length < 2) return 'En az 2 karakter giriniz.';
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Ad',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                inputFormatters: [Validators.nameInputFormatter, LengthLimitingTextInputFormatter(50)],
                                validator: (val) {
                                  final text = val?.trim() ?? '';
                                  if (text.isEmpty) return 'Soyad zorunludur.';
                                  if (!Validators.isValidName(text)) return 'Sadece harf giriniz.';
                                  if (text.length < 2) return 'En az 2 karakter giriniz.';
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Soyad',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Text('İletişim Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 14,
                          inputFormatters: [PhoneInputFormatter()],
                          validator: (val) {
                            final text = val?.trim() ?? '';
                            if (text.isEmpty) return 'Telefon boş bırakılamaz.';
                            if (!Validators.isValidPhone(text)) {
                              return 'Geçerli bir telefon numarası giriniz (05XX...).';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası',
                            hintText: '05XX XXX XX XX',
                            counterText: '',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        if (widget.role == 'Employer') ...[
                          Text('Kurumsal Bilgiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _taxNoController,
                            maxLength: 10,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (widget.role != 'Employer') return null;
                              final text = val?.trim() ?? '';
                              if (text.isEmpty) return 'Vergi Kimlik Numarası zorunludur.';
                              if (text.length != 10) return 'VKN tam 10 haneli olmalıdır.';
                              if (!Validators.isValidTaxNumber(text)) {
                                return 'Vergi Kimlik Numarası algoritmaya uymuyor.';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Vergi Kimlik Numarası (10 Hane)',
                              hintText: '10 haneli vergi no',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.receipt_long_outlined),
                              suffixIcon: _buildTaxSuffixIcon(_taxNoController.text),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        if (isEmployee) ...[
                          Text('İkametgah Adresi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            inputFormatters: [Validators.denyHtmlTagFormatter, LengthLimitingTextInputFormatter(255)],
                            maxLines: 3,
                            validator: (val) {
                              if (!isEmployee) return null;
                              final text = val?.trim() ?? '';
                              if (text.isEmpty) return 'İkametgah adresi zorunludur.';
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Adres',
                              border: OutlineInputBorder(),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 32.0),
                                child: Icon(Icons.location_on),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                  Text('Çalışabileceğiniz Meslekler (İstediğiniz kadar seçin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableProfessions.map((prof) {
                       final isSelected = _selectedProfessions.contains(prof);
                       return FilterChip(
                         label: Text(prof),
                         selected: isSelected,
                         backgroundColor: isDark ? const Color(0xFF1E232B) : null,
                         selectedColor: isDark ? const Color(0xFF1E3A8A) : Colors.blue.shade100,
                         checkmarkColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827),
                         side: BorderSide(color: isDark ? const Color(0xFF282F3A) : Colors.grey.shade300),
                         labelStyle: TextStyle(
                           color: isSelected 
                               ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF111827)) 
                               : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade800),
                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                         ),
                         onSelected: (bool selected) {
                           setState(() {
                             if (selected) {
                               _selectedProfessions.add(prof);
                             } else {
                               _selectedProfessions.remove(prof);
                             }
                           });
                         },
                       );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
