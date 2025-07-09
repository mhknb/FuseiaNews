import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../02_main_navigation/screens/main_screen.dart';




class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<String> _allInterests = [
    'Teknoloji', 'Bilim', 'Yapay Zeka', 'Spor', 'Sağlık',
    'Finans', 'Oyun', 'Sinema', 'Gündem', 'Eğitim',
  ];

  final Set<String> _selectedInterests = {};
  bool _isLoading = true;
  bool _isSaving = false; // Kaydetme işlemi için yeni bir durum değişkeni

  @override
  void initState() {
    super.initState();
    _loadSelectedInterests();
  }

  Future<void> _loadSelectedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final savedInterests = prefs.getStringList('user_interests');
    if (savedInterests != null) {
      _selectedInterests.addAll(savedInterests);
    }
    setState(() {
      _isLoading = false;
    });
  }

  // SADECE BU FONKSİYON GÜNCELLENDİ
  Future<void> _saveAndNavigate() async {
    // Kaydetme butonuna tekrar tekrar basılmasını engelle
    if (_isSaving) return;

    setState(() {
      _isSaving = true; // Kaydetme animasyonunu başlat
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_interests', _selectedInterests.toList());


      if (mounted) {
        // Artık HomePage'e değil, MainScreen'e yönlendiriyoruz.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Hata olursa kullanıcıyı bilgilendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Kaydetme animasyonunu durdur
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'daki actions kısmını sildik
      appBar: AppBar(
        title: const Text('İlgi Alanlarınızı Seçin',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        )),


        automaticallyImplyLeading: false,
      ),
      // Alt tarafa sabit bir buton eklemek için Column ve Expanded kullanıyoruz
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sayfanın içeriği Expanded içine alınır ki kalan boşluğu doldursun
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hangi konulardaki haberleri görmek istersiniz?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seçimleriniz, haber akışınızı kişiselleştirmek için kullanılacaktır. Birden fazla seçim yapabilirsiniz.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _allInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Sayfanın en altına sabitlenecek buton
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaving ? null : _saveAndNavigate,
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Kaydet ve Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}