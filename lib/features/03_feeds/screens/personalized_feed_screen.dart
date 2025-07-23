// lib/features/03_feeds/screens/personalized_feed_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/PythonApiService.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/gemini_api_service.dart';
import '../../../core/models/news_model.dart';
import '../../04_settings/screens/settings_screen.dart';

class PersonalizedFeedScreen extends StatefulWidget {
  const PersonalizedFeedScreen({super.key});

  @override
  State<PersonalizedFeedScreen> createState() => _PersonalizedFeedScreenState();
}

class _PersonalizedFeedScreenState extends State<PersonalizedFeedScreen> {
  final RssService _apiService = RssService();
  final GeminiApiService _geminiService = GeminiApiService();
  final PythonApiService _pythonApiService = PythonApiService();
  late Future<List<HaberModel>> _haberlerFuture;

  @override
  void initState() {
    super.initState();
    _fetchAndTranslateNews();
  }

  void _fetchAndTranslateNews() {
    setState(() {
      _haberlerFuture = _loadData();
    });
  }




  Future<List<HaberModel>> _loadData() async {
    List<HaberModel> newsList = await _apiService.fetchPersonalizedNews();

    int itemsToTranslate = newsList.length > 10 ? 10 : newsList.length;

    for (int i = 0; i < itemsToTranslate; i++) {
      var haber = newsList[i];
      if (!haber.isYoutubeVideo) {
        print("Çevriliyor biraz bekle: ${haber.title}");

        haber.title = await _geminiService.translateToTurkish(haber.title) ?? haber.title;
        haber.description = await _geminiService.translateToTurkish(haber.description) ?? haber.description;

        await Future.delayed(const Duration(milliseconds: 500)); // Yarım saniye bekle
      }
    }
    return newsList;
  }



  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not lsaunch $url');
    }
  }






  Future<void> _sharePost(Uint8List imageBytes, String postText) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/image.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      final result = await Share.shareXFiles([XFile(imagePath)], text: postText);
      if (result.status == ShareResultStatus.success) print('Paylaşım başarılı!');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paylaşım sırasında bir hata oluştu: $e')));
    }
  }







  Future<void> _summarizeAndShowPopup(HaberModel haber) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    final summary = await _geminiService.summarizeText(haber.description);
    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yapay Zeka Özeti'),
        content: SingleChildScrollView(child: Text(summary ?? 'Özet alınamadı.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          FilledButton.icon(
            icon: const Icon(Icons.photo_camera),
            label: const Text('Post Oluştur'),
            onPressed: () {
              Navigator.pop(context);
              _generatePostAndImage(haber.description, haber.title);
            },
          )
        ],
      ),
    );
  }






  Future<void> _generatePostAndImage(String rawContent, String title) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Dialog(child: Padding(padding: EdgeInsets.all(20.0), child: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 20), Text("İçerikler Üretiliyor...")]))));
    String? postText;
    Uint8List? finalImageBytes;
    try {
      final postTextFuture = _geminiService.createInstagramPost(rawContent);
      final rawImageFuture = http.get(Uri.parse('https://picsum.photos/1080'));
      final results = await Future.wait([postTextFuture, rawImageFuture]);
      postText = results[0] as String?;
      final rawImageResponse = results[1] as http.Response;
      if (rawImageResponse.statusCode == 200) {
        finalImageBytes = await _pythonApiService.processImageWithPython(rawImageResponse.bodyBytes, title);
      } else {
        throw Exception('Ham görsel alınamadı. Kod: ${rawImageResponse.statusCode}');
      }
    } catch (e) {
      print("İçerik oluşturma akışında hata: $e");
    }
    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paylaşıma Hazır!"),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [if (finalImageBytes != null) ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.memory(finalImageBytes)) else const Icon(Icons.error_outline, color: Colors.red, size: 50), const SizedBox(height: 16), Text(postText ?? "Metin üretilemedi.")])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Instagramda Paylaş'),
            onPressed: () {
              if (finalImageBytes != null && postText != null) _sharePost(finalImageBytes, postText);
              else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paylaşılacak içerik bulunamadı!')));
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.interests_rounded, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('İçerik Bulunamadı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Lütfen Ayarlar\'dan ilgi alanlarınızı ve kaynaklarınızı kontrol edin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Ayarları Aç'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => _fetchAndTranslateNews());
                    },
                  )
                ],
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final haberler = snapshot.data!;
          return ListView.builder(
            itemCount: haberler.length,
            itemBuilder: (context, index) {
              final haber = haberler[index];
              // Gelen verinin tipine göre farklı kart göster
              return haber.isYoutubeVideo
                  ? _buildYoutubeVideoCard(haber)
                  : _buildNewsCard(haber);
            },
          );
        } else {
          return const Center(child: Text('Bilinmeyen bir hata oluştu.'));
        }
      },
    );
  }

  // --- YARDIMCI KART WIDGET'LARI ---
  Widget _buildNewsCard(HaberModel haber) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        onTap: () => _summarizeAndShowPopup(haber),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (haber.sourceIconUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                  child: Image.network(haber.sourceIconUrl!, width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.language, size: 20)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(haber.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(haber.sourceName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(haber.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.auto_awesome, color: Colors.amber)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYoutubeVideoCard(HaberModel video) {
    return GestureDetector(
      onTap: () => _launchURL(video.link),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (video.thumbnailUrl != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(video.thumbnailUrl!, height: 200, width: double.infinity, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())), errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Icon(Icons.error, size: 50))),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 50)),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(video.description, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}