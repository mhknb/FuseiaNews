// lib/features/03_feeds/screens/global_news_feed_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Kendi dosya yollarını kontrol et
import '../../../core/api/PythonApiService.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/gemini_api_service.dart';
import '../../../core/models/news_model.dart';

class GlobalNewsScreen extends StatefulWidget {
  const GlobalNewsScreen({super.key});

  @override
  State<GlobalNewsScreen> createState() => _GlobalNewsScreenState();
}

class _GlobalNewsScreenState extends State<GlobalNewsScreen> {
  // --- SERVİSLER (PYTHONAPISERVICE KALDIRILDI) ---
  final ApiService _apiService = ApiService();
  final GeminiApiService _geminiService = GeminiApiService();
  late Future<List<HaberModel>> _haberlerFuture;

  @override
  void initState() {
    super.initState();
    _haberlerFuture = _apiService.fetchGlobalNews();
  }

  Future<void> _sharePost(Uint8List imageBytes, String postText) async {
    try {
      // --- 1. ADIM: METNİ PANOYA KOPYALA ---
      await Clipboard.setData(ClipboardData(text: postText));

      // --- 2. ADIM: KULLANICIYA BİLGİ VER ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metin panoya kopyalandı!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // --- 3. ADIM: GÖRSELİ PAYLAŞ ---
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/ai_generated_post.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Artık 'text' parametresini göndermemize gerek yok, çünkü Instagram onu zaten okumuyor.
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
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('Post Oluştur'),
            onPressed: () {
              Navigator.pop(context);
              _generatePostAndImage(summary ?? haber.description, haber.title);
            },
          )
        ],
      ),
    );
  }







  /// Bir haberden sosyal medya gönderisi (metin ve İNTERNETTEN GELEN GÖRSEL) üretir.
  Future<void> _generatePostAndImage(String summaryContent, String title) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Dialog(child: Padding(padding: EdgeInsets.all(20.0), child: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 20), Text("İçerikler Üretiliyor...")]))));

    String? postTextForSharing;
    Uint8List? finalImageBytes; // Bu artık şablonlu değil, ham görsel olacak

    try {
      // 1. ADIM: Metni Gemini'den, ham görseli internetten eş zamanlı olarak al.
      final postTextFuture = _geminiService.createInstagramPost(summaryContent);
      final rawImageFuture = http.get(Uri.parse('https://picsum.photos/1080')); // Rastgele görsel
      final results = await Future.wait([postTextFuture, rawImageFuture]);

      postTextForSharing = results[0] as String?;
      final rawImageResponse = results[1] as http.Response;

      // 2. ADIM: PYTHON ADIMI ARTIK YOK. Doğrudan gelen görseli kullan.
      if (rawImageResponse.statusCode == 200 && (postTextForSharing != null && !postTextForSharing.contains("API hatası"))) {
        print("İnternetten ham görsel başarıyla alındı.");
        finalImageBytes = rawImageResponse.bodyBytes; // Doğrudan ata
      } else {
        throw Exception('Ham görsel veya Instagram metni alınamadı. Gelen metin: $postTextForSharing');
      }
    } catch (e) {
      print("İçerik oluşturma akışında hata: $e");
    }

    if (!mounted) return;
    Navigator.pop(context); // Yükleniyor penceresini kapat

    // 3. ADIM: Nihai sonucu (metin + internetten gelen görsel) kullanıcıya göster.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paylaşıma Hazır!"),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (finalImageBytes != null)
            ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.memory(finalImageBytes))
          else
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text("Paylaşılacak Metin:\n${postTextForSharing ?? "Metin üretilemedi."}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Paylaş'),
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Hata: ${snapshot.error}', textAlign: TextAlign.center)));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final haberler = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _haberlerFuture = _apiService.fetchGlobalNews();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: haberler.length,
              itemBuilder: (context, index) {
                return _buildNewsCard(haberler[index]);
              },
            ),
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
