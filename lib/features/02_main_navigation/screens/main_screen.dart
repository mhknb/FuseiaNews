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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  static const List<Widget> _widgetOptions = <Widget>[
    GlobalNewsScreen(),
    PersonalizedFeedScreen(),
    YoutubeFeedScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    );
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.reset();
      _pageController.forward();
    }
  }


  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Global Haber Akışı';
      case 1: return 'Sana Özel Akış';
      case 2: return 'YouTube Akışı';
      case 3: return 'Ayarlar';
      default: return 'AI Haber Akışı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation.drive(Tween<double>(begin: 0.0, end: 1.0)),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          child: Text(
            _getAppBarTitle(),
            key: ValueKey(_selectedIndex),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _pageAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _pageAnimation.drive(Tween<double>(begin: 0.0, end: 1.0)),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _pageAnimation,
                curve: Curves.easeOut,
              )),
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          );
        },
      ),
      floatingActionButton: AnimatedScale(
        scale: _selectedIndex == 0 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: () {
            // Add refresh functionality
            setState(() {
              _pageController.reset();
              _pageController.forward();
            });
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
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
      ),
    );
  }
}