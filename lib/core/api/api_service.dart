import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/news_model.dart';
import '../utilis/constants.dart';
import 'youtube_service.dart';



class ApiService {
  final YoutubeService _youtubeService = YoutubeService();

  /// Global haber akışı için haberleri çeker.
  Future<List<HaberModel>> fetchGlobalNews() {

    return _fetchNewsFromUrl(kGlobalNewsUrl, 'BBC Teknoloji');
  }

  /// Kullanıcının seçtiği ve eklediği tüm kişisel kaynaklardan (RSS ve YouTube) haberleri çeker.
  Future<List<HaberModel>> fetchPersonalizedNews() async {
    final prefs = await SharedPreferences.getInstance();



   final String? customSourcesJson = prefs.getString('user_custom_sources');
    final List<dynamic> customRssList = (customSourcesJson != null && customSourcesJson.isNotEmpty)
        ? jsonDecode(customSourcesJson)
        : [];


    final customYoutubeUrls = prefs.getStringList('youtube_channels') ?? [];

    if (customRssList.isEmpty && customYoutubeUrls.isEmpty) {
      return []; // Takip edilen hiçbir kaynak yoksa boş liste döndür.
    }


    List<Future<List<HaberModel>>> futures = [];

   for (var source in customRssList) {
      if (source is Map<String, dynamic> && source.containsKey('name') && source.containsKey('url')) {
        final String name = source['name'];
        final String url = source['url'];
        futures.add(_fetchNewsFromUrl(url, name));
      }
    }

   if (customYoutubeUrls.isNotEmpty) {
      futures.add(_youtubeService.fetchAllTrackedChannelVideos());
    }

   final results = await Future.wait(futures);
    List<HaberModel> allPersonalizedNews = results.expand((list) => list).toList();
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


      if (responseBody.trim().contains('<feed')) {
        var feed = AtomFeed.parse(responseBody);
        newsList = feed.items?.map((item) {
          String? imageUrl;
          if (item.media?.thumbnails != null && item.media!.thumbnails!.isNotEmpty) {
            imageUrl = item.media!.thumbnails!.first.url;
          }
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
      }
      else if (responseBody.trim().contains('<rss')) {
        var feed = RssFeed.parse(responseBody);
        newsList = feed.items?.map((item) {
          String? imageUrl;
          if (item.media?.contents != null && item.media!.contents!.isNotEmpty) {
            imageUrl = item.media!.contents!.first.url;
          } else if (item.media?.thumbnails != null && item.media!.thumbnails!.isNotEmpty) {
            imageUrl = item.media!.thumbnails!.first.url;
          } else if (item.enclosure?.url != null) {
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
      return [];
    }
  }

  /// Bir kaynak için ikon URL'si bulan yardımcı fonksiyon.
  String? _getIconUrl(String itemLink, String? feedIconUrl) {
    if (feedIconUrl != null && feedIconUrl.isNotEmpty) return feedIconUrl;
    final uri = Uri.tryParse(itemLink);
    return uri != null ? 'https://www.google.com/s2/favicons?sz=64&domain_url=${uri.host}' : null;
  }
}