// lib/screens/main_screen.dart

import 'package:flutter/material.dart';

import '../../03_feeds/screens/global_news_feed_screen.dart';
import '../../03_feeds/screens/personalized_feed_screen.dart';
import '../../03_feeds/screens/youtube_feed_screen.dart';
import '../../04_settings/screens/settings_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;


  static const List<Widget> _widgetOptions = <Widget>[
    GlobalNewsScreen(),
    personalizedFeedScreen(),
    YoutubeFeedScreen(),
    SettingsScreen(),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Global Haber Akışı';
      case 1: return 'Sana Özel Akış';
      case 2: return 'YouTube Akışı'; // YENİ BAŞLIK
      case 3: return 'Ayarlar'; // AYARLARIN İNDEKSİ DEĞİŞTİ
      default: return 'AI Haber Akışı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()), // Başlık dinamik olarak değişecek
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Global',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_rounded),
            label: 'Sana Özel',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'YouTube'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}