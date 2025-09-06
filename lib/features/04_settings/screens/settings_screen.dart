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
  // Bilim kategorisi
  RssSource(name: 'Arkeofili', url: 'https://arkeofili.com/feed/'),
  RssSource(name: 'Bilim ve Gelecek', url: 'https://bilimvegelecek.com.tr/index.php/feed/'),
  RssSource(name: 'Bilimoloji', url: 'https://www.bilimoloji.com/feed/'),
  RssSource(name: 'Bilimup', url: 'https://www.bilimup.com/rss.xml'),
  RssSource(name: 'Tarihli Bilim', url: 'https://www.tarihlibilim.com/feed/'),
  RssSource(name: 'Fizikist', url: 'https://www.fizikist.com/feed'),
  RssSource(name: 'Gerçek Bilim', url: 'https://www.gercekbilim.com/feed/'),
  RssSource(name: 'Gelecek Bilimde', url: 'https://gelecekbilimde.net/feed/'),
  RssSource(name: 'Herkese Bilim Teknoloji', url: 'https://www.herkesebilimteknoloji.com/feed'),
  RssSource(name: 'Matematiksel', url: 'https://www.matematiksel.org/feed'),
  RssSource(name: 'Moletik', url: 'https://moletik.com/feed/'),
  RssSource(name: 'Popular Science', url: 'https://popsci.com.tr/feed/'),
  RssSource(name: 'Sarkaç', url: 'https://sarkac.org/feed/'),
  
  // Teknoloji kategorisi
  RssSource(name: 'DijitalX', url: 'https://www.dijitalx.com/feed/'),
  RssSource(name: 'CHIP Online', url: 'https://www.chip.com.tr/rss'),
  RssSource(name: 'Donanım Haber', url: 'https://www.donanimhaber.com/rss/tum/'),
  RssSource(name: 'Donanım Günlüğü', url: 'https://www.donanimgunlugu.com/feed/'),
  RssSource(name: 'LOG', url: 'https://www.log.com.tr/feed/'),
  RssSource(name: 'Megabayt', url: 'https://www.megabayt.com/rss/news'),
  RssSource(name: 'PC Hocası', url: 'https://www.pchocasi.com.tr/feed/'),
  RssSource(name: 'Technopat', url: 'https://www.technopat.net/feed/'),
  RssSource(name: 'Teknoblog', url: 'http://www.teknoblog.com/feed/'),
  RssSource(name: 'Teknolojioku', url: 'https://www.teknolojioku.com/export/rss'),
  RssSource(name: 'TeknoBurada', url: 'https://www.teknoburada.net/feed/'),
  RssSource(name: 'Tam İndir', url: 'http://feeds.feedburner.com/tamindir/stream'),
  RssSource(name: 'Webrazzi', url: 'https://webrazzi.com/feed/'),
  RssSource(name: 'T24 Bilim/Teknoloji', url: 'https://t24.com.tr/rss/bilim-teknoloji-haberleri'),
  RssSource(name: 'Sabah Teknoloji', url: 'https://www.sabah.com.tr/rss/teknoloji.xml'),
  RssSource(name: 'Habertürk Teknoloji', url: 'https://www.haberturk.com/rss/kategori/teknoloji.xml'),
  RssSource(name: 'NTV Teknoloji', url: 'https://www.ntv.com.tr/teknoloji.rss'),
  RssSource(name: 'Star Teknoloji', url: 'http://www.star.com.tr/rss/teknoloji.xml'),
  
  // Gündem
  RssSource(name: 'A Haber', url: 'https://www.ahaber.com.tr/rss/gundem.xml'),
  RssSource(name: 'Anadolu Ajansı', url: 'https://www.aa.com.tr/tr/rss/default?cat=guncel'),
  RssSource(name: 'BBC Türkçe', url: 'https://feeds.bbci.co.uk/turkce/rss.xml'),
  RssSource(name: 'CNN Türk', url: 'https://www.cnnturk.com/feed/rss/all/news'),
  RssSource(name: 'Cumhuriyet', url: 'http://www.cumhuriyet.com.tr/rss/son_dakika.xml'),
  RssSource(name: 'Habertürk', url: 'https://www.haberturk.com/rss'),
  RssSource(name: 'Hürriyet', url: 'http://www.hurriyet.com.tr/rss/anasayfa'),
  RssSource(name: 'NTV', url: 'https://www.ntv.com.tr/gundem.rss'),
  RssSource(name: 'Sabah', url: 'https://www.sabah.com.tr/rss/gundem.xml'),
  RssSource(name: 'Sözcü', url: 'https://www.sozcu.com.tr/feeds-rss-category-sozcu'),
  RssSource(name: 'Star', url: 'https://www.star.com.tr/rss/rss.asp'),
  RssSource(name: 'T24', url: 'https://t24.com.tr/rss'),
  RssSource(name: 'TRT Haber', url: 'https://www.trthaber.com/sondakika.rss'),
  RssSource(name: 'Yeni Akit', url: 'https://www.yeniakit.com.tr/rss/haber/gundem'),
  RssSource(name: 'Yeni Şafak', url: 'https://www.yenisafak.com/rss?xml=gundem'),
  RssSource(name: 'T24 Dünya', url: 'https://t24.com.tr/rss/dunya-haberleri'),
  RssSource(name: 'Cumhuriyet Dünya', url: 'http://www.cumhuriyet.com.tr/rss/17.xml'),
  RssSource(name: 'Sabah Dünya', url: 'https://www.sabah.com.tr/rss/dunya.xml'),
  RssSource(name: 'Star Dünya', url: 'http://www.star.com.tr/rss/dunya.xml'),
  
  // Spor kategorisi
  RssSource(name: 'A Spor', url: 'https://www.aspor.com.tr/rss'),
  RssSource(name: 'Fotomaç', url: 'https://www.fotomac.com.tr/rss/anasayfa.xml'),
  RssSource(name: 'NTV Spor', url: 'https://www.ntvspor.net/rss/'),
  RssSource(name: 'Sözcü Spor', url: 'https://www.sozcu.com.tr/feeds-rss-category-spor'),
  RssSource(name: 'Spor Maraton', url: 'https://www.spormaraton.com/rss/'),
  RssSource(name: 'T24 Spor', url: 'https://t24.com.tr/rss/spor-haberleri'),
  RssSource(name: 'Cumhuriyet Spor', url: 'http://www.cumhuriyet.com.tr/rss/32.xml'),
  RssSource(name: 'Habertürk Spor', url: 'https://www.haberturk.com/rss/spor.xml'),
  RssSource(name: 'Sabah Spor', url: 'https://www.sabah.com.tr/rss/spor.xml'),
  RssSource(name: 'Star Spor', url: 'http://www.star.com.tr/rss/spor.xml'),
  RssSource(name: 'Fotomaç Süper Lig', url: 'https://www.fotomac.com.tr/rss/futbol/super-lig.xml'),
  RssSource(name: 'Fotomaç Beşiktaş', url: 'https://www.fotomac.com.tr/rss/futbol/besiktas.xml'),
  RssSource(name: 'Fotomaç Fenerbahçe', url: 'https://www.fotomac.com.tr/rss/futbol/fenerbahce.xml'),
  RssSource(name: 'Fotomaç Galatasaray', url: 'https://www.fotomac.com.tr/rss/futbol/galatasaray.xml'),
  RssSource(name: 'Fotomaç Basketbol', url: 'https://www.fotomac.com.tr/rss/basketbol.xml'),
  
  // Eğlence kategorisi
  RssSource(name: 'Atarita', url: 'https://www.atarita.com/feed/'),
  RssSource(name: 'Bigumigu', url: 'https://bigumigu.com/feed/'),
  RssSource(name: 'Bilimkurgu Kulübü', url: 'https://www.bilimkurgukulubu.com/feed/'),
  RssSource(name: 'FRPNET', url: 'https://frpnet.net/feed'),
  RssSource(name: 'Geekyapar', url: 'https://geekyapar.com/feed/'),
  RssSource(name: 'Kayıp Rıhtım', url: 'https://kayiprihtim.com/feed/'),
  RssSource(name: 'ListeList', url: 'https://listelist.com/feed/'),
  RssSource(name: 'The Geyik', url: 'http://www.thegeyik.com/feed/'),
  RssSource(name: 'Turkmmo', url: 'https://www.turkmmo.com/feed'),
  RssSource(name: 'Turuncu Levye', url: 'https://www.turunculevye.com/feed/'),
  RssSource(name: 'Campaign Türkiye', url: 'https://www.campaigntr.com/feed/'),
  RssSource(name: 'Cumhuriyet Magazin', url: 'http://www.cumhuriyet.com.tr/rss/33.xml'),
  RssSource(name: 'Star Magazin', url: 'http://www.star.com.tr/rss/magazin.xml'),
  RssSource(name: 'Star Sinema', url: 'http://www.star.com.tr/rss/sinema.xml'),
  RssSource(name: 'Star Sanat', url: 'http://www.star.com.tr/rss/sanat.xml'),
  RssSource(name: 'T24 Kültür & Sanat', url: 'https://t24.com.tr/rss/kultur-sanat-haberleri'),
  
  // Yaşam kategorisi
  RssSource(name: 'İstanbul Life', url: 'https://www.istanbullife.com/feed/'),
  RssSource(name: 'Megabayt Yaşam', url: 'https://www.megabayt.com/yasam/rss'),
  RssSource(name: 'Medium Türkçe', url: 'https://medium.com/feed/@turkce'),
  RssSource(name: 'Uplifers', url: 'https://uplifers.com/feed/'),
  RssSource(name: 'Sabah Yaşam', url: 'https://www.sabah.com.tr/rss/yasam.xml'),
  RssSource(name: 'NTV Yaşam', url: 'https://www.ntv.com.tr/yasam.rss'),
  
  // Finans kategorisi
  RssSource(name: 'Bigpara', url: 'http://bigpara.hurriyet.com.tr/rss/'),
  RssSource(name: 'Dünya', url: 'https://www.dunya.com/rss?dunya'),
  RssSource(name: 'Investing', url: 'https://tr.investing.com/rss/'),
  RssSource(name: 'Sözcü Ekonomi', url: 'https://www.sozcu.com.tr/feeds-rss-category-ekonomi'),
  RssSource(name: 'T24 Ekonomi', url: 'https://t24.com.tr/rss/ekonomi-haberleri'),
  RssSource(name: 'Cumhuriyet Ekonomi', url: 'http://www.cumhuriyet.com.tr/rss/24.xml'),
  RssSource(name: 'Habertürk Ekonomi', url: 'https://www.haberturk.com/rss/ekonomi.xml'),
  RssSource(name: 'Sabah Ekonomi', url: 'https://www.sabah.com.tr/rss/ekonomi.xml'),
  RssSource(name: 'Star Ekonomi', url: 'http://www.star.com.tr/rss/ekonomi.xml'),
  RssSource(name: 'NTV Ekonomi', url: 'https://www.ntv.com.tr/ekonomi.rss'),
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
  bool _useOwnApiKey = false;

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
    _useOwnApiKey = prefs.getBool('use_own_api_key') ?? false;
    _apiKeyController.text = prefs.getString('user_api_key') ?? '';
    _youtubeChannels = prefs.getStringList('youtube_channels') ?? [];

    final String? rssJson = prefs.getString('user_custom_sources');
    if (rssJson != null && rssJson.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(rssJson);
      // Varsayılan/global kaynak URL'lerini kişisel listeden ayıkla
      final Set<String> defaultUrls = kDefaultRssSources.map((e) => e.url).toSet();
      final filtered = decodedList.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('url')) {
          return !defaultUrls.contains(item['url']);
        }
        return true;
      }).toList();

      _rssSources = filtered.map((item) => RssSource.fromJson(item)).toList();

      // Eğer bir şey temizlendiyse depoyu güncelle
      if (filtered.length != decodedList.length) {
        await prefs.setString('user_custom_sources', jsonEncode(filtered));
      }
    } else {
      // Artık otomatik varsayılan ekleme YOK. Liste boş bırakılır.
      _rssSources = [];
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveAllSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_own_api_key', _useOwnApiKey);
      if (_useOwnApiKey) {
        await prefs.setString('user_api_key', _apiKeyController.text);
      }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kendi API anahtarımı kullan'),
                  subtitle: const Text('Kapalıyken varsayılan anahtar kullanılır'),
                  value: _useOwnApiKey,
                  onChanged: (value) {
                    setState(() {
                      _useOwnApiKey = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (_useOwnApiKey)
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Gemini API anahtarınızı buraya yapıştırın',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  const Text(
                    'Varsayılan anahtar ve model kullanılacak: models/gemini-2.0-flash-lite',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 1,
            ),
            icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_alt_rounded, size: 20),
            label: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Tüm Ayarları Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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