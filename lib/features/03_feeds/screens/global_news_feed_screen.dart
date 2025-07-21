// lib/screens/global_news_feed.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/PythonApiService.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/gemini_api_service.dart';
import '../../../core/api/image_generation_service.dart';
import '../../../core/models/news_model.dart';



class GlobalNewsScreen extends StatefulWidget {
  const GlobalNewsScreen({super.key});

  @override
  State<GlobalNewsScreen> createState() => _GlobalNewsScreenState();
}

class _GlobalNewsScreenState extends State<GlobalNewsScreen> {
  final RssService _apiService = RssService();
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






  Future<void> _generatePostAndImage(String rawContent, String title) async {
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
              Text("İçerikler Üretiliyor..."),
            ],
          ),
        ),
      ),
    );
    String? postText;
    Uint8List? finalImageBytes;

    try {
      final postTextFuture = _geminiService.createInstagramPost(rawContent);
      final rawImageFuture = http.get(Uri.parse('https://picsum.photos/1080'));
      final results = await Future.wait([postTextFuture, rawImageFuture]);

      postText = results[0] as String?;
      final rawImageResponse = results[1] as http.Response;

      if (rawImageResponse.statusCode == 200) {
        print("Ham görsel başarıyla alındı, Python'a gönderiliyor...");

        finalImageBytes = await _pythonApiService.processImageWithPython(
          rawImageResponse.bodyBytes,
          title,
        );
      }else {
        throw Exception('Ham görsel alınamadı. Durum Kodu: ${rawImageResponse.statusCode}');
      }

    } catch (e) {
      print("İçerik oluşturma akışında hata: $e");
    }
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paylaşıma Hazır!"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // finalImageBytes artık Python'dan gelen işlenmiş görseldir
              if (finalImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(finalImageBytes),
                )
              else
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(postText ?? "Metin üretilemedi."),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton.icon(
            icon: Icon(Icons.share),
            label: const Text('Instagramda Paylaş'),
            onPressed: () {
              // TODO: Buraya 'share_plus' paketi ile paylaşma kodu gelecek.
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Hata: ${snapshot.error}', textAlign: TextAlign.center),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final haberler = snapshot.data!;
          return ListView.builder(
            itemCount: haberler.length,
            itemBuilder: (context, index) {
              final haber = haberler[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(haber.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      haber.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                    tooltip: 'AI ile İçerik Oluştur',
                    onPressed: () {
                      _summarizeAndShowPopup(haber);
                    },
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('Gösterilecek haber bulunamadı.'));
        }
      },
    );
  }
}