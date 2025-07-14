// lib/features/03_feeds/screens/private_screen.dart (veya personalized_feed_screen.dart)

import 'dart:typed_data';
import 'dart:io'; // Dosya işlemleri için
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Geçici dizin için
import 'package:share_plus/share_plus.dart'; // Paylaşım için

// Kendi dosyalarını import et (dosya yollarını kontrol et)
import '../../../core/api/api_service.dart';
import '../../../core/api/gemini_api_service.dart';

import '../../../core/models/news_model.dart';
import '../../../core/sevices/python_api_service.dart';
import '../../01_setup/screens/interest_selection_screen.dart';
import '../../04_settings/screens/settings_screen.dart';


class PrivateScreen extends StatefulWidget {
  const PrivateScreen({super.key});

  @override
  State<PrivateScreen> createState() => _PrivateScreenState();
}

class _PrivateScreenState extends State<PrivateScreen> {
  // Servis isimlerini dosya isimlerinle eşleştirdim
  final  RssService _apiService = RssService();
  final GeminiService _geminiService = GeminiService();
  final PythonApiService _pythonApiService = PythonApiService();
  late Future<List<HaberModel>> _haberlerFuture;

  @override
  void initState() {
    super.initState();
    _haberlerFuture = _apiService.fetchPersonalizedNews();
  }

  // --- YENİ EKLENEN PAYLAŞIM FONKSİYONU BURADA ---
  Future<void> _sharePost(Uint8List imageBytes, String postText) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/image_to_share.png').create();
      await file.writeAsBytes(imageBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');

      await Share.shareXFiles(
        [xFile],
        text: postText,
        subject: 'AI ContentFlow ile Oluşturuldu!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım sırasında bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _summarizeAndShowPopup(HaberModel haber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final summary = await _geminiService.summarizeText(haber.description);
    if (!mounted) return;
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("İçerikler Üretiliyor..."),
          ]),
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
        finalImageBytes = await _pythonApiService.processImageWithPython(
          rawImageResponse.bodyBytes,
          title,
        );
      } else {
        throw Exception('Ham görsel alınamadı. Durum Kodu: ${rawImageResponse.statusCode}');
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            icon: const Icon(Icons.share),
            label: const Text('Instagramda Paylaş'),
            // --- DÜZELTME BURADA ---
            onPressed: () {
              if (finalImageBytes != null && postText != null) {
                // YAZDIĞIMIZ YENİ FONKSİYONU ÇAĞIRIYORUZ
                _sharePost(finalImageBytes, postText);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paylaşılacak içerik bulunamadı!')),
                );
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
        }
        else if (snapshot.hasData && snapshot.data!.isEmpty) {
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
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden Dene'),
                    onPressed: () {
                      setState(() {
                        _haberlerFuture = _apiService.fetchPersonalizedNews();
                      });
                    },
                  ),
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
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(haber.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(haber.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                    tooltip: 'AI ile İçerik Oluştur',
                    onPressed: () => _summarizeAndShowPopup(haber),
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('Bilinmeyen bir hata oluştu.'));
        }
      },
    );
  }
}