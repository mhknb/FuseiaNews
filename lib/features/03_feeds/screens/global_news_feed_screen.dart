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

class GlobalNewsScreen extends StatefulWidget {
  const GlobalNewsScreen({super.key});

  @override
  State<GlobalNewsScreen> createState() => _GlobalNewsScreenState();
}

class _GlobalNewsScreenState extends State<GlobalNewsScreen> {
  final ApiService _apiService = ApiService();
  final GeminiApiService _geminiService = GeminiApiService();
  final ImageSearchService _imageSearchService = ImageSearchService();
  late Future<List<HaberModel>> _haberlerFuture;
  bool _isBackgroundRefreshing = false;

  @override
  void initState() {
    super.initState();
    _haberlerFuture = _apiService.fetchGlobalNews();
    _startBackgroundRefresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Start background refresh when app becomes active
  void _startBackgroundRefresh() {
    // Start background refresh after initial load
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && !_isBackgroundRefreshing) {
        _performBackgroundRefresh();
      }
    });
  }

  /// Perform background refresh without blocking UI
  Future<void> _performBackgroundRefresh() async {
    if (_isBackgroundRefreshing) return;

    setState(() {
      _isBackgroundRefreshing = true;
    });

    try {
      // Refresh in background without blocking UI
      final freshNews = await _apiService.fetchGlobalNews(forceRefresh: true);

      if (mounted && freshNews.isNotEmpty) {
        // Show a subtle notification that news has been updated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haberler güncellendi'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Update the future for next refresh
        setState(() {
          _haberlerFuture = Future.value(freshNews);
        });
      }
    } catch (e) {
      print('Background refresh failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundRefreshing = false;
        });
      }
    }
  }

  /// Force refresh news data
  Future<void> _refreshNews() async {
    setState(() {
      _haberlerFuture = _apiService.fetchGlobalNews(forceRefresh: true);
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
        // Paylaşım başarılı
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

  /// Loading view with shimmer effect
  Widget _buildLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: 5, // Show 5 loading cards
      itemBuilder: (context, index) {
        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source name placeholder
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 16,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    // Description placeholder
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 14,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    // Bottom row placeholder
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HaberModel>>(
      future: _haberlerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _haberlerFuture = _apiService.fetchGlobalNews();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final haberler = snapshot.data!;
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshNews,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: haberler.length,
              itemBuilder: (context, index) {
                return _buildNewsCard(haberler[index]);
              },
            ),
          ),
              // Background refresh indicator
              if (_isBackgroundRefreshing)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Güncelleniyor...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } else {
          return const Center(child: Text('Gösterilecek haber bulunamadı.'));
        }
      },
    );
  }

  /// RSS haberleri için görsel odaklı kart widget'ı.
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
              height: 180,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double imageWidth = constraints.maxHeight * 4 / 5; // 4:5 oranı
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Sol taraf - Metin içeriği
                Expanded(
                  flex: 2, // 2/3 oranında genişlik
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
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
