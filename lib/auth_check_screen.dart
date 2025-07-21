// lib/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kendi dosya yollarına göre bu import'ları güncelle
import 'features/01_setup/screens/onboarding_screen.dart';
import 'features/02_main_navigation/screens/main_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetupStatusAndNavigate();
  }

  Future<void> _checkSetupStatusAndNavigate() async {
    // Arayüzün oturması için küçük bir gecikme eklemek,
    // "yanıp sönme" (flash) efektini engeller.
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('user_api_key');
    final bool isSetupComplete = apiKey != null && apiKey.isNotEmpty;

    // `mounted` kontrolü, yönlendirme yapılmadan önce widget'ın
    // hala ekranda olduğundan emin olmak için iyi bir pratiktir.
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isSetupComplete
              ? const MainScreen()
              : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kontroller yapılırken ekranda bir logo veya yüklenme animasyonu göster
    return const Scaffold(
      body: Center(
        // Buraya kendi uygulama logonun widget'ını koyabilirsin
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.hub_rounded, size: 80),
            // SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}