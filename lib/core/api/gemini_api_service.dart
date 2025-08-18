// lib/core/api/gemini_api_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiApiService {
  GenerativeModel? _model;

  // Modeli sadece ihtiyaç duyulduğunda bir kere başlatan private fonksiyon
  Future<GenerativeModel?> _initializeModel() async {
    if (_model != null) return _model;

    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('user_api_key');

    if (apiKey == null || apiKey.isEmpty) {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    }

    if (apiKey == null || apiKey.isEmpty) {
      print("HATA: Gemini API anahtarı ne ayarlarda ne de .env dosyasında bulunamadı.");
      return null;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
    return _model;
  }

  // Hataları ve yeniden deneme mantığını yöneten merkezi fonksiyon
  Future<String?> _callGenerativeApi(String prompt, String taskName, {int retries = 3}) async {
    final model = await _initializeModel();
    if (model == null) return "API Anahtarı bulunamadı veya geçersiz.";

    int attempt = 0;
    while (attempt < retries) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text;
      } on GenerativeAIException catch (e) {
        // Sunucu meşgul veya kota aşıldı gibi geçici hatalar için
        if (e.message.contains('overloaded') || e.message.contains('503') || e.message.contains('quota')) {
          attempt++;
          if (attempt >= retries) {
            print("Gemini $taskName Hatası: Model aşırı yüklendi veya kota aşıldı, deneme limitine ulaşıldı.");
            return "API şu an çok yoğun, lütfen daha sonra tekrar deneyin.";
          }
          final delay = Duration(seconds: 2 << (attempt - 1)); // 2s, 4s, 8s bekle
          print("Gemini $taskName Hatası: Model meşgul. $delay sonra tekrar denenecek... ($attempt/$retries)");
          await Future.delayed(delay);
        } else {
          // Başka bir Gemini hatası ise, tekrar deneme.
          print("Gemini $taskName Hatası (Tekrar Denenmeyecek): $e");
          return "Yapay zeka modelinde bir hata oluştu: ${e.message}";
        }
      } catch (e) {
        print("Genel $taskName Hatası: $e");
        return "İşlem sırasında genel bir hata oluştu.";
      }
    }
    return null;
  }



  Future<String?> summarizeText(String textToSummarize) {
    final prompt = 'Aşağıdaki metni, ana fikrini koruyarak 2-3 cümlelik akıcı bir Türkçe ile özetle:\n\n"$textToSummarize"';
    return _callGenerativeApi(prompt, "Özetleme");
  }

  Future<String?> createInstagramPost(String content) {
    final prompt = '''
    Aşağıdaki içerikten yola çıkarak, Instagram için dikkat çekici ve akıcı bir gönderi metni oluştur.
    Metnin başına kalın harflerle (Markdown formatında **Başlık** şeklinde) çarpıcı bir başlık ekle.
    Metnin içinde konuyla alakalı 2-3 tane emoji kullan.
    Sonuna da 4-5 tane popüler ve ilgili hashtag ekle.
    İçerik: "$content"
    ''';
    return _callGenerativeApi(prompt, "Post Oluşturma");
  }

  Future<String?> translateToTurkish(String textToTranslate) async {
    if (textToTranslate.length < 15 || textToTranslate.contains(RegExp(r'[çğıöşüÇĞİÖŞÜ]'))) {
      return textToTranslate;
    }
    final prompt = '''
    Act as a direct translator. Translate the following English text to Turkish.
    Provide ONLY the Turkish translation, without any extra text or explanations.
    English Text: """$textToTranslate"""
    Turkish Translation:
    ''';
    final result = await _callGenerativeApi(prompt, "Çeviri");
    return result ?? textToTranslate;
  }
}