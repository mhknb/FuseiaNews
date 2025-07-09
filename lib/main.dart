// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/01_setup/screens/onboarding_screen.dart';
import 'features/02_main_navigation/screens/main_screen.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();


  final prefs = await SharedPreferences.getInstance();
  final String? apiKey = prefs.getString('user_api_key');

  bool isSetupComplete = apiKey != null && apiKey.isNotEmpty;

  runApp(MyApp(isSetupComplete: isSetupComplete));
}

class MyApp extends StatelessWidget {

  final bool isSetupComplete;

  const MyApp({
    super.key,
    required this.isSetupComplete,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI ContentFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        brightness: Brightness.dark,

        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(

          seedColor: Colors.indigo,

          brightness: Brightness.dark,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(

          selectedItemColor: Colors.blueAccent,

          unselectedItemColor: Colors.white70, // Hafif şeffaf beyaz

          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),

        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
//      home: isSetupComplete ? const MainScreen() : const ApiKeyScreen(),
    //burası duzenlenecek
        home: isSetupComplete ? const MainScreen() : const OnboardingScreen(),
    );
  }
}