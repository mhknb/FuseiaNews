// lib/features/01_setup/screens/source_selection_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../02_main_navigation/screens/main_screen.dart';

class SourceSelectionScreen extends StatefulWidget {
  const SourceSelectionScreen({super.key});

  @override
  State<SourceSelectionScreen> createState() => _SourceSelectionScreenState();
}

class _SourceSelectionScreenState extends State<SourceSelectionScreen> {
  final Map<String, String> _allSources = {
    'BBC Teknoloji': 'http://feeds.bbci.co.uk/news/technology/rss.xml',
    'The Verge': 'https://www.theverge.com/rss/index.xml',
    'TechCrunch': 'https://techcrunch.com/feed/',
    'Wired': 'https://www.wired.com/feed/rss',
    'Sky News Spor': 'https://feeds.skynews.com/feeds/rss/sports.xml',
    'Wall Street Journal': 'https://feeds.a.dj.com/rss/RSSMarketsMain.xml',
    'MIT Technology Review': 'https://www.technologyreview.com/feed/',
  };

  final Set<String> _selectedSources = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedSources();
  }




  Future<void> _loadSelectedSources() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedSourcesJson = prefs.getString('user_selected_sources_map');

    if (savedSourcesJson != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(savedSourcesJson);
      setState(() {
        _selectedSources.addAll(decodedMap.values.cast<String>());
      });
    }
    setState(() => _isLoading = false);
  }






  Future<void> _saveAndNavigate() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      Map<String, String> sourcesToSave = {};
      _selectedSources.forEach((url) {
        final sourceName = _allSources.entries.firstWhere((entry) => entry.value == url).key;
        sourcesToSave[sourceName] = url;
      });

      String jsonString = jsonEncode(sourcesToSave);

      await prefs.setString('user_selected_sources_map', jsonString);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bir mesaj gösterebilirsiniz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme işlemi başarısız: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haber Kaynaklarınızı Seçin'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hangi kaynakları takip etmek istersiniz?', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Seçimleriniz "Sana Özel" akışınızı oluşturacaktır.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _allSources.entries.map((entry) {
                        final sourceName = entry.key;
                        final sourceUrl = entry.value;
                        final isSelected = _selectedSources.contains(sourceUrl);

                        return FilterChip(
                          label: Text(sourceName),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedSources.add(sourceUrl);
                              } else {
                                _selectedSources.remove(sourceUrl);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAndNavigate,
                child: _isSaving
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Kurulumu Tamamla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}