import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiApiService {
  GenerativeModel? _model;





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




  Future<String?> summarizeText(String textToSummarize) async {
    final model = await _initializeModel();
    if (model == null) return "Lütfen ayarlardan geçerli bir API anahtarı girin.";

    try {
      final prompt = 'Aşağıdaki metni, ana fikrini koruyarak 2-3 cümlelik akıcı bir Türkçe ile özetle:\n\n"$textToSummarize"';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      print("Gemini Özetleme Hatası: $e");
      return "Özetleme sırasında bir API hatası oluştu.";
    }
  }

  Future<String?> createInstagramPost(String rawContent) async {
    final model = await _initializeModel();
    if (model == null) return "Lütfen ayarlardan geçerli bir API anahtarı girin.";

    try {
      final prompt = '''
      Aşağıdaki haber metninden yola çıkarak, Instagram için dikkat çekici, 
      akıcı ve genç bir dille bir gönderi metni oluştur. 
      Metnin başına kalın harflerle (Markdown formatında **Başlık** şeklinde) çarpıcı bir başlık ekle. 
      Metnin içinde konuyla alakalı 2-3 tane emoji kullan. 
      Sonuna da 4-5 tane popüler ve konuyla ilgili İngilizce ve Türkçe hashtag ekle.

      Haber Metni: "$rawContent"
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      print('Gemini Post Oluşturma Hatası: $e');
      return 'Post metni oluşturulurken bir API hatası oluştu.';
    }
  }

  Future<String?> translateToTurkish(String textToTranslate) async {
    if (textToTranslate.length < 15 || textToTranslate.contains(RegExp(r'[çğıöşüÇĞİÖŞÜ]'))) {
      return textToTranslate;
    }

    final model = await _initializeModel();
    if (model == null) return textToTranslate;
    try {
      final prompt = 'Translate the following English text to natural, fluent Turkish:\n\n"$textToTranslate"';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? textToTranslate;
    } catch (e) {
      print("Gemini Çeviri Hatası: $e");
      return textToTranslate;
    }
  }
}