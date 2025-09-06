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
import '../widgets/news_list_item.dart';
import '../widgets/animated_news_list.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/category_filter_bar.dart';

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
  
  // Filtreleme için state
  List<String> _selectedCategories = [];
  List<HaberModel> _allNews = [];
  List<HaberModel> _filteredNews = [];
  bool _isFiltered = false;
  
  // Kategori listesi
  final List<String> _availableCategories = [
    'Bilim',
    'Teknoloji', 
    'Gündem',
    'Spor',
    'Eğlence',
    'Yaşam',
    'Finans',
    'Eğitim',
    'Sağlık',
    'Sinema',
    'Oyun',
  ];

  @override
  void initState() {
    super.initState();
    _haberlerFuture = _loadNews();
    _startBackgroundRefresh();
  }

  Future<List<HaberModel>> _loadNews() async {
    final news = await _apiService.fetchGlobalNews();
    _allNews = news;
    _filteredNews = news;
    return news;
  }

  void _onCategorySelectionChanged(List<String> selectedCategories) {
    setState(() {
      _selectedCategories = selectedCategories;
      _isFiltered = selectedCategories.isNotEmpty;
      
      if (_isFiltered) {
        _filteredNews = _allNews.where((news) {
          return selectedCategories.contains(news.category);
        }).toList();
      } else {
        _filteredNews = _allNews;
      }
    });
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Text(
          'Yapay Zeka Özeti',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            summary ?? 'Özet alınamadı.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
            label: Text(
              'Post Oluştur',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
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

  /// Loading view with shimmer effect
  Widget _buildLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: 5, // Show 5 loading cards
      itemBuilder: (context, index) {
        return ShimmerLoading(
          isLoading: true,
          child: const ShimmerNewsCard(),
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
                        _haberlerFuture = _loadNews();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Column(
            children: [
              // Filtreleme barı
              CategoryFilterBar(
                categories: _availableCategories,
                selectedCategories: _selectedCategories,
                onSelectionChanged: _onCategorySelectionChanged,
                showAllOption: true,
              ),
              // Haber listesi
              Expanded(
                child: _isFiltered 
                    ? AnimatedNewsList(
                        haberler: _filteredNews,
                        onItemTap: _summarizeAndShowPopup,
                        onRefresh: _refreshNews,
                        isBackgroundRefreshing: _isBackgroundRefreshing,
                      )
                    : AnimatedNewsList(
                        haberler: snapshot.data!,
                        onItemTap: _summarizeAndShowPopup,
                        onRefresh: _refreshNews,
                        isBackgroundRefreshing: _isBackgroundRefreshing,
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

  /// Eski kart fonksiyonu kaldırıldı; NewsListItem kullanılmaktadır.
}
