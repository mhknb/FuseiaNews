// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {

  Future<GenerativeModel?> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('user_api_key');

    if (apiKey == null || apiKey.isEmpty) {
      print("HATA: Kullanıcı API anahtarı bulunamadı.");
      return null;
    }

    return GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
  }

  Future<String?> summarizeText(String textToSummarize) async {
    final model = await _getModel();
    if (model == null) return "Lütfen ayarlardan API anahtarınızı girin.";

    try {
      final prompt = '...';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      return "API Hatası: $e";
    }
  }



  Future<String?> createInstagramPost(String summary) async {

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('user_api_key');


    if (apiKey == null || apiKey.isEmpty) {

      print("HATA: Gemini API anahtarı bulunamadı. Lütfen ayarlardan girin.");
      return "Lütfen önce Ayarlar menüsünden API anahtarınızı girin.";
    }


    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );

      final prompt = '''
    Aşağıdaki haber özetinden yola çıkarak, Instagram için dikkat çekici, 
    akıcı ve genç bir dille bir gönderi metni oluştur. 
    Metnin başına kalın harflerle (Markdown formatında **Başlık** şeklinde) çarpıcı bir başlık ekle. 
    Metnin içinde konuyla alakalı 2-3 tane emoji kullan. 
    Sonuna da 4-5 tane popüler ve konuyla ilgili İngilizce ve Türkçe hashtag ekle.

    Özet Metin: "$summary"
    ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;

    } catch (e) {
      print('--- GEMINI API (POST) HATASI ---');
      print('Hata: $e');
      print('------------------------------');
      return 'Post metni oluşturulurken bir API hatası oluştu. Detaylar konsolda.';
    }
  }
}