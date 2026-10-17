import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'server_config.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerConfig.discoverServer();
  await ThemeController.init();
  final bool isLoggedIn = await AuthService.isLoggedIn();
  final String role = await AuthService.getRole();
  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String role;
  const MyApp({super.key, required this.isLoggedIn, required this.role});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Yömyeci',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr', 'TR')],
          home: isLoggedIn ? HomeScreen(role: role) : const LoginScreen(),
        );
      },
    );
  }
}

