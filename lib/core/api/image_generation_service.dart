import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageGenerationService {
  static const String _pythonApiUrl = 'http://10.0.2.2:5000/process-image';
  static const String _imageSourceUrl = 'https://picsum.photos/512';

  Future<Uint8List?> processImageWithPython(Uint8List rawImageBytes, String title) async {
    try {
      print("Python backend'e istek gönderiliyor...");

      var request = http.MultipartRequest('POST', Uri.parse(_pythonApiUrl));
      // Metin verisi
      request.fields['title'] = title;

      // Dosya verisi
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        rawImageBytes,
        filename: 'image.png',
      ));

      // İsteği gönderdiğim yer
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("İşlenmiş görsel Python'dan başarıyla alındı!");
        // Gelen cevap doğrudan resmin byte'ları olacak
        return response.bodyBytes;
      } else {
        print("Python backend hatası: ${response.statusCode}");
        print("Hata Mesajı: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Python backend'e bağlanırken hata: $e");
      return null;
    }
  }

  Future<Uint8List?> generateAndProcessImage(String title) async {
    // 1. Önce ham görseli picsum'dan alalım
    try {
      final rawImageResponse = await http.get(Uri.parse(_imageSourceUrl));
      if (rawImageResponse.statusCode == 200) {
        return await processImageWithPython(rawImageResponse.bodyBytes, title);
      } else {
        print("Picsum'dan görsel alınamadı.");
        return null;
      }
    } catch (e) {
      print("Ham görsel alınırken hata: $e");
      return null;
    }
  }
}