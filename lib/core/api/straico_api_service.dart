// lib/core/api/openai_api_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIApiService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  final String? _apiKey = dotenv.env['OPENAI_API_KEY']; // .env içinde E2- ile başlayan key

  static const String translationModel = 'gpt-4o-mini';
  static const String creativeModel = 'gpt-4o';

  Future<String?> _callOpenAIApi({
    required String model,
    required String prompt,
    required String taskName,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print("HATA: OpenAI API anahtarı .env dosyasında bulunamadı.");
      return "OpenAI API anahtarı ayarlanmamış.";
    }

    final url = Uri.parse('$_baseUrl/chat/completions');

    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedResponse['choices'][0]['message']['content'];
      } else {
        print("OpenAI $taskName Hatası: ${response.statusCode} - ${response.body}");
        return "$taskName sırasında bir API hatası oluştu.";
      }
    } catch (e) {
      print("OpenAI $taskName Bağlantı Hatası: $e");
      return "$taskName sırasında bir bağlantı hatası oluştu.";
    }
  }

  // --- Fonksiyonlar ---
  Future<String?> summarizeText(String textToSummarize) {
    final prompt = 'Aşağıdaki metni, ana fikrini koruyarak 2-3 cümlelik akıcı bir Türkçe ile özetle:\n\n"$textToSummarize"';
    return _callOpenAIApi(model: creativeModel, prompt: prompt, taskName: "Özetleme");
  }

  Future<String?> createInstagramPost(String content) {
    final prompt = '''
    Aşağıdaki içerikten yola çıkarak, Instagram için dikkat çekici ve akıcı bir gönderi metni oluştur.
    Metnin başına kalın harflerle (Markdown formatında **Başlık** şeklinde) çarpıcı bir başlık ekle.
    Metnin içinde konuyla alakalı 2-3 tane emoji kullan.
    Sonuna da 4-5 tane popüler ve ilgili hashtag ekle.
    İçerik: "$content"
    ''';
    return _callOpenAIApi(model: creativeModel, prompt: prompt, taskName: "Post Oluşturma");
  }

  Future<String?> translateToTurkish(String textToTranslate) {
    if (textToTranslate.length < 15 || textToTranslate.contains(RegExp(r'[çğıöşüÇĞİÖŞÜ]'))) {
      return Future.value(textToTranslate);
    }
    final prompt = '''
    Act as a direct translator. Translate the following English text to Turkish.
    Provide ONLY the Turkish translation, without any extra text or explanations.
    English Text: """$textToTranslate"""
    Turkish Translation:
    ''';
    return _callOpenAIApi(model: translationModel, prompt: prompt, taskName: "Çeviri");
  }
}
