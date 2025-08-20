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
    const Color primaryColor = Colors.indigo;
    const Color secondaryColor = Colors.indigoAccent;
    const Color darkBackgroundColor = Color(0xFF121212);
    const Color lightPrimaryColor = Color(0xFF4A9782);
    const Color lightBackgroundColor = Color(0xFFDCD0A8);
    const Color lightCardColor = Color(0xFFDCD0A8);
    const Color lightTextColor = Color(0xFF333333);


    return MaterialApp(
      title: 'HAG Content Flow',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightPrimaryColor,
          brightness: Brightness.light,
          background: lightBackgroundColor,
          primary: lightPrimaryColor,
          onPrimary: Colors.black,
          surface: lightCardColor,
          onSurface: lightTextColor,
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
          selectedItemColor: lightPrimaryColor,
          unselectedItemColor: Colors.grey,
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
          surface: Color(0xFF121212),
        ),





        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'YourCustomFont', // Eğer özel bir fontun varsa
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: secondaryColor,
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
// Temalar arası geçişi sağlayan ThemeProvider kullanımı
      home: const AuthCheckScreen(),
    );
  }
}