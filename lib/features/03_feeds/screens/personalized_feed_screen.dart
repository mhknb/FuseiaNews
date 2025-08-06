// lib/features/03_feeds/screens/personalized_feed_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  final ApiService _apiService = ApiService();
  final GeminiApiService _geminiService = GeminiApiService();
  final PythonApiService _pythonApiService = PythonApiService();
  late Future<List<HaberModel>> _haberlerFuture;
  String _loadingStatus = 'Kişisel akışınız hazırlanıyor...';

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
    if (mounted) setState(() => _loadingStatus = 'Kişisel kaynaklar taranıyor...');
    // Artık bu fonksiyon sadece RSS/Atom kaynaklarını çekecek
    List<HaberModel> newsList = await _apiService.fetchPersonalizedNews();
    if (newsList.isEmpty) return [];

    if (mounted) setState(() => _loadingStatus = 'Haberler çevriliyor...');
    int itemsToProcess = newsList.length > 5 ? 5 : newsList.length;
    for (int i = 0; i < itemsToProcess; i++) {
      var haber = newsList[i];
      if (mounted) setState(() => _loadingStatus = '${i + 1}/$itemsToProcess haber çevriliyor...');
      haber.title = await _geminiService.translateToTurkish(haber.title) ?? haber.title;
      haber.description = await _geminiService.translateToTurkish(haber.description) ?? haber.description;
      await Future.delayed(const Duration(milliseconds: 1100));
    }
    return newsList;
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
    String? postTextForSharing;
    Uint8List? finalTemplatedImage;
    try {
      final postTextFuture = _geminiService.createInstagramPost(rawContent);
      final rawImageFuture = http.get(Uri.parse('https://picsum.photos/1080'));
      final results = await Future.wait([postTextFuture, rawImageFuture]);
      postTextForSharing = results[0] as String?;
      final rawImageResponse = results[1] as http.Response;
      if (rawImageResponse.statusCode == 200 && postTextForSharing != null) {
        print("Ham görsel alındı, şablona işlenmesi için Python'a gönderiliyor...");
        finalTemplatedImage = await _pythonApiService.createPostWithTemplate(
          rawImageBytes: rawImageResponse.bodyBytes,
          title: title,
          content: rawContent,
        );
      } else {
        throw Exception('Ham görsel veya Instagram metni alınamadı.');
      }
    } catch (e) {
      print("İçerik oluşturma akışında hata: $e");
    }
    if (!mounted) return;
    Navigator.pop(context);
    showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text("Paylaşıma Hazır!"),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [if (finalTemplatedImage != null) ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.memory(finalTemplatedImage)) else const Icon(Icons.error_outline, color: Colors.red, size: 50), const SizedBox(height: 16), Text("Paylaşılacak Metin:\n${postTextForSharing ?? "Metin üretilemedi."}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          FilledButton.icon(icon: const Icon(Icons.share), label: const Text('Paylaş'), onPressed: () { if (finalTemplatedImage != null && postTextForSharing != null) _sharePost(finalTemplatedImage, postTextForSharing); })]));
  }
















  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HaberModel>>(
      future: _haberlerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 20), Text(_loadingStatus)]));
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return _buildEmptyState();
        } else if (snapshot.hasData) {
          final haberler = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _fetchAndTranslateNews(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
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

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildEmptyState() {
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
            const Text('Lütfen Ayarlar\'dan takip etmek istediğiniz RSS kaynaklarını ekleyin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
  }

  Widget _buildNewsCard(HaberModel haber) {
    bool hasImage = haber.imageUrl != null && haber.imageUrl!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _summarizeAndShowPopup(haber),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Image.network(
                haber.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!hasImage && haber.sourceIconUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(haber.sourceIconUrl!, width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.language, size: 20)),
                        ),
                      Text(
                        haber.sourceName.toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Spacer(),
                      Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary.withOpacity(0.8), size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    haber.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (haber.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      haber.description,
                      maxLines: hasImage ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}