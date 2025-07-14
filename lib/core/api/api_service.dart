// lib/services/rss_service.dart

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/webfeed_plus.dart'; // webfeed_plus'ı import ediyoruz
import '../models/news_model.dart';
import '../utilis/constants.dart';
import 'youtube_service.dart'; // Yeni YouTube servisimizi import ediyoruz

class RssService {
  final YoutubeService _youtubeService = YoutubeService();






  Future<List<HaberModel>> fetchGlobalNews() {
    // Artık URL'yi doğrudan yazmıyoruz, sabit dosyasından çekiyoruz.
    return _fetchNewsFromUrl(kGlobalNewsUrl);
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

  Future<List<HaberModel>> fetchPersonalizedNews() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Kullanıcının kaydettiği dinamik RSS linklerini al
    // Ayarlar ekranında 'user_rss_sources' gibi bir anahtarla kaydettiğimizi varsayalım
    final userRssUrls = prefs.getStringList('user_rss_sources') ?? [];

    // 2. Kullanıcının kaydettiği dinamik YouTube kanallarını al
    // Bu zaten 'youtube_channels' anahtarıyla kaydediliyor
    final userYoutubeUrls = prefs.getStringList('youtube_channels') ?? [];

    // Eğer kullanıcı hiçbir şey eklemediyse, boş liste döndür
    if (userRssUrls.isEmpty && userYoutubeUrls.isEmpty) {
      return [];
    }

    // Tüm asenkron işlemleri tutacak bir liste
    List<Future<List<HaberModel>>> futures = [];

    // 3. Her bir dinamik RSS linki için haber çekme işlemini başlat
    for (String rssUrl in userRssUrls) {
      futures.add(_fetchNewsFromUrl(rssUrl));
    }

    // 4. Her bir dinamik YouTube kanalı için video çekme işlemini başlat
    for (String youtubeUrl in userYoutubeUrls) {
      futures.add(_youtubeService.fetchVideosFromSingleChannel(youtubeUrl));
    }

    // 5. Tüm işlemlerin bitmesini bekle ve sonuçları birleştir
    final results = await Future.wait(futures);
    List<HaberModel> allPersonalizedNews = results.expand((list) => list).toList();

    // Son olarak tarihe göre sırala
    allPersonalizedNews.sort((a, b) {
      if (a.pubDate == null || b.pubDate == null) return 0;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allPersonalizedNews;
  }
}