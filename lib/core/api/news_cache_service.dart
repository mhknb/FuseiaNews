import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';

class NewsCacheService {
  static const String _cacheKey = 'cached_global_news';
  static const String _cacheTimestampKey = 'cached_global_news_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 10); // Cache 10 dakika geçerli

  Future<void> cacheNews(List<HaberModel> news) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = news.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<HaberModel>?> getCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_cacheTimestampKey);

    if (timestamp != null) {
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        final List<String>? jsonList = prefs.getStringList(_cacheKey);
        if (jsonList != null) {
          return jsonList.map((json) => HaberModel.fromJson(jsonDecode(json))).toList();
        }
      } else {
        // Cache süresi doldu, temizle
        await prefs.remove(_cacheKey);
        await prefs.remove(_cacheTimestampKey);
      }
    }
    return null;
  }
}
