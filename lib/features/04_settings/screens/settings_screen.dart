// lib/features/04_settings/screens/settings_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utilis/providers.dart';
import '../../01_setup/screens/interest_selection_screen.dart';


class RssSource {
  String name;
  String url;
  RssSource({required this.name, required this.url});
  Map<String, dynamic> toJson() => {'name': name, 'url': url};
  factory RssSource.fromJson(Map<String, dynamic> json) => RssSource(name: json['name'], url: json['url']);
}

// Varsayılan RSS kaynakları (ilk açılışta otomatik yüklenecek)
final List<RssSource> kDefaultRssSources = [
  RssSource(name: 'Anadolu Ajansı (AA)', url: 'https://www.aa.com.tr/tr/rss/default?cat=guncel'),
  RssSource(name: 'NTV', url: 'https://www.ntv.com.tr/gundem.rss'),
  RssSource(name: 'CNN Türk', url: 'https://www.cnnturk.com/feed/rss/all/news'),
  RssSource(name: 'Sözcü', url: 'https://www.sozcu.com.tr/rss.xml'),
  RssSource(name: 'Cumhuriyet', url: 'http://www.cumhuriyet.com.tr/rss/son_dakika.xml'),
  RssSource(name: 'Haber7', url: 'https://i12.haber7.net/rss/sondakika.xml'),
  RssSource(name: 'Milliyet', url: 'https://www.milliyet.com.tr/rss/rssNew/gundemRss.xml'),
  RssSource(name: 'Sabah', url: 'https://www.sabah.com.tr/rss/gundem.xml'),
  RssSource(name: 'Habertürk Ekonomi', url: 'https://www.haberturk.com/rss/kategori/ekonomi.xml'),
  RssSource(name: 'AA Ekonomi', url: 'https://www.aa.com.tr/tr/rss/default?cat=ekonomi'),
  RssSource(name: 'Investing.com Türkiye', url: 'https://tr.investing.com/rss/news.rss'),
  RssSource(name: 'Dünya Gazetesi', url: 'https://www.dunya.com/rss'),
  RssSource(name: 'Ekonomist', url: 'https://www.ekonomist.com.tr/rss.xml'),
  RssSource(name: 'Bloomberg HT', url: 'https://www.bloomberght.com/rss'),
  RssSource(name: 'A Spor', url: 'https://www.aspor.com.tr/rss.xml'),
  RssSource(name: 'NTV Spor', url: 'https://www.ntvspor.net/rss'),
  RssSource(name: 'Fotomaç', url: 'https://www.fotomac.com.tr/rss.xml'),
  RssSource(name: 'Fanatik', url: 'https://www.fanatik.com.tr/rss.xml'),
  RssSource(name: 'TRT Spor', url: 'https://www.trtspor.com.tr/rss.xml'),
  RssSource(name: 'Sporx', url: 'https://www.sporx.com/rss.xml'),
  RssSource(name: 'Donanım Haber', url: 'https://www.donanimhaber.com/rss.xml'),
  RssSource(name: 'Webrazzi', url: 'https://webrazzi.com/feed/'),
  RssSource(name: 'Teknoblog', url: 'https://www.teknoblog.com/feed/'),
  RssSource(name: 'ShiftDelete.Net', url: 'https://shiftdelete.net/feed'),
  RssSource(name: 'Webtekno', url: 'https://www.webtekno.com/rss.xml'),
  RssSource(name: 'Chip Online', url: 'https://www.chip.com.tr/rss.xml'),
  RssSource(name: 'Beyaz Perde', url: 'https://www.beyazperde.com/rss/haberler.xml'),
  RssSource(name: 'Onedio', url: 'https://onedio.com/rss.xml'),
  RssSource(name: 'Habertürk Magazin', url: 'https://www.haberturk.com/rss/kategori/magazin.xml'),
  RssSource(name: 'Milliyet Magazin', url: 'https://www.milliyet.com.tr/rss/rssNew/magazinRss.xml'),
  RssSource(name: 'Hürriyet Magazin', url: 'https://www.hurriyet.com.tr/rss/magazin'),
  RssSource(name: 'AA Politika', url: 'https://www.aa.com.tr/tr/rss/default?cat=politika'),
  RssSource(name: 'Habertürk Gündem', url: 'https://www.haberturk.com/rss/kategori/gundem.xml'),
  RssSource(name: 'T24', url: 'https://t24.com.tr/rss'),
  RssSource(name: 'Gazete Duvar', url: 'https://www.gazeteduvar.com.tr/rss.xml'),
  RssSource(name: 'BirGün', url: 'https://www.birgun.net/rss'),
  RssSource(name: 'Arkitera', url: 'https://www.arkitera.com/rss.xml'),
  RssSource(name: 'Sanat Haberleri', url: 'https://sanathaber.com/rss.xml'),
  RssSource(name: 'Kültür Servisi', url: 'https://kulturservisi.com/rss.xml'),
  RssSource(name: 'Edebiyat Haber', url: 'https://www.edebiyathaber.net/rss.xml'),
  RssSource(name: 'Müze Haberleri', url: 'https://muzehaberleri.com/rss.xml'),
  RssSource(name: 'Bilim ve Gelecek', url: 'https://bilimvegelecek.com.tr/rss.xml'),
  RssSource(name: 'TÜBİTAK Bilim Teknik', url: 'https://bilimteknik.tubitak.gov.tr/rss.xml'),
  RssSource(name: 'Bilim Günlüğü', url: 'https://www.bilimgunlugu.com/rss.xml'),
  RssSource(name: 'Popular Science Türkiye', url: 'https://www.populerbildim.com/rss.xml'),
];

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
    if (rssJson != null && rssJson.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(rssJson);
      _rssSources = decodedList.map((item) => RssSource.fromJson(item)).toList();
    } else {
      // İlk yüklemede varsayılan kaynakları uygula ve kalıcı olarak kaydet
      _rssSources = List<RssSource>.from(kDefaultRssSources);
      final List<Map<String, dynamic>> encodedRssList = _rssSources.map((s) => s.toJson()).toList();
      await prefs.setString('user_custom_sources', jsonEncode(encodedRssList));
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


  void _showAddSourceDialog({required bool isYoutube}) {
   final urlController = isYoutube ? _youtubeUrlController : _rssUrlController;
    final nameController = _rssNameController;
    urlController.clear();
    nameController.clear();
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcının dışarı tıklayarak kapatmasını engelle
      builder: (context) => AlertDialog(
        title: Text(isYoutube ? 'Yeni YouTube Kanalı Ekle' : 'Yeni RSS Kaynağı Ekle'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isYoutube)
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Kaynak Adı',
                      hintText: 'Örn: Hürriyet Teknoloji',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kaynak adı boş olamaz.';
                      }
                      return null;
                    },
                  ),

                if (!isYoutube) const SizedBox(height: 16),


                TextFormField(
                  controller: urlController,
                  keyboardType: TextInputType.url, // URL klavyesi açar
                  decoration: InputDecoration(
                    labelText: isYoutube ? 'YouTube Kanal URL\'si' : 'RSS/Atom URL Adresi',

                    // --- BİLGİLENDİRME METİNLERİ ---
                    hintText: isYoutube
                        ? 'örn: https://youtube.com/channel/UC...'
                        : 'örn: https://site.com/feed/',

                    helperText: isYoutube
                        ? 'Lütfen /channel/UC... formatındaki linki girin.'
                        : 'Geçerli bir RSS veya Atom linki olmalıdır.',
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'URL boş olamaz.';
                    }
                    // Basit URL format kontrolü
                    if (!value.trim().startsWith('http')) {
                      return 'Lütfen geçerli bir URL girin.';
                    }
                    // YouTube için daha spesifik bir kontrol
                    if (isYoutube && !value.trim().contains('/channel/UC')) {
                      return 'Geçersiz format. Lütfen tam kanal linkini girin.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              // Form geçerliyse ekleme işlemini yap
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Altta kaydet butonu için boşluk
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Görünüm Ayarları',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
              title: const Text('Koyu Tema'),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  // Provider'daki toggleTheme fonksiyonunu çağır
                  themeProvider.toggleTheme(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),


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