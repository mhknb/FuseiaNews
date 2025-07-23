
import 'dart:convert';


import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/webfeed_plus.dart'; // webfeed_plus'ı import ediyoruz
import '../models/news_model.dart';
import '../utilis/constants.dart';

class RssService {






  Future<List<HaberModel>> fetchPersonalizedNews() async {
    final prefs = await SharedPreferences.getInstance();

    final String? savedSourcesJson = prefs.getString('user_selected_sources_map');

    final userYoutubeUrls = prefs.getStringList('youtube_channels') ?? [];

    Map<String, String> userSelectedSources = {};
    if (savedSourcesJson != null && savedSourcesJson.isNotEmpty) {
      userSelectedSources = Map<String, String>.from(jsonDecode(savedSourcesJson));
    }

    if (userSelectedSources.isEmpty && userYoutubeUrls.isEmpty) {
      return [];
    }

    List<Future<List<HaberModel>>> futures = [];

    userSelectedSources.forEach((name, url) {
      futures.add(_fetchNewsFromUrl(url, name));
    });


    for (String youtubeUrl in userYoutubeUrls) {
    }

    final results = await Future.wait(futures);
    List<HaberModel> allPersonalizedNews = results.expand((list) => list).toList();

    allPersonalizedNews.sort((a, b) {
      if (a.pubDate == null || b.pubDate == null) return 0;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allPersonalizedNews;
  }


  Future<List<HaberModel>> _fetchNewsFromUrl(String url, String sourceName) async {
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
      };
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Feed yüklenemedi. Kod: ${response.statusCode}');
      }

      final responseBody = utf8.decode(response.bodyBytes);
      List<HaberModel> newsList = [];

      // --- YENİ VE DAHA SAĞLAM KONTROL ---
      // Metnin içinde '<feed' kelimesi geçiyor mu?
      if (responseBody.contains('<feed')) {
        // Evet, bu bir Atom beslemesi.
        print("Bilgi: Atom beslemesi algılandı -> $url");
        var feed = AtomFeed.parse(responseBody);
        newsList = feed.items?.map((atomItem) {
          final iconUrl = _getIconUrl(atomItem.links?.first.href ?? url, feed.logo);

          return HaberModel(
            title: atomItem.title ?? 'Başlık Yok',
            link: atomItem.links?.first.href ?? 'Link Yok',
            description: atomItem.summary ?? atomItem.content ?? 'Açıklama Yok',
            pubDate: atomItem.updated,
            isYoutubeVideo: false,
            sourceName: sourceName,
            sourceIconUrl: iconUrl,
          );
        }).toList() ?? [];

      }
      // Metnin içinde '<rss' kelimesi geçiyor mu?
      else if (responseBody.contains('<rss')) {
        // Evet, bu bir RSS beslemesi.
        print("Bilgi: RSS beslemesi algılandı -> $url");
        var feed = RssFeed.parse(responseBody);
        newsList = feed.items?.map((rssItem) {
          final iconUrl = _getIconUrl(rssItem.link ?? url, feed.image?.url);
          String descriptionText = rssItem.description?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim() ?? 'Açıklama Yok';

          return HaberModel(
            title: rssItem.title ?? 'Başlık Yok',
            link: rssItem.link ?? 'Link Yok',
            description: descriptionText,
            pubDate: rssItem.pubDate,
            isYoutubeVideo: false,
            sourceName: sourceName,
            sourceIconUrl: iconUrl,
          );
        }).toList() ?? [];
      } else {
        // Ne RSS ne de Atom. Bu bir hata.
        throw Exception('Gelen veri geçerli bir RSS veya Atom formatında değil.');
      }
      return newsList;

    } catch (e) {
      print("HATA AYIKLAMA: Bu URL işlenemedi -> $url");
      print("Hata Detayı: $e");
      throw Exception('\'$sourceName\' kaynağı yüklenemedi.');
    }
  }
  String? _getIconUrl(String itemLink, String? feedIconUrl) {
    if (feedIconUrl != null && feedIconUrl.isNotEmpty) return feedIconUrl;
    final uri = Uri.tryParse(itemLink);
    return uri != null ? 'https://www.google.com/s2/favicons?sz=64&domain_url=${uri.host}' : null;
  }

  Future<List<HaberModel>> fetchGlobalNews() {
    return _fetchNewsFromUrl(kGlobalNewsUrl, 'BBC Teknolojisimi acaba');
  }


}