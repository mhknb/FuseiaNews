  import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/news_model.dart';
import '../utilis/constants.dart';
import 'youtube_service.dart';



class ApiService {
  final YoutubeService _youtubeService = YoutubeService();


  // İlgi alanı -> RSS kaynak listesi (Global akış bu listelerden beslenir)
  final Map<String, List<String>> _interestToRssListMap = {
    'Teknoloji': [
      'https://www.donanimhaber.com/rss.xml',
      'https://webrazzi.com/feed/',
      'https://www.teknoblog.com/feed/',
      'https://shiftdelete.net/feed',
      'https://www.webtekno.com/rss.xml',
      'https://www.chip.com.tr/rss.xml',
    ],
    'Bilim': [
      'https://bilimvegelecek.com.tr/rss.xml',
      'https://bilimteknik.tubitak.gov.tr/rss.xml',
      'https://www.bilimgunlugu.com/rss.xml',
      'https://www.populerbildim.com/rss.xml',
    ],
    'Spor': [
      'https://www.aspor.com.tr/rss.xml',
      'https://www.ntvspor.net/rss',
      'https://www.fotomac.com.tr/rss.xml',
      'https://www.fanatik.com.tr/rss.xml',
      'https://www.trtspor.com.tr/rss.xml',
      'https://www.sporx.com/rss.xml',
    ],
    'Gündem': [
      'https://www.aa.com.tr/tr/rss/default?cat=guncel',
      'https://www.ntv.com.tr/gundem.rss',
      'https://www.cnnturk.com/feed/rss/all/news',
      'https://www.sozcu.com.tr/rss.xml',
      'http://www.cumhuriyet.com.tr/rss/son_dakika.xml',
      'https://i12.haber7.net/rss/sondakika.xml',
      'https://www.milliyet.com.tr/rss/rssNew/gundemRss.xml',
      'https://www.sabah.com.tr/rss/gundem.xml',
      'https://www.haberturk.com/rss/kategori/gundem.xml',
      'https://t24.com.tr/rss',
      'https://www.gazeteduvar.com.tr/rss.xml',
      'https://www.birgun.net/rss',
    ],
    'Finans': [
      'https://www.haberturk.com/rss/kategori/ekonomi.xml',
      'https://www.aa.com.tr/tr/rss/default?cat=ekonomi',
      'https://tr.investing.com/rss/news.rss',
      'https://www.dunya.com/rss',
      'https://www.ekonomist.com.tr/rss.xml',
      'https://www.bloomberght.com/rss',
    ],
    'Sinema': [
      'https://www.beyazperde.com/rss/haberler.xml',
      'https://www.haberturk.com/rss/kategori/magazin.xml',
      'https://www.milliyet.com.tr/rss/rssNew/magazinRss.xml',
      'https://www.hurriyet.com.tr/rss/magazin',
    ],
    'Kültür & Sanat': [
      'https://www.arkitera.com/rss.xml',
      'https://sanathaber.com/rss.xml',
      'https://kulturservisi.com/rss.xml',
      'https://www.edebiyathaber.net/rss.xml',
      'https://muzehaberleri.com/rss.xml',
    ],
    // Yedek: tekli kaynaklarla çalışan kategoriler
    'Yapay Zeka': [
      'https://www.technologyreview.com/feed/',
    ],
    'Eğitim': [
      'https://www.edsurge.com/news/rss',
    ],
    'Oyun': [
      'https://www.gamespot.com/feeds/news/',
    ],
    'Sağlık': [
      'http://feeds.bbci.co.uk/news/health/rss.xml',
    ],
  };

  /// Global haber akışı için haberleri çeker.
  Future<List<HaberModel>> fetchGlobalNews() async {
    final prefs = await SharedPreferences.getInstance();
   final userInterests = prefs.getStringList('user_interests') ?? [];

    if (userInterests.isEmpty) {
      // Varsayılan: Gündem kategorisindeki tüm kaynaklardan çek
      final defaultUrls = _interestToRssListMap['Gündem'] ?? [];
      final futures = defaultUrls.map((url) => _fetchNewsFromUrl(url, 'Gündem'));
      final results = await Future.wait(futures);
      final allNews = results.expand((list) => list).toList();
      allNews.sort((a, b) => b.pubDate?.compareTo(a.pubDate ?? DateTime(0)) ?? 0);
      return allNews;
    }

    List<Future<List<HaberModel>>> futures = [];

    for (String interest in userInterests) {
      final urls = _interestToRssListMap[interest];
      if (urls != null && urls.isNotEmpty) {
        for (final url in urls) {
          futures.add(_fetchNewsFromUrl(url, interest));
        }
      }
    }

    final results = await Future.wait(futures);
    List<HaberModel> allNews = results.expand((list) => list).toList();
    allNews.sort((a, b) => b.pubDate?.compareTo(a.pubDate ?? DateTime(0)) ?? 0);

    return allNews;
  }

  /// Kullanıcının seçtiği ve eklediği tüm kişisel kaynaklardan (RSS ve YouTube) haberleri çeker.
  Future<List<HaberModel>> fetchPersonalizedNews() async {
    final prefs = await SharedPreferences.getInstance();



   final String? customSourcesJson = prefs.getString('user_custom_sources');
    List<dynamic> customRssList = (customSourcesJson != null && customSourcesJson.isNotEmpty)
        ? jsonDecode(customSourcesJson)
        : [];

    // Kişisel kaynaklar içinde global akışın varsayılan URL'leri varsa filtrele (yanlış kaydedilmiş olabilir)
    final Set<String> defaultGlobalUrls = _interestToRssListMap.values.expand((e) => e).toSet();
    customRssList = customRssList.where((source) {
      if (source is Map<String, dynamic> && source.containsKey('url')) {
        final String url = source['url'];
        return !defaultGlobalUrls.contains(url);
      }
      return true;
    }).toList();


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