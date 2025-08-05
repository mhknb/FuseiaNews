// lib/main.dart

import 'package:ai_content_flow_app/auth_check_screen.dart'; // Yeni kontrol ekranımızı import ediyoruz
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  await dotenv.load(fileName: ".env");

   runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Renk paletimizi tanımlayalım
    const Color primaryColor = Colors.indigo; // Koyu Mor (Indigo yerine)
    const Color secondaryColor = Colors.indigoAccent; // Altın Sarısı
    const Color darkBackgroundColor = Color(0xFF121212); // Koyu Arka Plan

    return MaterialApp(
      title: 'HAG Content Flow',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
         brightness: Brightness.dark,
        useMaterial3: true,

         colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,

          primary: primaryColor,
          secondary: secondaryColor,
          background: darkBackgroundColor,
          surface: Color(0xFF121212), // Kartların rengi için hafif açık bir ton
        ),


        // AppBar Teması
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackgroundColor, // AppBar arka planı
          foregroundColor: Colors.white, // AppBar yazı ve ikon rengi
          elevation: 0, // AppBar altındaki gölgeyi kaldır
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'YourCustomFont', // Eğer özel bir fontun varsa
          ),
        ),

        // Buton Temaları
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Buton arka planı
            foregroundColor: Colors.white, // Buton yazı rengi
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        // Alt Navigasyon Barı Teması
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: secondaryColor, // Seçili ikonun rengi Altın Sarısı olsun
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
        ),

        // Çip (Chip) Teması
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[800],
          selectedColor: primaryColor,
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white), // Seçili çip yazı rengi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.white30),
          ),
        ),

        // Kart Teması
        cardTheme: CardThemeData(
          color: Colors.grey[850],
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        // Yazı Stili Teması
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      home: const AuthCheckScreen(),
    );
  }
}