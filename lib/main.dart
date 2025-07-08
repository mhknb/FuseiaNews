// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'features/01_setup/screens/api_key_screen.dart';
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
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      home: isSetupComplete ? const MainScreen() : const ApiKeyScreen(),
    );
  }
}