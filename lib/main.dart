// lib/main.dart

import 'package:ai_content_flow_app/auth_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/utilis/providers.dart';


Future<void> main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Renk paletimizi tanımlayalım
    const Color primaryColor = Colors.indigo; // Koyu Mor (Indigo yerine)
    const Color secondaryColor = Colors.indigoAccent; // Altın Sarısı
    const Color darkBackgroundColor = Color(0xFF121212); // Koyu Arka Plan
    const Color lightPrimaryColor = Color(0xFF528b8b); // Turquoise
    const Color lightBackgroundColor = Color(0xFFFFE4C4); // Bisque
    const Color lightCardColor = Color(0xFFFFE4C4); // Kartlar saf beyaz
    const Color lightTextColor = Color(0xFF333333); // Okunaklılık için koyu gri metin


    return MaterialApp(
      title: 'HAG Content Flow',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackgroundColor, // Ana arka plan rengi

        // Renk şemasını yeni renklerle oluştur
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightPrimaryColor,
          brightness: Brightness.light,
          background: lightBackgroundColor,
          primary: lightPrimaryColor,
          onPrimary: Colors.black, // Ana renk üzerindeki metin (siyah daha okunaklı)
          surface: lightCardColor, // Kartların ve diyalogların rengi
          onSurface: lightTextColor, // Kartların üzerindeki ana metin rengi
        ),

        // Arayüz bileşenlerini açık temaya göre özelleştir
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBackgroundColor,
          foregroundColor: lightTextColor, // AppBar yazı ve ikon rengi
          elevation: 0.5,
        ),


        cardTheme: CardThemeData(
          color: lightCardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimaryColor, // Buton arka plan rengi
            foregroundColor: Colors.white, // Buton yazı rengi
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: lightPrimaryColor, // Seçili sekme turkuaz
          unselectedItemColor: Colors.grey, // Seçili olmayan soluk gri
        ),

        textTheme: const TextTheme(
          titleLarge: TextStyle(color: lightTextColor),
          bodyMedium: TextStyle(color: Colors.black54),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: lightPrimaryColor, width: 2.0),
          ),
        ),
      ),



      darkTheme: ThemeData(
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