// lib/services/rss_service.dart

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/webfeed_plus.dart'; // webfeed_plus'ı import ediyoruz
import '../models/news_model.dart';
import 'youtube_service.dart'; // Yeni YouTube servisimizi import ediyoruz

class RssService {
  final YoutubeService _youtubeService = YoutubeService();

  // Artık sadece RSS linklerini tutuyoruz.
  final Map<String, String> _interestToRssMap = {
    'Teknoloji': 'http://feeds.bbci.co.uk/news/technology/rss.xml',
    'Bilim': 'http://feeds.bbci.co.uk/news/science_and_environment/rss.xml',
    'Sağlık': 'http://feeds.bbci.co.uk/news/health/rss.xml',
    'Spor': 'https://feeds.skynews.com/feeds/rss/sports.xml',
    'Gündem': 'http://feeds.bbci.co.uk/news/rss.xml',
    //buraya eklenecek unutma
  };




  Future<List<HaberModel>> fetchGlobalNews() {
    return _fetchNewsFromUrl('http://feeds.bbci.co.uk/news/technology/rss.xml');
  }


  Future<List<HaberModel>> _fetchNewsFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Feed yüklenemedi. Kod: ${response.statusCode}');
      }

      var feed = RssFeed.parse(response.body);

      return feed.items?.map((rssItem) {

        String descriptionText;


        if (rssItem.description != null) {
          // HTML etiketlerini ve özel karakterleri temizlememize yarıyor
          final regex = RegExp(r'<[^>]*>|&[^;]+;');
          descriptionText = rssItem.description!.replaceAll(regex, '');
        } else {
          descriptionText = 'Açıklama Yok';
        }

        return HaberModel(
          title: rssItem.title ?? 'Başlık Yok',
          link: rssItem.link ?? 'Link Yok',
          description: descriptionText,
          pubDate: rssItem.pubDate,
          isYoutubeVideo: false,
        );
      }).toList() ?? [];

    } catch (e) {
      print("Hata: _fetchNewsFromUrl($url) - $e");
      throw Exception('Haberler çekilirken bir sorun oluştu: $e');
    }
  }
}