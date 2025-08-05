// lib/features/04_settings/screens/settings_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../01_setup/screens/interest_selection_screen.dart';

// Kaynakları temsil etmek için basit bir class (Model)
class RssSource {
  String name;
  String url;
  RssSource({required this.name, required this.url});
  Map<String, dynamic> toJson() => {'name': name, 'url': url};
  factory RssSource.fromJson(Map<String, dynamic> json) => RssSource(name: json['name'], url: json['url']);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controller'lar
  final _apiKeyController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _rssNameController = TextEditingController();
  final _rssUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Durum Değişkenleri
  List<String> _youtubeChannels = [];
  List<RssSource> _rssSources = [];
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
    _rssNameController.dispose();
    _rssUrlController.dispose();
    super.dispose();
  }

  // --- VERİ İŞLEMLERİ ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKeyController.text = prefs.getString('user_api_key') ?? '';
    _youtubeChannels = prefs.getStringList('youtube_channels') ?? [];

    final String? rssJson = prefs.getString('user_custom_sources');
    if (rssJson != null) {
      final List<dynamic> decodedList = jsonDecode(rssJson);
      _rssSources = decodedList.map((item) => RssSource.fromJson(item)).toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveAllSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_api_key', _apiKeyController.text);
      await prefs.setStringList('youtube_channels', _youtubeChannels);

      final List<Map<String, dynamic>> encodedRssList = _rssSources.map((source) => source.toJson()).toList();
      await prefs.setString('user_custom_sources', jsonEncode(encodedRssList));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- ARAYÜZ İŞLEMLERİ ---

  void _showAddSourceDialog({required bool isYoutube}) {
    // Diyalog her açıldığında controller'ları temizle
    final urlController = isYoutube ? _youtubeUrlController : _rssUrlController;
    final nameController = _rssNameController;
    urlController.clear();
    nameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isYoutube ? 'Yeni YouTube Kanalı Ekle' : 'Yeni RSS Kaynağı Ekle'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isYoutube)
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Kaynak Adı'),
                  validator: (value) => value == null || value.isEmpty ? 'İsim boş olamaz' : null,
                ),
              TextFormField(
                controller: urlController,
                decoration: InputDecoration(labelText: isYoutube ? 'Kanal URL\'si' : 'RSS URL Adresi'),
                validator: (value) => value == null || value.isEmpty ? 'URL boş olamaz' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (isYoutube) {
                    final url = urlController.text.trim();
                    if (url.isNotEmpty && !_youtubeChannels.contains(url)) _youtubeChannels.add(url);
                  } else {
                    final name = nameController.text.trim();
                    final url = urlController.text.trim();
                    if (name.isNotEmpty && url.isNotEmpty) _rssSources.add(RssSource(name: name, url: url));
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MainScreen zaten bir Scaffold ve AppBar sağladığı için,
    // burada sadece sayfanın içeriğini döndürüyoruz.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Altta kaydet butonu için boşluk
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'API Anahtarı',
            child: TextFormField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Gemini API anahtarınızı buraya yapıştırın',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'İçerik Tercihleri',
            child: _buildSettingsTile(
              icon: Icons.interests,
              title: 'İlgi Alanlarını Düzenle',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InterestSelectionScreen())),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Özel RSS Kaynakları',
            child: _buildSourceList(
              sources: _rssSources.map((s) => s.name).toList(),
              onAdd: () => _showAddSourceDialog(isYoutube: false),
              onDelete: (index) => setState(() => _rssSources.removeAt(index)),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Takip Edilen YouTube Kanalları',
            child: _buildSourceList(
              sources: _youtubeChannels,
              onAdd: () => _showAddSourceDialog(isYoutube: true),
              onDelete: (index) => setState(() => _youtubeChannels.removeAt(index)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_alt_rounded),
            label: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Tüm Ayarları Kaydet'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isSaving ? null : _saveAllSettings,
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGET METOTLARI (Aynı Sınıf İçinde) ---
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSourceList({required List<String> sources, required VoidCallback onAdd, required Function(int) onDelete}) {
    return Column(
      children: [
        if (sources.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Henüz kaynak eklenmedi.', style: TextStyle(color: Colors.grey)),
          ),
        ...List.generate(
          sources.length,
              (index) => ListTile(
            title: Text(sources[index], overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => onDelete(index),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const Divider(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Yeni Ekle"),
          ),
        ),
      ],
    );
  }
}