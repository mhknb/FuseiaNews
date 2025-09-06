// lib/core/api/image_search_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageSearchService {
  static const String _baseUrl = 'https://api.pexels.com/v1/';
  
  String? get _apiKey {
    try {
      return dotenv.env['PEXELS_API_KEY'];
    } catch (e) {
      return null;
    }
  }

  /// Verilen bir anahtar kelime ile ilgili bir görselin URL'sini arar ve bulur.
  Future<String?> searchImageByKeyword(String keyword) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return null; // Anahtar yoksa hiç deneme
    }

   if (keyword.length < 10) {
      return null;
    }

    final url = Uri.parse('${_baseUrl}search?query=$keyword&per_page=1');
    final headers = {'Authorization': _apiKey!};

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['photos'] != null && data['photos'].isNotEmpty) {
       return data['photos'][0]['src']['large'];
        }
         return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}