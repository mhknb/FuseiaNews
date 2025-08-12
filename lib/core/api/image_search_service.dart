// lib/core/api/image_search_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageSearchService {
  static const String _baseUrl = 'https://api.pexels.com/v1/';
  final String? _apiKey = dotenv.env['PEXELS_API_KEY'];

  /// Verilen bir anahtar kelime ile ilgili bir görselin URL'sini arar ve bulur.
  Future<String?> searchImageByKeyword(String keyword) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print("HATA: Pexels API anahtarı .env dosyasında bulunamadı.");
      return null; // Anahtar yoksa hiç deneme
    }

    // Pexels, arama için en az 3 harf gerektirir.
    if (keyword.length < 3) {
      return null;
    }

    final url = Uri.parse('${_baseUrl}search?query=$keyword&per_page=1');
    final headers = {'Authorization': _apiKey!};

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Eğer arama sonucu fotoğraf içeriyorsa
        if (data['photos'] != null && data['photos'].isNotEmpty) {
          // İlk fotoğrafın, 'large' boyutundaki URL'sini geri döndür.
          // Diğer boyutlar: 'original', 'medium', 'small', 'portrait', 'landscape', 'tiny'
          return data['photos'][0]['src']['large'];
        }
        // Eğer arama sonucu boşsa
        return null;
      } else {
        print("Pexels API Hatası: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Pexels Bağlantı Hatası: $e");
      return null;
    }
  }
}