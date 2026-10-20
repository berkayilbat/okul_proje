import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'job_service.dart';
import 'validators.dart';
import 'widgets/app_snackbar.dart';
import 'theme/app_theme.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController(); // Tarih okuma için eklendi
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  String? _selectedDistrict;

  void _publishJob() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      AppSnackbar.showWarning(
        context,
        'Lütfen işaretli tüm zorunlu alanları doldurun.',
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final cleanTitle = Validators.sanitizeText(_titleController.text);
    final cleanDistrict = Validators.sanitizeText(_selectedDistrict ?? '');
    final cleanLocationDetail = Validators.sanitizeText(_locationController.text);
    final fullLocation = "Ankara, $cleanDistrict, $cleanLocationDetail";
    final result = await JobService.addJob(
      title: cleanTitle,
      location: fullLocation,
      workingHours: Validators.sanitizeText(_hoursController.text),
      wage: _priceController.text.trim().replaceAll(',', '.'),
      description: Validators.sanitizeText(_descController.text),
      dates: Validators.sanitizeText(_dateController.text),
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (result['status'] == 'success') {
      AppSnackbar.showSuccess(context, 'İlanınız başarıyla yayınlandı!');
      Navigator.pop(context, true);
    } else {
      AppSnackbar.showError(
        context,
        result['message'] ?? 'Bir hata oluştu',
        onRetry: result['is_network_error'] == true ? _publishJob : null,
      );
    }
  }

  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Tarih Aralığı Seçin (En Fazla 5 Gün)',
    );

    if (picked != null) {
      if (picked.end.difference(picked.start).inDays > 4) {
        if (!mounted) return;
        AppSnackbar.showWarning(
          context,
          'İlanınız ilk günden itibaren en fazla 5 günlük olabilir! Lütfen tekrar seçin.',
        );
      } else {
        setState(() {
          _dateController.text = "${picked.start.day}/${picked.start.month}/${picked.start.year} - ${picked.end.day}/${picked.end.month}/${picked.end.year}";
        });
      }
    }
  }

  void _pickTimeRange() {
    TimeOfDay selectedStart = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay selectedEnd = const TimeOfDay(hour: 18, minute: 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 380,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Çalışma Saatlerini Belirleyin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Başlangıç', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              initialDateTime: DateTime(2023, 1, 1, 9, 0),
                              onDateTimeChanged: (DateTime newDateTime) {
                                selectedStart = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Bitiş', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              initialDateTime: DateTime(2023, 1, 1, 18, 0),
                              onDateTimeChanged: (DateTime newDateTime) {
                                selectedEnd = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final startStr = '${selectedStart.hour.toString().padLeft(2, '0')}:${selectedStart.minute.toString().padLeft(2, '0')}';
                      final endStr = '${selectedEnd.hour.toString().padLeft(2, '0')}:${selectedEnd.minute.toString().padLeft(2, '0')}';
                      setState(() {
                        _hoursController.text = "$startStr - $endStr";
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Saatleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16191E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF282F3A) : Colors.grey.shade300;
    final textColor = isDark ? const Color(0xFFF1F5F9) : Colors.black87;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İlan Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('İlan Türü Seçin'),
              const SizedBox(height: 8),
              FormField<String>(
                validator: (_) => _titleController.text.isEmpty ? 'Lütfen bir ilan türü seçin' : null,
                builder: (fieldState) {
                  final hasError = fieldState.hasError;
                  final currentBorder = hasError ? AppColors.error : borderColor;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          await _showSingleSelectDropdown(
                            context, 
                            'İlan Türü', 
                            AppConstants.jobTypes, 
                            _titleController.text, 
                            (newSelected) {
                              setState(() => _titleController.text = newSelected ?? '');
                              fieldState.didChange(newSelected);
                            }
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: currentBorder, width: hasError ? 1.5 : 1.0),
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _titleController.text.isEmpty ? 'İlan Türü Seçin' : _titleController.text,
                                style: TextStyle(
                                  color: _titleController.text.isEmpty 
                                      ? (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600) 
                                      : textColor,
                                  fontSize: 16
                                )
                              ),
                              Icon(Icons.arrow_drop_down, color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                            ]
                          )
                        ),
                      ),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 14, top: 6),
                          child: Text(
                            fieldState.errorText ?? '',
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Konum Bilgileri'),
              const SizedBox(height: 8),
              FormField<String>(
                validator: (_) => _selectedDistrict == null ? 'Lütfen bir ilçe seçin' : null,
                builder: (fieldState) {
                  final hasError = fieldState.hasError;
                  final currentBorder = hasError ? AppColors.error : borderColor;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          await _showSingleSelectDropdown(
                            context, 
                            'İlçe', 
                            AppConstants.ankaraDistricts, 
                            _selectedDistrict, 
                            (newSelected) {
                              setState(() => _selectedDistrict = newSelected);
                              fieldState.didChange(newSelected);
                            }
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: currentBorder, width: hasError ? 1.5 : 1.0),
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDistrict == null ? 'İl: Ankara, İlçe Seçin' : 'Ankara, $_selectedDistrict', 
                                style: TextStyle(
                                  color: _selectedDistrict == null 
                                      ? (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600) 
                                      : primaryColor,
                                  fontSize: 16,
                                  fontWeight: _selectedDistrict == null ? FontWeight.normal : FontWeight.bold
                                )
                              ),
                              Icon(Icons.arrow_drop_down, color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                            ]
                          )
                        ),
                      ),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 14, top: 6),
                          child: Text(
                            fieldState.errorText ?? '',
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              _buildModernTextField(
                controller: _locationController,
                label: 'Açık Adres / Şube Adı (Örn: Mado Kızılay)',
                icon: Icons.location_on_outlined,
                validator: (val) => val!.isEmpty ? 'Lütfen konum belirtin' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _dateController,
                label: 'Çalışma Tarihi (En fazla 5 gün)',
                icon: Icons.date_range,
                readOnly: true,
                onTap: _pickDateRange,
                validator: (val) => val!.isEmpty ? 'Lütfen tarih aralığı seçin' : null,
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Detaylar'),
              _buildModernTextField(
                controller: _hoursController,
                label: 'Çalışma Saatleri (Örn: 09:00 - 18:00)',
                icon: Icons.access_time,
                readOnly: true,
                onTap: _pickTimeRange,
                validator: (val) => val!.isEmpty ? 'Saatleri belirtin' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _priceController,
                label: 'Günlük/Saatlik Ücret (TL)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [Validators.wageInputFormatter],
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen ücret kısmını girin';
                  if (!Validators.isValidWage(val)) return 'Geçerli bir ücret tutarı girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _descController,
                label: 'Açıklama & Aranan Nitelikler',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (val) => val!.isEmpty ? 'Lütfen açıklama girin' : null,
              ),
              const SizedBox(height: 40),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _publishJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                      child: const Text('İlanı Yayınla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFF1F5F9) : Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16191E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF282F3A) : Colors.transparent;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        inputFormatters: inputFormatters ?? [Validators.denyHtmlTagFormatter],
        onTap: onTap,
        style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
          prefixIcon: maxLines == 1 ? Icon(icon, color: primaryColor.withOpacity(0.8)) : Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Icon(icon, color: primaryColor.withOpacity(0.8)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
          filled: true,
          fillColor: cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _showSingleSelectDropdown(
    BuildContext context, 
    String title, 
    List<String> items, 
    String? selectedItem,
    Function(String?) onChanged
  ) async {
    String searchQuery = '';
    String? localSelected = selectedItem;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final filteredItems = items.where((item) => item.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: '$title Ara',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0)
                      ),
                      onChanged: (val) => setStateSB(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item),
                            value: item,
                            groupValue: localSelected,
                            onChanged: (val) {
                              setStateSB(() => localSelected = val);
                              onChanged(val);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ]
                )
              )
            );
          }
        );
      }
    );
  }
}
