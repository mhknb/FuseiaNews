

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



class GlobalNewsScreen extends StatefulWidget {
  const GlobalNewsScreen({super.key});

  @override
  State<GlobalNewsScreen> createState() => _GlobalNewsScreenState();
}

class _GlobalNewsScreenState extends State<GlobalNewsScreen> {
  final ApiService _apiService = ApiService();
  final GeminiApiService _geminiService = GeminiApiService();
  final PythonApiService _pythonApiService = PythonApiService();

  late Future<List<HaberModel>> _haberlerFuture;

  @override
  void initState() {
    super.initState();
    _haberlerFuture = _apiService.fetchGlobalNews();
  }







  Future<void> _summarizeAndShowPopup(HaberModel haber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final summary = await _geminiService.summarizeText(haber.description);

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yapay Zeka Özeti'),
        content: SingleChildScrollView(child: Text(summary ?? 'Özet alınamadı.')),
        actions: [
          TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.pop(context),
          ),
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



  Future<void> _sharePost(Uint8List imageBytes, String postText) async {

  }






  Future<void> _generatePostAndImage(String rawContent, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("İçerikler Üretiliyor..."),
          ]),
        ),
      ),
    );

    String? postTextForSharing; // Instagram metni (bu değişmedi)
    Uint8List? finalTemplatedImage; // Şablonlu nihai görsel

    try {
      // 1. ADIM: Metin ve ham görseli eş zamanlı olarak al
      final postTextFuture = _geminiService.createInstagramPost(rawContent);
      final rawImageFuture = http.get(Uri.parse('https://picsum.photos/1080')); // 1080x1080
      final results = await Future.wait([postTextFuture, rawImageFuture]);

      postTextForSharing = results[0] as String?;
      final rawImageResponse = results[1] as http.Response;

      // 2. ADIM: Ham görseli ve metinleri Python'a gönder
      if (rawImageResponse.statusCode == 200 && postTextForSharing != null) {
        print("Ham görsel alındı, şablona işlenmesi için Python'a gönderiliyor...");

        // YENİ SERVİS FONKSİYONUNU ÇAĞIRIYORUZ
        finalTemplatedImage = await _pythonApiService.createPostWithTemplate(
          rawImageBytes: rawImageResponse.bodyBytes,
          title: title, // Haberin orijinal başlığı
          content: rawContent, // Haberin orijinal içeriği/açıklaması
        );
      } else {
        throw Exception('Ham görsel veya Instagram metni alınamadı.');
      }
    } catch (e) {
      print("İçerik oluşturma akışında hata: $e");
    }

    if (!mounted) return;
    Navigator.pop(context); // Yükleniyor penceresini kapat

    // 3. ADIM: Nihai sonucu kullanıcıya göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paylaşıma Hazır!"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // finalTemplatedImage artık Python'dan gelen şablonlu görsel
              if (finalTemplatedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(finalTemplatedImage),
                )
              else
                const Icon(Icons.error_outline, color: Colors.red, size: 50),

              const SizedBox(height: 16),
              // Paylaşılacak olan Instagram metnini de gösterelim (opsiyonel)
              Text(
                "Paylaşılacak Metin:\n${postTextForSharing ?? "Metin üretilemedi."}",
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Paylaş'),
            onPressed: () {
              if (finalTemplatedImage != null && postTextForSharing != null) {
                _sharePost(finalTemplatedImage, postTextForSharing);
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
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final haberler = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0), // Liste etrafında boşluk
            itemCount: haberler.length,
            itemBuilder: (context, index) {
              final haber = haberler[index];
              // Artık ListTile yerine yeni _buildNewsCard widget'ımızı çağırıyoruz
              return _buildNewsCard(haber);
            },
          );
        } else {
          return const Center(child: Text('Gösterilecek haber bulunamadı.'));
        }
      },
    );
  }

  // --- YENİ, RESİMLİ KART TASARIMI ---
  Widget _buildNewsCard(HaberModel haber) {
    return Card(
      clipBehavior: Clip.antiAlias, // Resmin kartın köşelerinden taşmasını engeller
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _summarizeAndShowPopup(haber),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SOL TARAFTAKİ GÖRSEL ---
            // Eğer haberin görseli varsa onu, yoksa kaynak logosunu göster
            SizedBox(
              width: 120, // Resim genişliği
              height: 140, // Resim yüksekliği
              child: Image.network(
                haber.imageUrl ?? haber.sourceIconUrl ?? '', // Ana resim > ikon > boş
                fit: BoxFit.cover,
                // Resim yüklenirken veya hata verdiğinde ne olacağı
                loadingBuilder: (context, child, progress) =>
                progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              ),
            ),

            // --- SAĞ TARAFTAKİ METİN İÇERİĞİ ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kaynak Adı
                    Text(
                      haber.sourceName.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary, // Altın rengi
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Haber Başlığı
                    Text(
                      haber.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    // AI İkonu
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}