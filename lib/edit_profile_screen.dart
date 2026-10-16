import 'package:flutter/material.dart';
import 'auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userPhone;
  final String role;

  const EditProfileScreen({super.key, required this.userPhone, required this.role});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _taxNoController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _availableProfessions = [
    'Garson', 'Kasiyer', 'Barista', 'Barmen', 'Aşçı', 'Komi', 
    'Bulaşıkçı', 'Kurye', 'Temizlik Görevlisi', 'Güvenlik', 
    'Vale', 'Animatör', 'Satış Danışmanı', 'Resepsiyonist'
  ];

  Set<String> _selectedProfessions = {};

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    final details = await AuthService.getProfileDetails(widget.userPhone);
    if (!mounted) return;

    if (details.isNotEmpty) {
      _phoneController.text = details['phone']?.toString() ?? '';
      _addressController.text = details['address']?.toString() ?? '';
      _firstNameController.text = details['first_name']?.toString() ?? '';
      _lastNameController.text = details['last_name']?.toString() ?? '';
      _taxNoController.text = details['tax_no']?.toString() ?? '';
      
      final profs = details['professions']?.toString() ?? '';
      if (profs.isNotEmpty) {
         final profList = profs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
         _selectedProfessions = profList.toSet();
         
         // Eğer standart listede olmayan bir meslek yazılmışsa onu da listeye ekleyelim ki seçili görünsün
         for (var prof in profList) {
           if (!_availableProfessions.contains(prof)) {
             _availableProfessions.add(prof);
           }
         }
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final newPhone = _phoneController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (newPhone.isEmpty || firstName.isEmpty || lastName.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İsim, soyisim veya telefon boş bırakılamaz.')));
       return;
    }

    if (widget.role == 'Employee' && _selectedProfessions.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir meslek seçin.')));
       return;
    }

    setState(() => _isSaving = true);

    final professionsStr = _selectedProfessions.join(', ');
    
    final result = await AuthService.updateProfile(
      oldPhone: widget.userPhone,
      phone: newPhone,
      firstName: firstName,
      lastName: lastName,
      taxNo: widget.role == 'Employer' ? _taxNoController.text.trim() : null,
      address: widget.role == 'Employee' ? _addressController.text.trim() : null,
      professions: widget.role == 'Employee' ? professionsStr : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green),
      );
      // Geriye yeni telefon numarası ile dön (böylece önceki ekran da yenilenebilir)
      Navigator.pop(context, newPhone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Güncelleme hatası.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmployee = widget.role == 'Employee';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilimi Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A49A6),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A49A6)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kişisel Bilgiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A49A6))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Soyad',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('İletişim Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A49A6))),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon Numarası',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (widget.role == 'Employer') ...[
                  const Text('Kurumsal Bilgiler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A49A6))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taxNoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Vergi Kimlik No / TC Kimlik No',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                if (isEmployee) ...[
                  const Text('İkametgah Adresi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A49A6))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
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

                  const Text('Çalışabileceğiniz Meslekler (İstediğiniz kadar seçin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A49A6))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableProfessions.map((prof) {
                       final isSelected = _selectedProfessions.contains(prof);
                       return FilterChip(
                         label: Text(prof),
                         selected: isSelected,
                         selectedColor: Colors.blue.shade100,
                         checkmarkColor: const Color(0xFF0A49A6),
                         labelStyle: TextStyle(
                           color: isSelected ? const Color(0xFF0A49A6) : Colors.grey.shade800,
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
                      backgroundColor: const Color(0xFF0A49A6),
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
          )
    );
  }
}
