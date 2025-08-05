import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PythonApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  Future<Uint8List?> createPostWithTemplate({
    required Uint8List rawImageBytes,
    required String title,
    required String content,
  }) async {
      final url = Uri.parse('$_baseUrl/create-post-image');
    try {
      print("Python backend'ine istek gönderiliyor: $url");
      var request = http.MultipartRequest('POST', url);
      request.fields['title'] = title;
      request.fields['content'] = content;
      request.files.add(http.MultipartFile.fromBytes(
        'background_image',
        rawImageBytes,
        filename: 'background.png',
      ));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        print("Şablonlu görsel Python'dan başarıyla alındı!");
        return response.bodyBytes;
      } else {
        print("Python backend hatası oluştu. Durum Kodu: ${response.statusCode}");
        print("Hata Mesajı: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Python backend'e bağlanırken hata: $e");
      return null;
    }
  }
}