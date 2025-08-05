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
    return _callGenerativeApi(
        'Aşağıdaki metni, ana fikrini koruyarak 2-3 cümlelik akıcı bir Türkçe ile özetle:\n\n"$textToSummarize"',
        "Özetleme"
    );
  }

  Future<String?> createInstagramPost(String rawContent) async {
    return _callGenerativeApi(
        '''
      Aşağıdaki haber metninden yola çıkarak, Instagram için dikkat çekici...
      Haber Metni: "$rawContent"
      ''',
        "Post Oluşturma"
    );
  }

  Future<String?> translateToTurkish(String textToTranslate) async {
    if (textToTranslate.length < 15 || textToTranslate.contains(RegExp(r'[çğıöşüÇĞİÖŞÜ]'))) {
      return textToTranslate;
    }

    final result = await _callGenerativeApi(
        'Translate the following English text to natural, fluent Turkish:\n\n"$textToTranslate"',
        "Çeviri"
    );
    return result ?? textToTranslate;
  }

  Future<String?> _callGenerativeApi(String prompt, String taskName, {int retries = 3}) async {
    final model = await _initializeModel();
    if (model == null) return "API Anahtarı bulunamadı.";

    int attempt = 0;
    while (attempt < retries) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text;
      } on GenerativeAIException catch (e) {
        if (e.message.contains('overloaded') || e.message.contains('503')) {
          attempt++;
          if (attempt >= retries) {
            print("Gemini $taskName Hatası: Model aşırı yüklendi, deneme limitine ulaşıldı.");
            return null;
          }

          final delay = Duration(seconds: 1 << (attempt - 1));
          print("Gemini $taskName Hatası: Model meşgul. $delay sonra tekrar denenecek... ($attempt/$retries)");
          await Future.delayed(delay);
        } else {
          print("Gemini $taskName Hatası (Tekrar Denenmeyecek): $e");
          return null; // veya bir hata mesajı
        }
      } catch (e) {
        print("Genel $taskName Hatası: $e");
        return null;
      }
    }
    return null;
  }
}