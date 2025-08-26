import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'web_view_screen.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/gemini_api_service.dart';
import '../../../core/api/image_search_service.dart';
import '../../../core/models/news_model.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchAndTranslateNews();
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

  void _fetchAndTranslateNews() {
    setState(() {
      _haberlerFuture = _loadData();
    });
  }

  Future<List<HaberModel>> _loadData() async {
    if (mounted) setState(() => _loadingStatus = 'Kişisel kaynaklar taranıyor...');
    List<HaberModel> newsList = await _apiService.fetchPersonalizedNews();
    if (newsList.isEmpty) return [];

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
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            summary ?? 'Özet alınamadı.',
            style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: Text(
              'Post Oluştur',
              style: GoogleFonts.poppins(
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
        title: Text(
          "Paylaşıma Hazır!",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (finalImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), 
                  child: Image.memory(finalImageBytes)
                )
              else
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                "Paylaşılacak Metin:\n${postTextForSharing ?? "Metin üretilemedi."}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: Text(
              'Paylaş',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
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
          return RefreshIndicator(
            onRefresh: () async => _fetchAndTranslateNews(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: haberler.length,
              itemBuilder: (context, index) {
                return _buildNewsCard(haberler[index]);
              },
            ),
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
              icon: const Icon(Icons.settings),
              label: const Text('Ayarları Aç'),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const SettingsScreen())
                ).then((_) => _fetchAndTranslateNews());
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(HaberModel haber) {
    bool hasImage = haber.imageUrl != null && haber.imageUrl!.isNotEmpty;
    
    return Dismissible(
      key: Key(haber.link),
      direction: DismissDirection.endToStart, // Sağdan sola kaydırma
      confirmDismiss: (direction) async {
        // Swipe onaylandığında browser'ı aç
        await _openInBrowser(haber.link);
        return false; // Kartı silme, sadece browser aç
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.open_in_browser,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              'Chrome\'da Aç',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Dinamik tema rengi
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _summarizeAndShowPopup(haber),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double imageWidth = constraints.maxHeight * 4 / 5; // 4:5 oranı
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Kart yüksekliğinde hizala
                    children: [
                // Sol taraf - Metin içeriği
                Expanded(
                  flex: 2, // 2/3 oranında genişlik
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start, // İçeriği dikey olarak dağıt
                      children: [
                        // Üst kısım
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kaynak adı etiketi
                            Text(
                              haber.sourceName.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? const Color(0xFF637588)
                                    : const Color(0xFF637588),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Başlık
                            Text(
                              haber.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                fontSize: 16,
                              ),
                            ),
                            
                            // Açıklama
                            if (haber.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                haber.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF637588)
                                      : const Color(0xFF637588),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Alt bilgiler
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: const Color(0xFF4A90E2),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Özet',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF4A90E2),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              haber.pubDate?.toString().split(' ')[0] ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Kaynak adı
                        Row(
                          children: [
                            Icon(
                              Icons.language,
                              size: 12,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              haber.websiteName ?? haber.sourceName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16), // Metin ve görüntü arası boşluk
                
                // Sağ taraf - Kart yüksekliğinde görüntü
                if (hasImage)
                  SizedBox(
                    width: imageWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        haber.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                    ],
                  );
                },
              ),
            ),
          ),
          ),
        ),
      );
  }
}
