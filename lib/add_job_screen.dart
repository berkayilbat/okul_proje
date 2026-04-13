import 'package:flutter/material.dart';
import 'job_service.dart';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController(); // Tarih okuma için eklendi
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;

  void _publishJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final result = await JobService.addJob(
        title: _titleController.text,
        location: _locationController.text,
        workingHours: _hoursController.text,
        wage: _priceController.text,
        description: _descController.text,
        dates: _dateController.text,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlanınız başarıyla yayınlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true döndürerek listenin güncellenmesini tetikleyebiliriz
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('İlanınız ilk günden itibaren en fazla 5 günlük olabilir! Lütfen tekrar seçin.'), 
             backgroundColor: Colors.red
           ),
        );
      } else {
        setState(() {
          _dateController.text = "${picked.start.day}/${picked.start.month}/${picked.start.year} - ${picked.end.day}/${picked.end.month}/${picked.end.year}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Yeni İlan Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A148C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Temel Bilgiler'),
              _buildModernTextField(
                controller: _titleController,
                label: 'İlan Başlığı (Örn: Garson, Komi vb.)',
                icon: Icons.work_outline,
                validator: (val) => val!.isEmpty ? 'Lütfen başlık girin' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _locationController,
                label: 'Çalışma Yeri / Şube (Örn: Mado Kızılay)',
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
                validator: (val) => val!.isEmpty ? 'Saatleri belirtin' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _priceController,
                label: 'Günlük/Saatlik Ücret (TL)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Lütfen ücret kısmını girin' : null,
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
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF4A148C).withOpacity(0.5),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
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
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFF4A148C).withOpacity(0.6)) : Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Icon(icon, color: const Color(0xFF4A148C).withOpacity(0.6)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
