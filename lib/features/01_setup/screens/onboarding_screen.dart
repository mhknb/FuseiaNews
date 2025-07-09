// lib/features/01_setup/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'api_key_screen.dart'; // Yönlendireceğimiz ekran

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını alalım ki tasarımımız orantılı olsun
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[900], // Arka plan rengi
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üstteki Başlık
              const Text(
                'Hoş Geldin!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Uygulamanın tüm özelliklerini kullanabilmek için bir Gemini API anahtarına ihtiyacın var.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const Spacer(), // Boşluk bırakarak ortalamak için

              // Ortadaki resimli kutu
              Container(
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8.0,
                      offset: const Offset(12, 8), // Gölgenin konumu
                    ),
                  ],

                ),
                child:
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/images/splah1.png',
                        height: screenSize.height * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),

              ),

              const Spacer(), // Boşluk bırakarak ortalamak için

              // Alttaki "Geç" butonu
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // ApiKeyScreen'e yönlendir.
                  // pushReplacement, kullanıcının bu ekrana geri dönmesini engeller.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ApiKeyScreen()),
                  );
                },
                child: const Text(
                  'Anladım, Devam Et',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}