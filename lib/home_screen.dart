import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'add_job_screen.dart';
import 'jobs_list_screen.dart';
import 'applications_screen.dart';
import 'edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _activeFilterIndex = 0; // Üst kısımdaki yatay menü için ('İlanlar', 'Geçmiş İşlerim' vs.)
  int _listUpdateKey = 0;

  final List<String> _jobTypes = [
    'Barista',
    'Bulaşıkçı',
    'Garson',
    'Kasiyer',
    'Komi',
    'Kurye',
    'Meydancı',
    'Temizlik Görevlisi',
    'Vale'
  ];
  Set<String> _selectedJobFilters = {};

  final List<String> _ankaraDistricts = [
    'Akyurt', 'Altındağ', 'Ayaş', 'Bala', 'Beypazarı', 'Çamlıdere', 'Çankaya', 
    'Çubuk', 'Elmadağ', 'Etimesgut', 'Evren', 'Gölbaşı', 'Güdül', 'Haymana', 
    'Kahramankazan', 'Kalecik', 'Keçiören', 'Kızılcahamam', 'Mamak', 'Nallıhan', 
    'Polatlı', 'Pursaklar', 'Sincan', 'Şereflikoçhisar', 'Yenimahalle'
  ];
  Set<String> _selectedLocationFilters = {};
  
  String _firstName = "Yükleniyor...";
  String _lastName = "";
  String _companyName = "";
  String _tcKimlikNo = "";

  // Dinamik profil verileri (Yeni, boş hesap görünümü)
  int _jobCount = 0;
  double _averageRating = 0.0;
  double _walletBalance = 0.0;
  String _lastPaymentText = "Henüz ödeme yok";
  String _lastJobTitle = "İşlem geçmişi bulunmuyor";
  String _lastJobSubtitle = "-";
  double _lastJobRating = 0.0;
  
  String _userPhone = "";

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadUserData(); // loadUserData zaten sessiz çalışıyor, arayüzü bozmuyor
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _loadUserData() async {
    final userData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _firstName = userData['first_name'] ?? "Bilinmeyen";
        _lastName = userData['last_name'] ?? "Kullanıcı";
        _companyName = userData['company_name'] ?? "";
        _tcKimlikNo = userData['tc_kimlik_no'] ?? "";
      });
    }

    // Backend'den Cüzdan, İlan Sayısı gibi verileri çek
    final String phone = userData['phone'] ?? "";
    if (phone.isNotEmpty) {
      if (mounted) setState(() => _userPhone = phone);
      final stats = await AuthService.getUserProfileStats(phone, widget.role);
      if (mounted) {
        setState(() {
          _jobCount = stats['job_count'] ?? 0;
          
          final wallet = stats['wallet_balance'];
          if (wallet is int) {
             _walletBalance = wallet.toDouble();
          } else if (wallet is double) {
             _walletBalance = wallet;
          } else if (wallet is String) {
             _walletBalance = double.tryParse(wallet) ?? 0.0;
          }
          
          final rating = stats['average_rating'];
          if (rating is int) {
             _averageRating = rating.toDouble();
          } else if (rating is double) {
             _averageRating = rating;
          }
          
          final recentJobs = stats['recent_jobs'];
          if (recentJobs != null && recentJobs is List && recentJobs.isNotEmpty) {
             final job = recentJobs[0];
             _lastJobTitle = job['title']?.toString() ?? '-';
             _lastJobSubtitle = job['subtitle']?.toString() ?? '-';
             final r = job['rating'];
             if (r is int) _lastJobRating = r.toDouble();
             else if (r is double) _lastJobRating = r;
          } else {
             _lastJobTitle = "İşlem geçmişi bulunmuyor";
             _lastJobSubtitle = "-";
             _lastJobRating = 0.0;
          }
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Her profil sekmesine geçişte veya ana sekmeye geçişte bakiyeyi vs. yenile
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    bool isEmployer = widget.role == 'Employer';

    final pages = [isEmployer ? 'İlanlarım' : 'İlanlar', 'Profil'];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (_selectedIndex == 0)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTopFilterButton(
                                isEmployer ? 'İlanlarım' : 'İlanlar',
                                _activeFilterIndex == 0,
                                onTap: () {
                                  setState(() => _activeFilterIndex = 0);
                                },
                              ),
                              const SizedBox(width: 24),
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 24),
                              _buildTopFilterButton(
                                isEmployer ? 'Geçmiş İlanlarım' : 'Geçmiş İşlerim',
                                _activeFilterIndex == 1,
                                onTap: () {
                                  setState(() => _activeFilterIndex = 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.grey.shade300,
                        indent: 32,
                        endIndent: 32,
                        thickness: 1,
                        height: 20,
                      ),
                    ],
                  ),
                Expanded(
                  child: _selectedIndex == 0
                  ? (_activeFilterIndex == 0 
                      ? JobsListScreen(key: ValueKey('jobs_$_listUpdateKey'), isEmployer: isEmployer, jobFilters: _selectedJobFilters, locationFilters: _selectedLocationFilters)
                      : isEmployer
                          ? JobsListScreen(key: ValueKey('jobs_hist_$_listUpdateKey'), isEmployer: true, isHistory: true, jobFilters: _selectedJobFilters, locationFilters: _selectedLocationFilters)
                          : ApplicationsScreen(key: ValueKey('apps_hist_$_listUpdateKey'), isEmployer: false, isHistory: true))
                  : (!isEmployer && _selectedIndex == 1)
                      ? ApplicationsScreen(key: ValueKey('apps_$_listUpdateKey'), isEmployer: false)
                  : SingleChildScrollView( // _selectedIndex == 1 (İşveren) veya _selectedIndex == 2 (Çalışan) -> Profil

                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_firstName $_lastName',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEmployer
                                          ? (_companyName.isNotEmpty ? _companyName : 'İşveren Hesabı')
                                          : 'Çalışan Hesabı',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Çıkış Yap'),
                                      content: const Text(
                                        'Çıkış yapmak istediğinize emin misiniz?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('İptal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen(),
                                              ),
                                              (Route<dynamic> route) => false,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade50,
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Evet'),
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        isEmployer
                                            ? 'Açılan İlanlar'
                                            : 'Tamamlanan İşlerim',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.work,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$_jobCount',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Ortalama Puan',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _averageRating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cüzdanım',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Mevcut Bakiye:',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_walletBalance TL',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Son Alınan Ödeme:',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _lastPaymentText,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0A49A6,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Banka Hesabım Bağla',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEmployer ? 'Son İlanlarım' : 'Son İşlerim',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _lastJobTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Colors.grey,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _lastJobSubtitle,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _lastJobRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final newPhone = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      userPhone: _userPhone,
                                      role: widget.role,
                                    ),
                                  ),
                                );
                                if (newPhone != null) {
                                  _loadUserData(); // Return received, fetch updated details
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text(
                                'Profilimi Düzenle',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0A49A6),
                                side: const BorderSide(
                                  color: Color(0xFF0A49A6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                ),
              ],
            ),
            if (_selectedIndex == 0)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A49A6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A49A6).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(12),
                    iconSize: 28,
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isEmployer
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddJobScreen()),
                );
                _loadUserData();
                if (result == true) {
                  setState(() {
                    _listUpdateKey++;
                  });
                }
              },
              backgroundColor: const Color(0xFF0A49A6),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 36),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shape: const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            //CircularNotchedRectangle(),
          ),
          notchMargin: 10.0,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: _buildNavItem(
                    0,
                    Icons.list_rounded,
                    isEmployer ? 'İlanlarım' : 'İlanlar',
                  ),
                ),
                if (isEmployer) const SizedBox(width: 48), // FAB Ortası Boşluğu sadece İşveren için
                if (!isEmployer)
                  Expanded(
                    child: _buildNavItem(1, Icons.assignment_turned_in, 'Başvurularım'),
                  ),
                Expanded(
                  child: _buildNavItem(isEmployer ? 1 : 2, Icons.person_outline, 'Profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFilterButton(String title, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF0A49A6) : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.list_alt;
      case 1:
        return Icons.person_outline;
      default:
        return Icons.help;
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF0A49A6) : Colors.grey.shade600;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text('Filtrele', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A49A6))),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text('Meslekler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              await _showMultiSelectDropdown(
                                context, 
                                'Meslek', 
                                _jobTypes, 
                                _selectedJobFilters, 
                                (newSelected) {
                                  setStateSB(() => _selectedJobFilters = newSelected);
                                  setState(() => _listUpdateKey++);
                                }
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedJobFilters.isEmpty 
                                        ? 'Meslek Seçin' 
                                        : '${_selectedJobFilters.length} Meslek Seçildi',
                                    style: TextStyle(
                                      color: _selectedJobFilters.isEmpty ? Colors.black54 : Colors.black87,
                                      fontWeight: _selectedJobFilters.isEmpty ? FontWeight.normal : FontWeight.bold
                                    )
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                ]
                              )
                            )
                          ),
                          const SizedBox(height: 32),
                          const Text('Ankara İlçeleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              await _showMultiSelectDropdown(
                                context, 
                                'İlçe', 
                                _ankaraDistricts, 
                                _selectedLocationFilters, 
                                (newSelected) {
                                  setStateSB(() => _selectedLocationFilters = newSelected);
                                  setState(() => _listUpdateKey++);
                                }
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedLocationFilters.isEmpty 
                                        ? 'İlçe Seçin' 
                                        : '${_selectedLocationFilters.length} İlçe Seçildi',
                                    style: TextStyle(
                                      color: _selectedLocationFilters.isEmpty ? Colors.black54 : Colors.black87,
                                      fontWeight: _selectedLocationFilters.isEmpty ? FontWeight.normal : FontWeight.bold
                                    )
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                ]
                              )
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A49A6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Sonuçları Göster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _showMultiSelectDropdown(
    BuildContext context, 
    String title, 
    List<String> items, 
    Set<String> selectedItems,
    Function(Set<String>) onChanged
  ) async {
    String searchQuery = '';
    Set<String> localSelected = Set.from(selectedItems);
    
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
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item),
                            value: localSelected.contains(item),
                            onChanged: (val) {
                              setStateSB(() {
                                if (val == true) localSelected.add(item);
                                else localSelected.remove(item);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A49A6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          onChanged(localSelected);
                          Navigator.pop(context);
                        },
                        child: const Text('Seçimleri Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    )
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

