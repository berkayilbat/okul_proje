import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'qr_scan_screen.dart';
import 'qr_generate_screen.dart';
class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEmployer = widget.role == 'Employer';

    final pages = [
      isEmployer ? 'İlanlarım' : 'İlanlar',
      'Profil',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(pages[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndex(_selectedIndex),
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text('${pages[_selectedIndex]} Sayfası',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              isEmployer ? 'İşveren Paneline Hoşgeldiniz' : 'Çalışan Paneline Hoşgeldiniz',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SpeedDial(
        icon: Icons.qr_code_scanner,
        activeIcon: Icons.close,
        buttonSize: const Size(68, 68),
        iconTheme: const IconThemeData(size: 32),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        spacing: 3,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        tooltip: 'QR Menü',
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'QR Okut',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScanScreen()));
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_2),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'QR Açma',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QRGenerateScreen()));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(0, Icons.list_alt, isEmployer ? 'İlanlarım' : 'İlanlar'),
            const SizedBox(width: 48), // FAB Ortası Boşluğu
            _buildNavItem(1, Icons.person_outline, 'Profil'),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.list_alt;
      case 1: return Icons.person_outline;
      default: return Icons.help;
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF4A148C) : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
