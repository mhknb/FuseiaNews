import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../01_setup/screens/interest_selection_screen.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final List<String> _youtubeChannels = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }





  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKeyController.text = prefs.getString('user_api_key') ?? '';
    final savedChannels = prefs.getStringList('youtube_channels') ?? [];
    setState(() {
      _youtubeChannels.addAll(savedChannels);
      _isLoading = false;
    });
  }






  Future<void> _saveAllSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_api_key', _apiKeyController.text);
      await prefs.setStringList('youtube_channels', _youtubeChannels);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayarlar kaydedilirken hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }





  void _addYoutubeChannel() {
    final url = _youtubeUrlController.text.trim();
    if (url.isNotEmpty && !_youtubeChannels.contains(url)) {
      setState(() {
        _youtubeChannels.add(url);
      });
      _youtubeUrlController.clear();
    }
  }




  void _removeYoutubeChannel(String url) {
    setState(() {
      _youtubeChannels.remove(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Anahtarı Kartı
            _buildSectionCard(
              title: 'API Ayarları',
              child: TextFormField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Anahtarı',
                  hintText: 'API anahtarınızı buraya yapıştırın',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: 'İçerik Tercihleri',
              child: ListTile(
                leading: const Icon(Icons.interests),
                title: const Text('İlgi Alanlarını Düzenle'),
                subtitle: const Text('Haber akışınızı kişiselleştirin'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InterestSelectionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: 'Takip Edilen YouTube Kanalları',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _youtubeUrlController,
                          decoration: const InputDecoration(
                            labelText: 'YouTube Kanal URL\'si',
                            hintText: 'Kanal linkini buraya yapıştırın',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: _addYoutubeChannel,
                        tooltip: 'Ekle',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Eklenen kanalların listesi
                  _youtubeChannels.isEmpty
                      ? const Text('Henüz kanal eklenmedi.', style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _youtubeChannels.length,
                    itemBuilder: (context, index) {
                      final channelUrl = _youtubeChannels[index];
                      return ListTile(
                        leading: const Icon(Icons.smart_display),
                        title: Text(channelUrl, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeYoutubeChannel(channelUrl),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tümünü Kaydet Butonu
            ElevatedButton.icon(
              icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save),
              label: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tüm Ayarları Kaydet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _isSaving ? null : _saveAllSettings,
            ),
          ],
        ),
      ),
    );
  }

  // Tekrarlanan Card yapısı için bir yardımcı widget metodu
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}