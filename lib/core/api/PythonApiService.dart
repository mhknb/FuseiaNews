// lib/core/api/python_api_service.dart

import 'dart:typed_data'; // Byte verileri için
import 'package:http/http.dart' as http;

class PythonApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  Future<Uint8List?> processImageWithPython(Uint8List rawImageBytes, String title) async {
    final url = Uri.parse('$_baseUrl/process-image');

    try {
      print("Python backend'ine istek gönderiliyor: $url");
      var request = http.MultipartRequest('POST', url);
      request.fields['title'] = title;

      request.files.add(http.MultipartFile.fromBytes(
        'image', // 'image' anahtarı, Python'da `request.files['image']` ile yakaladığımız anahtarla aynı olmalı.
        rawImageBytes,
        filename: 'image_to_process.png', // Sunucu tarafında dosya adı önemli değil ama belirtmek iyi bir pratiktir.
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("İşlenmiş görsel Python'dan başarıyla alındı!");
        return response.bodyBytes;
      } else {
        print("Python backend hatası oluştu. Durum Kodu: ${response.statusCode}");
        print("Hata Mesajı: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Python backend'e bağlanırken bir hata oluştu: $e");
      return null;
    }
  }
}