// lib/main.dart

import 'package:ai_content_flow_app/auth_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Modern clean design - ekteki görsellere göre
    const Color primaryColor = Color(0xFF4A90E2); // Modern blue
    const Color secondaryColor = Color(0xFF7B68EE); // Soft purple
    const Color darkBackgroundColor = Color(0xFF121212);
    const Color lightPrimaryColor = Color(0xFF4A90E2); // Modern blue
    const Color lightBackgroundColor = Color(0xFFF8F9FA); // Very light gray background
    const Color lightCardColor = Color(0xFFFFFFFF); // Pure white cards
    const Color lightTextColor = Color(0xFF1A1A1A); // Near black for titles
    const Color lightBodyTextColor = Color(0xFF6B7280); // Medium gray for content
    const Color chipBackgroundColor = Color(0xFFF3F4F6); // Light gray for chips
    const Color chipTextColor = Color(0xFF374151); // Dark gray for chip text

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'HAG Content Flow',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode, // Provider'dan dinamik tema

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
        appBarTheme: AppBarTheme(
          backgroundColor: lightBackgroundColor,
          foregroundColor: lightTextColor, // AppBar yazı ve ikon rengi
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: lightTextColor,
            ),
          ),
        ),


        cardTheme: CardThemeData(
          color: lightCardColor,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          backgroundColor: lightCardColor,
          selectedItemColor: lightPrimaryColor,
          unselectedItemColor: lightBodyTextColor,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),

        textTheme: TextTheme(
          titleLarge: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: lightTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          titleMedium: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: lightTextColor,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          bodyLarge: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: lightTextColor,
              fontSize: 16,
            ),
          ),
          bodyMedium: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: lightBodyTextColor,
              fontSize: 14,
            ),
          ),
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
        scaffoldBackgroundColor: darkBackgroundColor,
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          secondary: secondaryColor,
          background: darkBackgroundColor,
          surface: const Color(0xFF1E1E1E), // Kart arka plan rengi
          onSurface: Colors.white, // Kart üzerindeki metin rengi
          onBackground: Colors.white, // Arka plan üzerindeki metin rengi
        ),





        appBarTheme: AppBarTheme(
          backgroundColor: darkBackgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
          color: const Color(0xFF1E1E1E), // Koyu gri kart arka planı
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        // Yazı Stili Teması
        textTheme: TextTheme(
          titleLarge: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          titleMedium: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          bodyLarge: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          bodyMedium: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ),
          // Temalar arası geçişi sağlayan ThemeProvider kullanımı
          home: const AuthCheckScreen(),
        );
      },
    );
  }
}