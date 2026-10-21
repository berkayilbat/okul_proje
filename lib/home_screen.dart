import 'utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'add_job_screen.dart';
import 'jobs_list_screen.dart';
import 'applications_screen.dart';
import 'edit_profile_screen.dart';
import 'widgets/animated_theme_toggle.dart';
import 'widgets/app_refresh_indicator.dart';
import 'widgets/app_avatar.dart';
import 'widgets/avatar_picker_sheet.dart';
import 'widgets/app_toast.dart';
import 'theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  int _listUpdateKey = 0;

  Set<String> _selectedJobFilters = {};
  Set<String> _selectedLocationFilters = {};
  
  String _firstName = "Yükleniyor...";
  String _lastName = "";
  String _companyName = "";

  // Dinamik profil verileri (Yeni, boş hesap görünümü)
  int _jobCount = 0;
  double _averageRating = 0.0;
  double _walletBalance = 0.0;
  String _lastPaymentText = "Henüz ödeme yok";
  String _lastJobTitle = "İşlem geçmişi bulunmuyor";
  String _lastJobSubtitle = "-";
  double _lastJobRating = 0.0;
  
  String _userPhone = "";
  String? _profileImage;
  bool _isAvatarUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final userData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _firstName = userData['first_name'] ?? "Bilinmeyen";
        _lastName = userData['last_name'] ?? "Kullanıcı";
        _companyName = userData['company_name'] ?? "";
        _profileImage = userData['profile_image'];
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
          if (stats['profile_image'] != null && stats['profile_image'].toString().isNotEmpty) {
            _profileImage = stats['profile_image'].toString();
          }
          
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
          if (stats['last_payment'] != null) {
             _lastPaymentText = stats['last_payment'].toString();
          }
        });
      }
    }
  }

  Future<void> _handleAvatarChange() async {
    final result = await AvatarPickerSheet.show(
      context,
      hasExistingImage: _profileImage != null && _profileImage!.isNotEmpty,
    );
    if (!mounted || result == null) return;

    if (result.action == AvatarPickerAction.delete) {
      setState(() => _isAvatarUploading = true);
      final res = await AuthService.deleteAvatar(phone: _userPhone);
      if (!mounted) return;
      setState(() {
        _isAvatarUploading = false;
        if (res['status'] == 'success') {
          _profileImage = null;
        }
      });
      if (res['status'] == 'success') {
        AppToast.showSuccess(context, 'Profil fotoğrafı kaldırıldı.');
      } else {
        AppToast.showError(context, res['message'] ?? 'Fotoğraf kaldırılamadı.');
      }
    } else if (result.filePath != null) {
      setState(() => _isAvatarUploading = true);
      final res = await AuthService.uploadAvatar(
        phone: _userPhone,
        filePath: result.filePath!,
      );
      if (!mounted) return;
      setState(() {
        _isAvatarUploading = false;
        if (res['status'] == 'success') {
          _profileImage = res['profile_image']?.toString();
        }
      });
      if (res['status'] == 'success') {
        AppToast.showSuccess(context, 'Profil fotoğrafınız güncellendi.');
      } else {
        AppToast.showError(context, res['message'] ?? 'Yükleme başarısız oldu.');
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
    // Her profil sekmesine geçişte veya ana sekmeye geçişte bakiyeyi vs. yenile
    _loadUserData();
  }

  Widget _buildTopHeader(bool isEmployer, bool isDark) {
    String title;
    bool showFilter = false;

    if (isEmployer) {
      if (_selectedIndex == 0) {
        title = 'İlanlarım';
        showFilter = true;
      } else {
        title = 'Geçmiş İlanlarım';
      }
    } else {
      if (_selectedIndex == 0) {
        title = 'İlanlar';
        showFilter = true;
      } else if (_selectedIndex == 1) {
        title = 'Başvurularım';
      } else {
        title = 'Geçmiş İşlerim';
      }
    }

    final hasActiveFilters = _selectedJobFilters.isNotEmpty || _selectedLocationFilters.isNotEmpty;
    final filterCount = _selectedJobFilters.length + _selectedLocationFilters.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              final isForward = _selectedIndex >= _previousIndex;
              final slideTween = Tween<Offset>(
                begin: Offset(isForward ? 0.25 : -0.25, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(slideTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              title,
              key: ValueKey<String>(title),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          if (showFilter)
            InkWell(
              onTap: _showFilterBottomSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInput : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasActiveFilters
                        ? (isDark ? AppColors.darkPrimary : const Color(0xFF111827))
                        : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 18,
                      color: hasActiveFilters
                          ? (isDark ? AppColors.darkPrimary : const Color(0xFF111827))
                          : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filtrele',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasActiveFilters
                            ? (isDark ? AppColors.darkPrimary : const Color(0xFF111827))
                            : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
                      ),
                    ),
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimary : const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$filterCount',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(bool isEmployer) {
    void handleClearFilters() {
      setState(() {
        _selectedJobFilters.clear();
        _selectedLocationFilters.clear();
      });
    }

    if (isEmployer) {
      if (_selectedIndex == 0) {
        return JobsListScreen(
          key: ValueKey('jobs_$_listUpdateKey'),
          isEmployer: true,
          isHistory: false,
          jobFilters: _selectedJobFilters,
          locationFilters: _selectedLocationFilters,
          onClearFilters: handleClearFilters,
        );
      } else if (_selectedIndex == 1) {
        return JobsListScreen(
          key: ValueKey('jobs_hist_$_listUpdateKey'),
          isEmployer: true,
          isHistory: true,
          jobFilters: _selectedJobFilters,
          locationFilters: _selectedLocationFilters,
          onClearFilters: handleClearFilters,
        );
      } else {
        return _buildProfileTab(isEmployer);
      }
    } else {
      if (_selectedIndex == 0) {
        return JobsListScreen(
          key: ValueKey('jobs_$_listUpdateKey'),
          isEmployer: false,
          isHistory: false,
          jobFilters: _selectedJobFilters,
          locationFilters: _selectedLocationFilters,
          onClearFilters: handleClearFilters,
        );
      } else if (_selectedIndex == 1) {
        return ApplicationsScreen(
          key: ValueKey('apps_$_listUpdateKey'),
          isEmployer: false,
          isHistory: false,
          onExploreJobs: () => _onItemTapped(0),
        );
      } else if (_selectedIndex == 2) {
        return ApplicationsScreen(
          key: ValueKey('apps_hist_$_listUpdateKey'),
          isEmployer: false,
          isHistory: true,
          onExploreJobs: () => _onItemTapped(0),
        );
      } else {
        return _buildProfileTab(isEmployer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmployer = widget.role == 'Employer';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isProfileTab = isEmployer ? _selectedIndex == 2 : _selectedIndex == 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!isProfileTab) _buildTopHeader(isEmployer, isDark),
            Expanded(
              child: DirectionalTabSwitcher(
                currentIndex: _selectedIndex,
                previousIndex: _previousIndex,
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: _buildCurrentTab(isEmployer),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isEmployer && _selectedIndex != 2
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  AppPageRoute.slideUp(const AddJobScreen()),
                );
                _loadUserData();
                if (result == true) {
                  setState(() {
                    _listUpdateKey++;
                  });
                }
              },
              backgroundColor: isDark ? AppColors.darkPrimary : const Color(0xFF111827),
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: isEmployer
                  ? [
                      Expanded(
                        child: _buildNavItem(
                          0,
                          Icons.format_list_bulleted_rounded,
                          'İlanlarım',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          1,
                          Icons.history_rounded,
                          'Geçmiş İlanlarım',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          2,
                          Icons.person_outline,
                          'Profil',
                          isDark,
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: _buildNavItem(
                          0,
                          Icons.work_outline,
                          'İlanlar',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          1,
                          Icons.assignment_turned_in_outlined,
                          'Başvurularım',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          2,
                          Icons.history_rounded,
                          'Geçmiş İşlerim',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          3,
                          Icons.person_outline,
                          'Profil',
                          isDark,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isEmployer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.grey.shade200;

    return AppRefreshIndicator(
      onRefresh: () async {
        _loadUserData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              AppAvatar(
                                radius: 44,
                                imageUrl: _profileImage,
                                name: '$_firstName $_lastName',
                                heroTag: 'user-profile-avatar',
                                showEditBadge: true,
                                isLoading: _isAvatarUploading,
                                onEditBadgeTap: _handleAvatarChange,
                                onTap: _handleAvatarChange,
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Profil Üst Çubuğu: Siyah-Beyaz Animasyonlu Tema ve Çıkış Butonları
                              const AnimatedThemeToggle(width: 60, height: 30),
                              const SizedBox(width: 10),
                              AnimatedLogoutButton(
                                size: 30,
                                onLogout: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                                        ),
                                      ),
                                      title: Text(
                                        'Çıkış Yap',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      content: Text(
                                        'Çıkış yapmak istediğinize emin misiniz?',
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextSecondary : Colors.black87,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            foregroundColor: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                          child: const Text('İptal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await AuthService.logout();
                                            if (!context.mounted) return;
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const LoginScreen(),
                                              ),
                                              (Route<dynamic> route) => false,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? Colors.white : Colors.black,
                                            foregroundColor: isDark ? Colors.black : Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          ),
                                          child: const Text(
                                            'Çıkış Yap',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cardBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
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
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextSecondary : Colors.grey,
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
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cardBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Ortalama Puan',
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextSecondary : Colors.grey,
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
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
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
                                    Text(
                                      'Mevcut Bakiye:',
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_walletBalance TL',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.darkPrimary : null,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Son Alınan Ödeme:',
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextSecondary : Colors.grey,
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
                                        backgroundColor: isDark ? AppColors.darkPrimary : const Color(0xFF111827),
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
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextSecondary : Colors.grey,
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
                                            Icon(
                                              Icons.access_time,
                                              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _lastJobSubtitle,
                                              style: TextStyle(
                                                color: isDark ? AppColors.darkTextSecondary : Colors.grey,
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
                                  AppPageRoute.fadeThrough(
                                    EditProfileScreen(
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
                                foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                side: BorderSide(
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
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
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    final color = isSelected 
        ? (isDark ? AppColors.darkPrimary : const Color(0xFF111827)) 
        : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade500);

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : Colors.black54;
    final tileBg = isDark ? AppColors.darkInput : Colors.grey.shade50;
    final tileBorder = isDark ? AppColors.darkBorder : Colors.grey.shade300;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final hasActiveFilters = _selectedJobFilters.isNotEmpty || _selectedLocationFilters.isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrele',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              setStateSB(() {
                                _selectedJobFilters.clear();
                                _selectedLocationFilters.clear();
                              });
                              setState(() {
                                _listUpdateKey++;
                              });
                            },
                            child: Text(
                              'Temizle',
                              style: TextStyle(
                                color: isDark ? AppColors.darkPrimary : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meslekler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              await _showMultiSelectDropdown(
                                context,
                                'Meslek',
                                AppConstants.jobTypes,
                                _selectedJobFilters,
                                (newSelected) {
                                  setStateSB(() => _selectedJobFilters = newSelected);
                                  setState(() => _listUpdateKey++);
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: tileBg,
                                border: Border.all(color: tileBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedJobFilters.isEmpty
                                          ? 'Meslek Seçin'
                                          : '${_selectedJobFilters.length} Meslek Seçildi',
                                      style: TextStyle(
                                        color: _selectedJobFilters.isEmpty ? secondaryTextColor : textColor,
                                        fontWeight: _selectedJobFilters.isEmpty ? FontWeight.normal : FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: secondaryTextColor),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Ankara İlçeleri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              await _showMultiSelectDropdown(
                                context,
                                'İlçe',
                                AppConstants.ankaraDistricts,
                                _selectedLocationFilters,
                                (newSelected) {
                                  setStateSB(() => _selectedLocationFilters = newSelected);
                                  setState(() => _listUpdateKey++);
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: tileBg,
                                border: Border.all(color: tileBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedLocationFilters.isEmpty
                                          ? 'İlçe Seçin'
                                          : '${_selectedLocationFilters.length} İlçe Seçildi',
                                      style: TextStyle(
                                        color: _selectedLocationFilters.isEmpty ? secondaryTextColor : textColor,
                                        fontWeight: _selectedLocationFilters.isEmpty ? FontWeight.normal : FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: secondaryTextColor),
                                ],
                              ),
                            ),
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
                          backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Sonuçları Göster',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade300;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final filteredItems = items.where((item) => item.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '$title Ara',
                        hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : const Color(0xFF111827)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                      onChanged: (val) => setStateSB(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = localSelected.contains(item);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: isDark ? AppColors.darkPrimary : const Color(0xFF111827),
                            checkColor: isDark ? Colors.black : Colors.white,
                            title: Text(
                              item,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            value: isSelected,
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
                          backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          onChanged(localSelected);
                          Navigator.pop(context);
                        },
                        child: const Text('Seçimleri Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

