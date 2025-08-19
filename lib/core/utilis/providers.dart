// lib/core/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark; // Varsayılan tema

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Cihaz hafızasından kayıtlı temayı yükle
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(THEME_KEY) ?? true; // Varsayılan olarak koyu tema
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Temayı değiştir ve cihaza kaydet
  void toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, isDarkMode);
    notifyListeners(); // Değişikliği dinleyen widget'ları uyar
  }
}