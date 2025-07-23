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
      // --- YENİ VE DAHA NET PROMPT ---
      // Yapay zekaya tam olarak ne yapması gerektiğini ve ne yapmaması gerektiğini söylüyoruz.
      final prompt = '''
      Your task is to act as a direct translator.
      Translate the following English text into Turkish.
      Provide ONLY the raw Turkish translation.
      DO NOT add any extra text, explanations, options, titles, or formatting like "**".

      English Text:
      """
     $rawContent
      """

      Turkish Translation:
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