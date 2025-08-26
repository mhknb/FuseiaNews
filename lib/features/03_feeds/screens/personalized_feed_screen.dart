import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as fct;
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

  /// Haber bağlantısını browser'da açar
  Future<void> _openInBrowser(String url) async {
    // Debug: Swipe çalışıyor mu kontrol et
    print('🔄 SWIPE DETECTED! URL: $url');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 Swipe algılandı! Uygulama içi tarayıcı açılıyor...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      final Uri uri = Uri.parse(url);
      
      // Öncelik: Chrome Custom Tabs / SafariVC
      try {
        await fct.launch(
          url,
          customTabsOption: const fct.CustomTabsOption(
            showPageTitle: true,
            enableUrlBarHiding: true,
            enableInstantApps: true,
          ),
          safariVCOptions: const fct.SafariViewControllerOption(
            barCollapsingEnabled: true,
            entersReaderIfAvailable: false,
            preferredBarTintColor: null,
            preferredControlTintColor: null,
            dismissButtonStyle: fct.SafariViewControllerDismissButtonStyle.close,
          ),
        );
        return;
      } catch (e) {
        print('Custom Tabs/SafariVC başarısız: $e, inAppWebView ile deniyorum...');
        // Fallback: In-App WebView
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          return;
        } catch (_) {
          // Son fallback: external
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('URL açılamadı');
          }
        }
      }
    } catch (e) {
      print('URL açma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı açılamadı: $e'),
            duration: Duration(seconds: 3),
          ),
        );
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

    if (mounted) setState(() => _loadingStatus = 'Haberler çevriliyor (Bu işlem biraz sürebilir)...');

    // İlk açılışta kullanıcıyı çok bekletmemek için çevrilecek haber sayısını sınırlayalım.
    int itemsToProcess = newsList.length > 2 ? 2 : newsList.length;
    int translatedCount = 0;

    for (var haber in newsList) {
      // Çeviri limitine ulaştıysak, döngüden çık.
      if (translatedCount >= itemsToProcess) break;

      // Sadece RSS/Atom haberlerini çevir (YouTube başlıkları genellikle zaten anlaşılır)
      if (!haber.isYoutubeVideo) {
        translatedCount++;
        if (mounted) setState(() => _loadingStatus = '$translatedCount/$itemsToProcess haber çevriliyor...');

        haber.title = await _geminiService.translateToTurkish(haber.title) ?? haber.title;
        await Future.delayed(const Duration(milliseconds: 1100)); // 1.1 saniye bekle

        haber.description = await _geminiService.translateToTurkish(haber.description) ?? haber.description;
        await Future.delayed(const Duration(milliseconds: 1100)); // 1.1 saniye bekle
      }
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
              Icons.web,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              'Uygulama İçi Aç',
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          haber.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => 
                            progress == null ? child : const SizedBox(
                              height: 200, 
                              child: Center(child: CircularProgressIndicator())
                            ),
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF374151),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            haber.sourceName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasImage) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              haber.sourceName.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          haber.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (haber.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            haber.description,
                            maxLines: hasImage ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
