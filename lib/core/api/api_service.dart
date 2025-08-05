








import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/domain/atom_feed.dart';
import 'package:webfeed_plus/domain/rss_feed.dart';

import '../models/news_model.dart';
import '../utilis/constants.dart';

class ApiService {


  /// Global haber akışı için haberleri çeker.
  Future<List<HaberModel>> fetchGlobalNews() {
    // kGlobalNewsUrl, constants.dart dosyasından gelen sabit bir URL'dir.
    return _fetchNewsFromUrl(kGlobalNewsUrl, 'BBC Teknoloji');
  }

  /// Kullanıcının seçtiği ve eklediği tüm kişisel kaynaklardan haberleri çeker.
  Future<List<HaberModel>> fetchPersonalizedNews() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Kullanıcının Ayarlar'dan manuel olarak eklediği özel RSS kaynaklarını al
    final String? customSourcesJson = prefs.getString('user_custom_sources');
    final List<dynamic> customRssList = (customSourcesJson != null && customSourcesJson.isNotEmpty)
        ? jsonDecode(customSourcesJson)
        : [];

    // 2. Kullanıcının Ayarlar'dan manuel olarak eklediği YouTube kanallarını al
    final customYoutubeUrls = prefs.getStringList('youtube_channels') ?? [];

    if (customRssList.isEmpty && customYoutubeUrls.isEmpty) {
      return []; // Takip edilen hiçbir kaynak yoksa boş liste döndür.
    }

    List<Future<List<HaberModel>>> futures = [];

    // Her bir özel RSS kaynağı için haber çekme işlemini başlat
    for (var source in customRssList) {
      if (source is Map<String, dynamic> && source.containsKey('name') && source.containsKey('url')) {
        final String name = source['name'];
        final String url = source['url'];
        futures.add(_fetchNewsFromUrl(url, name));
      }
    }

    // Her bir özel YouTube kanalı için video çekme işlemini başlat
    for (String youtubeUrl in customYoutubeUrls) {

    }

    // Tüm işlemlerin bitmesini bekle
    final results = await Future.wait(futures);
    // Gelen tüm listeleri tek bir büyük listeye birleştir
    List<HaberModel> allPersonalizedNews = results.expand((list) => list).toList();

    // Haberleri tarihe göre en yeniden en eskiye sırala
    allPersonalizedNews.sort((a, b) {
      if (a.pubDate == null || b.pubDate == null) return 0;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allPersonalizedNews;
  }

  /// Verilen bir URL'den RSS veya Atom beslemesini çeker ve HaberModel listesine dönüştürür.
  Future<List<HaberModel>> _fetchNewsFromUrl(String url, String sourceName) async {
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
      };
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Feed yüklenemedi. Kod: ${response.statusCode}');
      }

      final responseBody = utf8.decode(response.bodyBytes);
      List<HaberModel> newsList = [];

      // Gelen verinin formatını kontrol et
      if (responseBody.trim().contains('<feed')) {
        // --- ATOM FORMATI İŞLEME ---
        var feed = AtomFeed.parse(responseBody);
        newsList = feed.items?.map((item) {

          // Atom için görsel arama mantığı
          String? imageUrl;
          if (item.media?.thumbnails != null && item.media!.thumbnails!.isNotEmpty) {
            imageUrl = item.media!.thumbnails!.first.url;
          }

          // Atom'daki açıklamalar genellikle temizdir, yine de kontrol edelim.
          final description = (item.summary ?? item.content ?? 'Açıklama Yok').replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

          return HaberModel(
            title: item.title ?? 'Başlık Yok',
            link: item.links?.first.href ?? 'Link Yok',
            description: description,
            pubDate: item.updated,
            isYoutubeVideo: false,
            sourceName: sourceName,
            sourceIconUrl: _getIconUrl(item.links?.first.href ?? url, feed.logo),
            imageUrl: imageUrl,
          );
        }).toList() ?? [];

      } else if (responseBody.trim().contains('<rss')) {
        // --- RSS FORMATI İŞLEME ---
        var feed = RssFeed.parse(responseBody);
        newsList = feed.items?.map((item) {

          // RSS için görsel arama mantığı (3 adımlı)
          String? imageUrl;
          // 1. Öncelik: <media:content> (Yüksek kaliteli, ana görsel)
          if (item.media?.contents != null && item.media!.contents!.isNotEmpty) {
            imageUrl = item.media!.contents!.first.url;
          }
          // 2. Öncelik: <media:thumbnail> (BBC'nin kullandığı küçük resim)
          else if (item.media?.thumbnails != null && item.media!.thumbnails!.isNotEmpty) {
            imageUrl = item.media!.thumbnails!.first.url;
          }
          // 3. Öncelik: <enclosure> (Genellikle podcast veya eski sitelerde)
          else if (item.enclosure?.url != null) {
            imageUrl = item.enclosure!.url;
          }

          String descriptionText = item.description?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim() ?? 'Açıklama Yok';

          return HaberModel(
            title: item.title ?? 'Başlık Yok',
            link: item.link ?? 'Link Yok',
            description: descriptionText,
            pubDate: item.pubDate,
            isYoutubeVideo: false,
            sourceName: sourceName,
            sourceIconUrl: _getIconUrl(item.link ?? url, feed.image?.url),
            imageUrl: imageUrl,
          );
        }).toList() ?? [];
      } else {
        throw Exception('Geçerli bir RSS veya Atom formatı değil.');
      }
      return newsList;

    } catch (e) {
      print("HATA: Bu URL işlenemedi -> $url. Hata Detayı: $e");
      // Hata durumunda boş liste döndürmek, 'Sana Özel' akışındaki diğer
      // kaynakların yüklenmeye devam etmesini sağlar.
      return [];
    }
  }

// _getIconUrl fonksiyonu (Bu fonksiyon sınıf içinde kalmalı)
  String? _getIconUrl(String itemLink, String? feedIconUrl) {
    if (feedIconUrl != null && feedIconUrl.isNotEmpty) return feedIconUrl;
    final uri = Uri.tryParse(itemLink);
    return uri != null ? 'https://www.google.com/s2/favicons?sz=64&domain_url=${uri.host}' : null;
  }

}