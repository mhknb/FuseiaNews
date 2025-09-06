// lib/core/api/gemini_api_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiService {
  GenerativeModel? _model;
  String? _lastApiKeyUsed;

  // API key artık environment variable'dan alınacak
  static const String kDefaultGeminiModel = 'models/gemini-2.0-flash-lite';

  // Modeli sadece ihtiyaç duyulduğunda bir kere başlatan private fonksiyon
  Future<GenerativeModel?> _initializeModel() async {
    final prefs = await SharedPreferences.getInstance();
    final bool useOwnApiKey = prefs.getBool('use_own_api_key') ?? false;
    
    String selectedApiKey = '';
    if (useOwnApiKey) {
      selectedApiKey = prefs.getString('user_api_key') ?? '';
    } else {
      // Environment variable'dan API key al
      selectedApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    }

    if (selectedApiKey.isEmpty) {
      return null;
    }

    if (_model != null && _lastApiKeyUsed == selectedApiKey) return _model;

    _model = GenerativeModel(
      model: kDefaultGeminiModel,
      apiKey: selectedApiKey,
    );
    _lastApiKeyUsed = selectedApiKey;
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
        if (e.message.contains('overloaded') || e.message.contains('503') || e.message.contains('quota')) {
          attempt++;
          if (attempt >= retries) {
            return "API şu an çok yoğun, lütfen daha sonra tekrar deneyin.";
          }
          final delay = Duration(seconds: 2 << (attempt - 1)); // 2s, 4s, 8s bekle
          await Future.delayed(delay);
        } else {
          return "Yapay zeka modelinde bir hata oluştu: ${e.message}";
        }
      } catch (e) {
        return "İşlem sırasında genel bir hata oluştu.";
      }
    }
    return null;
  }



  Future<String?> summarizeText(String textToSummarize) {
    final prompt = 'Aşağıdaki haber metnindeki içeriği, ana fikrini koruyarak 2-3 cümlelik akıcı bir Türkçe ile özetle:\n\n"$textToSummarize"';
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