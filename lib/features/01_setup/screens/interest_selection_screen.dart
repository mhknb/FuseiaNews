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
    'Bilim', 'Teknoloji', 'Gündem', 'Spor', 
    'Eğlence', 'Yaşam', 'Finans', 'Yapay Zeka', 
    'Eğitim', 'Oyun', 'Sağlık',
  ];


  final Set<String> _selectedInterests = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedInterests();
  }

  /// Cihaz hafızasından daha önce kaydedilmiş ilgi alanlarını yükler.
  Future<void> _loadSelectedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final savedInterests = prefs.getStringList('user_interests');
    if (savedInterests != null) {

      _selectedInterests.clear();
      _selectedInterests.addAll(savedInterests);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Kullanıcının seçtiği ilgi alanlarını kaydeder ve ana ekrana yönlendirir.
  Future<void> _saveAndNavigate() async {
   if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_interests', _selectedInterests.toList());


      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false, // Tüm geçmiş ekranları temizle
        );
      }
    } catch (e) {
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanlarınızı Seçin'),
        automaticallyImplyLeading: false, // Geri tuşunu gizle
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), // Alt boşluğu artırdım
        child: Column(
          children: [
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
                    Text(
                      'Seçimleriniz, "Sana Özel" akışınızı oluşturmak için kullanılacaktır. Daha sonra ayarlardan değiştirebilirsiniz.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12.0, // Çipler arası boşluk
                      runSpacing: 12.0,
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaving ? null : _saveAndNavigate,
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
                    : const Text('Kaydet ve Başla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}