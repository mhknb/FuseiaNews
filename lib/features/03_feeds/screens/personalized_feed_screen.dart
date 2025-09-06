import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_view_screen.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/gemini_api_service.dart';
import '../../../core/api/image_search_service.dart';
import '../../../core/models/news_model.dart';
import '../widgets/news_list_item.dart';
import '../widgets/category_filter_bar.dart';
import '../../04_settings/screens/settings_screen.dart';

class PersonalizedFeedScreen extends StatefulWidget {
  const PersonalizedFeedScreen({super.key});

  @override
  State<PersonalizedFeedScreen> createState() => _PersonalizedFeedScreenState();
}

class _PersonalizedFeedScreenState extends State<PersonalizedFeedScreen> {
  final ApiService _apiService = ApiService();
  final GeminiApiService _geminiService = GeminiApiService();
  final ImageSearchService _imageSearchService = ImageSearchService();
  late Future<List<HaberModel>> _haberlerFuture;
  String _loadingStatus = 'Kişisel akışınız hazırlanıyor...';
  
  // Filtreleme için state
  List<String> _selectedCategories = [];
  List<HaberModel> _allPersonalizedNews = [];
  List<HaberModel> _filteredNews = [];
  bool _isFiltered = false;
  
  // Kullanıcının seçtiği kategoriler
  List<String> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
    _fetchAndTranslateNews();
  }

  Future<void> _loadUserInterests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userInterests = prefs.getStringList('user_interests') ?? [];
    });
  }

  void _onCategorySelectionChanged(List<String> selectedCategories) {
    setState(() {
      _selectedCategories = selectedCategories;
      
      // Eğer tüm kategoriler seçiliyse veya hiçbiri seçili değilse filtreleme yapma
      _isFiltered = selectedCategories.isNotEmpty && 
                   selectedCategories.length < _userInterests.length;
      
      if (_isFiltered) {
        _filteredNews = _allPersonalizedNews.where((news) {
          return selectedCategories.contains(news.category);
        }).toList();
        print('🔍 Kişiselleştirilmiş filtrelenmiş haber sayısı: ${_filteredNews.length}');
      } else {
        _filteredNews = _allPersonalizedNews;
        print('📰 Tüm kişiselleştirilmiş haberler gösteriliyor: ${_allPersonalizedNews.length}');
      }
    });
  }

  /// Haber bağlantısını Chrome Custom Tabs ile açar
  Future<void> _openInBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Chrome Custom Tabs kullan - çok daha performanslı
      await launchUrl(
        uri,
        customTabsOptions: const CustomTabsOptions(
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          preferredBarTintColor: Colors.white,
          preferredControlTintColor: Colors.blue,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      print('Chrome Custom Tabs hatası, fallback URL launcher kullanılıyor: $e');
      
      // Fallback - eğer Custom Tabs çalışmazsa normal URL launcher kullan
      try {
        final Uri uri = Uri.parse(url);
        if (await ul.canLaunchUrl(uri)) {
          await ul.launchUrl(
            uri,
            mode: ul.LaunchMode.externalApplication,
          );
        } else {
          throw 'URL açılamadı';
        }
      } catch (fallbackError) {
        print('Fallback URL launcher hatası: $fallbackError');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bağlantı açılamadı: $fallbackError'),
              duration: const Duration(seconds: 3),
          ),
        );
        }
      }
    }
  }

  void _fetchAndTranslateNews({bool forceRefresh = false}) {
    setState(() {
      _haberlerFuture = _loadData(forceRefresh: forceRefresh);
    });
  }

  Future<List<HaberModel>> _loadData({bool forceRefresh = false}) async {
    if (mounted) setState(() => _loadingStatus = 'Kişisel kaynaklar taranıyor...');
    List<HaberModel> newsList = await _apiService.fetchPersonalizedNews(forceRefresh: forceRefresh);
    if (newsList.isEmpty) return [];
    
    // Tüm haberleri sakla
    _allPersonalizedNews = newsList;
    _filteredNews = newsList;

    if (mounted) setState(() => _loadingStatus = 'Haberler çevriliyor...');

      // Sadece RSS/Atom haberlerini çevir (YouTube başlıkları genellikle zaten anlaşılır)
    final rssNews = newsList.where((haber) => !haber.isYoutubeVideo).toList();

    if (rssNews.isEmpty) return newsList;

    // İlk 3 haberi paralel olarak çevir (performans için)
    final itemsToTranslate = rssNews.take(3).toList();

    if (mounted) setState(() => _loadingStatus = '${itemsToTranslate.length} haber çevriliyor...');

    // Paralel çeviri işlemleri
    final translationFutures = <Future>[];

    for (final haber in itemsToTranslate) {
      // Başlık ve açıklamayı aynı anda çevir
      final titleFuture = _geminiService.translateToTurkish(haber.title);
      final descFuture = _geminiService.translateToTurkish(haber.description);

      translationFutures.addAll([titleFuture, descFuture]);
    }

    // Tüm çevirileri paralel olarak bekle
    final results = await Future.wait(translationFutures);

    // Sonuçları haberlere uygula
    int resultIndex = 0;
    for (final haber in itemsToTranslate) {
      haber.title = (results[resultIndex++] as String?) ?? haber.title;
      haber.description = (results[resultIndex++] as String?) ?? haber.description;
    }

    return newsList;
  }

  Future<void> _sharePost(Uint8List imageBytes, String postText) async {
    try {
      await Clipboard.setData(ClipboardData(text: postText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metin panoya kopyalandı!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/ai_generated_post.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      final result = await Share.shareXFiles([XFile(imagePath)]);

      if (result.status == ShareResultStatus.success) {
        print('Paylaşım menüsü başarıyla açıldı!');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım sırasında bir hata oluştu: $e')),
        );
      }
    }
  }

  /// Bir haberin özetini Gemini ile oluşturur ve bir diyalog penceresinde gösterir.
  Future<void> _summarizeAndShowPopup(HaberModel haber) async {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context) => const Center(child: CircularProgressIndicator())
    );

    final summary = await _geminiService.summarizeText(haber.description);

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Yapay Zeka Özeti',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            summary ?? 'Özet alınamadı.',
            style: GoogleFonts.outfit(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: Text(
              'Post Oluştur',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _generatePostAndImage(summary ?? haber.description, haber.title);
            },
          )
        ],
      ),
    );
  }

  /// Bir haberden sosyal medya gönderisi (metin ve görsel) üretir.
  Future<void> _generatePostAndImage(String summaryContent, String title) async {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0), 
          child: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              CircularProgressIndicator(), 
              SizedBox(width: 20), 
              Text("İçerikler Üretiliyor...")
            ]
          )
        )
      )
    );

    String? postTextForSharing;
    Uint8List? finalImageBytes;

    try {
      final postTextFuture = _geminiService.createInstagramPost(summaryContent);
      final keyword = title.split(' ').take(3).join(' ');
      final imageUrlFuture = _imageSearchService.searchImageByKeyword(keyword);

      final results = await Future.wait([postTextFuture, imageUrlFuture]);
      postTextForSharing = results[0] as String?;
      final String? imageUrl = results[1] as String?;

      if (imageUrl != null) {
        final imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          finalImageBytes = imageResponse.bodyBytes;
        }
      } else {
        final imageResponse = await http.get(Uri.parse('https://picsum.photos/1080'));
        if (imageResponse.statusCode == 200) {
          finalImageBytes = imageResponse.bodyBytes;
        }
      }

      if (postTextForSharing == null || finalImageBytes == null) {
        throw Exception('Instagram metni veya görseli oluşturulamadı.');
      }

    } catch (e) {
      print("İçerik oluşturma akışında hata: $e");
    }

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          "Paylaşıma Hazır!",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (finalImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0), 
                    child: Image.memory(finalImageBytes)
                  )
                else
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 50),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Paylaşılacak Metin:\n${postTextForSharing ?? "Metin üretilemedi."}",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
          ),
          FilledButton.icon(
            icon: Icon(Icons.share, color: Colors.white),
            label: Text(
              'Paylaş',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              if (finalImageBytes != null && postTextForSharing != null) {
                _sharePost(finalImageBytes, postTextForSharing);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HaberModel>>(
      future: _haberlerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                const CircularProgressIndicator(), 
                const SizedBox(height: 20), 
                Text(_loadingStatus)
              ]
            )
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return _buildEmptyState();
        } else if (snapshot.hasData) {
          final haberler = snapshot.data!;
          return Column(
            children: [
              // Filtreleme barı (sadece kullanıcının seçtiği kategoriler)
              if (_userInterests.isNotEmpty)
                CategoryFilterBar(
                  categories: _userInterests,
                  selectedCategories: _selectedCategories,
                  onSelectionChanged: _onCategorySelectionChanged,
                  showAllOption: false,
                ),
              // Haber listesi
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchAndTranslateNews(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _isFiltered ? _filteredNews.length : _allPersonalizedNews.length,
                    itemBuilder: (context, index) {
                      final haber = _isFiltered ? _filteredNews[index] : _allPersonalizedNews[index];
                      return Dismissible(
                        key: Key(haber.link),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          await _openInBrowser(haber.link);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.open_in_browser, color: Colors.white, size: 28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: NewsListItem(
                            haber: haber,
                            onTap: () => _summarizeAndShowPopup(haber),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: Text('Bilinmeyen bir hata oluştu.'));
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.interests_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'İçerik Bulunamadı', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
              textAlign: TextAlign.center
            ),
            const Text(
              'Lütfen Ayarlar\'dan takip etmek istediğiniz RSS kaynaklarını ekleyin.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey)
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 1,
              ),
              icon: const Icon(Icons.settings, size: 20),
              label: Text(
                'Ayarları Aç',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const SettingsScreen())
                ).then((_) => _fetchAndTranslateNews(forceRefresh: true));
              },
            )
          ],
        ),
      ),
    );
  }

  // Eski kart fonksiyonu kaldırıldı; NewsListItem kullanılmaktadır.
}

