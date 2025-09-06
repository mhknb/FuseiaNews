import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';

class NewsCacheService {
  static const String _globalCacheKey = 'cached_global_news';
  static const String _globalCacheTimestampKey = 'cached_global_news_timestamp';
  static const String _personalizedCacheKey = 'cached_personalized_news';
  static const String _personalizedCacheTimestampKey = 'cached_personalized_news_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 10); // Cache 10 dakika geçerli

  // Global haberler için cache
  Future<void> cacheGlobalNews(List<HaberModel> news) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = news.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_globalCacheKey, jsonList);
    await prefs.setInt(_globalCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<HaberModel>?> getCachedGlobalNews() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_globalCacheTimestampKey);

    if (timestamp != null) {
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        final List<String>? jsonList = prefs.getStringList(_globalCacheKey);
        if (jsonList != null) {
          return jsonList.map((json) => HaberModel.fromJson(jsonDecode(json))).toList();
        }
      } else {
        // Cache süresi doldu, temizle
        await prefs.remove(_globalCacheKey);
        await prefs.remove(_globalCacheTimestampKey);
      }
    }
    return null;
  }

  // Kişiselleştirilmiş haberler için cache
  Future<void> cachePersonalizedNews(List<HaberModel> news) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = news.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_personalizedCacheKey, jsonList);
    await prefs.setInt(_personalizedCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<HaberModel>?> getCachedPersonalizedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_personalizedCacheTimestampKey);

    if (timestamp != null) {
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        final List<String>? jsonList = prefs.getStringList(_personalizedCacheKey);
        if (jsonList != null) {
          return jsonList.map((json) => HaberModel.fromJson(jsonDecode(json))).toList();
        }
      } else {
        // Cache süresi doldu, temizle
        await prefs.remove(_personalizedCacheKey);
        await prefs.remove(_personalizedCacheTimestampKey);
      }
    }
    return null;
  }

  // Geriye uyumluluk için eski metodlar
  Future<void> cacheNews(List<HaberModel> news) async {
    await cacheGlobalNews(news);
  }

  Future<List<HaberModel>?> getCachedNews() async {
    return await getCachedGlobalNews();
  }
}
