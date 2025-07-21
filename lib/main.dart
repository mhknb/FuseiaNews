// lib/main.dart

import 'package:ai_content_flow_app/auth_check_screen.dart'; // Yeni kontrol ekranımızı import ediyoruz
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Bu dosyada artık SharedPreferences veya diğer ekranları import etmemize gerek yok.
// Bu, main.dart'ı daha temiz ve odaklı hale getirir.

Future<void> main() async {
  // .env dosyasını uygulama başlarken yüklemek en iyisidir.
  // Bu işlem genellikle çok hızlıdır ve başlangıç performansını etkilemez.
  await dotenv.load(fileName: ".env");

  // runApp() artık basit ve senkron bir şekilde çağrılıyor.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // Seçili item rengini ana renk şemasından alalım ki tutarlı olsun
          // Ama istersen Colors.blueAccent olarak da bırakabilirsin.
          selectedItemColor: Colors.indigoAccent,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          // type: BottomNavigationBarType.fixed, // 4+ item olunca bu önemlidir
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // UYGULAMANIN BAŞLANGIÇ NOKTASI ARTIK HER ZAMAN AuthCheckScreen'DİR.
      // Bu ekran, kontrolleri yapıp kullanıcıyı doğru yere yönlendirecek.
      home: const AuthCheckScreen(),
    );
  }
}