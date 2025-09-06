  import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/news_model.dart';
import '../utilis/constants.dart';
import 'youtube_service.dart';
import 'news_cache_service.dart';



class ApiService {
  final YoutubeService _youtubeService = YoutubeService();
  final NewsCacheService _cacheService = NewsCacheService();


  // İlgi alanı -> RSS kaynak listesi (Global akış bu listelerden beslenir)
  final Map<String, List<String>> _interestToRssListMap = {
    'Bilim': [
      'https://arkeofili.com/feed/',
      'https://bilimvegelecek.com.tr/index.php/feed/',
      'https://www.bilimoloji.com/feed/',
      'https://www.bilimup.com/rss.xml',
      'https://www.tarihlibilim.com/feed/',
      'https://www.fizikist.com/feed',
      'https://www.gercekbilim.com/feed/',
      'https://gelecekbilimde.net/feed/',
      'https://www.herkesebilimteknoloji.com/feed',
      'https://www.matematiksel.org/feed',
      'https://moletik.com/feed/',
      'https://popsci.com.tr/feed/',
      'https://sarkac.org/feed/',
    ],
    'Teknoloji': [
      'https://www.dijitalx.com/feed/',
      'https://www.chip.com.tr/rss',
      'https://www.donanimhaber.com/rss/tum/',
      'https://www.donanimgunlugu.com/feed/',
      'https://www.log.com.tr/feed/',
      'https://www.megabayt.com/rss/news',
      'https://www.pchocasi.com.tr/feed/',
      'https://www.technopat.net/feed/',
      'http://www.teknoblog.com/feed/',
      'https://www.teknolojioku.com/export/rss',
      'https://www.teknoburada.net/feed/',
      'http://feeds.feedburner.com/tamindir/stream',
      'https://webrazzi.com/feed/',
      'https://t24.com.tr/rss/bilim-teknoloji-haberleri',
      'https://www.sabah.com.tr/rss/teknoloji.xml',
      'https://www.haberturk.com/rss/kategori/teknoloji.xml',
      'https://www.ntv.com.tr/teknoloji.rss',
      'http://www.star.com.tr/rss/teknoloji.xml',
    ],
    'Gündem': [
      'https://www.ahaber.com.tr/rss/gundem.xml',
      'https://www.aa.com.tr/tr/rss/default?cat=guncel',
      'https://feeds.bbci.co.uk/turkce/rss.xml',
      'https://www.cnnturk.com/feed/rss/all/news',
      'http://www.cumhuriyet.com.tr/rss/son_dakika.xml',
      'https://www.haberturk.com/rss',
      'http://www.hurriyet.com.tr/rss/anasayfa',
      'https://www.ntv.com.tr/gundem.rss',
      'https://www.sabah.com.tr/rss/gundem.xml',
      'https://www.sozcu.com.tr/feeds-rss-category-sozcu',
      'https://www.star.com.tr/rss/rss.asp',
      'https://t24.com.tr/rss',
      'https://www.trthaber.com/sondakika.rss',
      'https://www.yeniakit.com.tr/rss/haber/gundem',
      'https://www.yenisafak.com/rss?xml=gundem',
      'https://t24.com.tr/rss/dunya-haberleri',
      'http://www.cumhuriyet.com.tr/rss/17.xml',
      'https://www.sabah.com.tr/rss/dunya.xml',
      'http://www.star.com.tr/rss/dunya.xml',
    ],
    'Spor': [
      'https://www.aspor.com.tr/rss',
      'https://www.fotomac.com.tr/rss/anasayfa.xml',
      'https://www.ntvspor.net/rss/',
      'https://www.sozcu.com.tr/feeds-rss-category-spor',
      'https://www.spormaraton.com/rss/',
      'https://t24.com.tr/rss/spor-haberleri',
      'http://www.cumhuriyet.com.tr/rss/32.xml',
      'https://www.haberturk.com/rss/spor.xml',
      'https://www.sabah.com.tr/rss/spor.xml',
      'http://www.star.com.tr/rss/spor.xml',
      'https://www.fotomac.com.tr/rss/futbol/super-lig.xml',
      'https://www.fotomac.com.tr/rss/futbol/besiktas.xml',
      'https://www.fotomac.com.tr/rss/futbol/fenerbahce.xml',
      'https://www.fotomac.com.tr/rss/futbol/galatasaray.xml',
      'https://www.fotomac.com.tr/rss/basketbol.xml',
    ],
    'Eğlence': [
      'https://www.atarita.com/feed/',
      'https://bigumigu.com/feed/',
      'https://www.bilimkurgukulubu.com/feed/',
      'https://frpnet.net/feed',
      'https://geekyapar.com/feed/',
      'https://kayiprihtim.com/feed/',
      'https://listelist.com/feed/',
      'http://www.thegeyik.com/feed/',
      'https://www.turkmmo.com/feed',
      'https://www.turunculevye.com/feed/',
      'https://www.campaigntr.com/feed/',
      'http://www.cumhuriyet.com.tr/rss/33.xml',
      'http://www.star.com.tr/rss/magazin.xml',
      'http://www.star.com.tr/rss/sinema.xml',
      'http://www.star.com.tr/rss/sanat.xml',
      'https://t24.com.tr/rss/kultur-sanat-haberleri',
    ],
    'Yaşam': [
      'https://www.istanbullife.com/feed/',
      'https://www.megabayt.com/yasam/rss',
      'https://medium.com/feed/@turkce',
      'https://uplifers.com/feed/',
      'https://www.sabah.com.tr/rss/yasam.xml',
      'https://www.ntv.com.tr/yasam.rss',
    ],
    'Finans': [
      'http://bigpara.hurriyet.com.tr/rss/',
      'https://www.dunya.com/rss?dunya',
      'https://tr.investing.com/rss/',
      'https://www.sozcu.com.tr/feeds-rss-category-ekonomi',
      'https://t24.com.tr/rss/ekonomi-haberleri',
      'http://www.cumhuriyet.com.tr/rss/24.xml',
      'https://www.haberturk.com/rss/ekonomi.xml',
      'https://www.sabah.com.tr/rss/ekonomi.xml',
      'http://www.star.com.tr/rss/ekonomi.xml',
      'https://www.ntv.com.tr/ekonomi.rss',
    ],
    // Yedek: tekli kaynaklarla çalışan kategoriler
    'Yapay Zeka': [
      'https://www.technologyreview.com/feed/',
      'https://solveria.art/rss.xml',
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
  Future<List<HaberModel>> fetchGlobalNews({bool forceRefresh = false}) async {
    print('🔍 fetchGlobalNews başladı - forceRefresh: $forceRefresh');
    
    // Check cache first unless force refresh is requested
    if (!forceRefresh) {
      final cachedNews = await _cacheService.getCachedGlobalNews();
      if (cachedNews != null && cachedNews.isNotEmpty) {
        print('✅ Cache\'den ${cachedNews.length} haber döndürüldü');
        return cachedNews;
      }
      print('❌ Cache\'de haber bulunamadı');
    }

    List<Future<List<HaberModel>>> futures = [];

    // TÜM kategorilerden RSS kaynaklarını al (global akış)
    int totalUrls = 0;
    for (final entry in _interestToRssListMap.entries) {
      final category = entry.key;
      final urls = entry.value;
      print('📂 $category kategorisinden ${urls.length} RSS kaynağı');
      totalUrls += urls.length;
      
      for (final url in urls) {
        final detectedCategory = _getCategoryForUrl(url);
        futures.add(_fetchNewsFromUrl(url, detectedCategory));
      }
    }
    print('🔗 Toplam $totalUrls RSS kaynağı işlenecek');

    // YouTube kanallarından da haberleri çek
    futures.add(_youtubeService.fetchAllTrackedChannelVideos());

    // Tüm haberleri paralel olarak çek (hata toleranslı)
    final results = await Future.wait(futures.map((future) => 
      future.catchError((error) {
        print('⚠️ RSS kaynağı hatası: $error');
        return <HaberModel>[];
      })
    ));
    List<HaberModel> allNews = results.expand((list) => list).toList();

    // Tarihe göre sırala (en yeni önce)
    allNews.sort((a, b) => b.pubDate?.compareTo(a.pubDate ?? DateTime(0)) ?? 0);

    print('🎯 Toplam ${allNews.length} haber toplandı');

    // Cache the results for future use
    await _cacheService.cacheGlobalNews(allNews);
    print('💾 Haberler cache\'e kaydedildi');

    return allNews;
  }

  /// URL için kategori adını bul
  String _getCategoryForUrl(String url) {
    for (final entry in _interestToRssListMap.entries) {
      if (entry.value.contains(url)) {
        return entry.key;
      }
    }
    return 'Genel';
  }

  /// Kullanıcının seçtiği kategorilerden ve eklediği özel kaynaklardan haberleri çeker.
  Future<List<HaberModel>> fetchPersonalizedNews({bool forceRefresh = false}) async {
    print('🔍 fetchPersonalizedNews başladı - forceRefresh: $forceRefresh');
    
    // Cache'den haberleri kontrol et (forceRefresh false ise)
    if (!forceRefresh) {
      final cachedNews = await _cacheService.getCachedPersonalizedNews();
      if (cachedNews != null && cachedNews.isNotEmpty) {
        print('✅ Cache\'den ${cachedNews.length} kişiselleştirilmiş haber döndürüldü');
        return cachedNews;
      } else {
        print('❌ Cache\'de kişiselleştirilmiş haber bulunamadı');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final userInterests = prefs.getStringList('user_interests') ?? [];
    
    List<Future<List<HaberModel>>> futures = [];

    // 1. Kullanıcının seçtiği kategorilerden haberleri çek
    if (userInterests.isNotEmpty) {
      List<String> categoryUrls = [];
      for (String interest in userInterests) {
        final urls = _interestToRssListMap[interest];
        if (urls != null && urls.isNotEmpty) {
          // Her kategoriden maksimum 5 kaynak al
          categoryUrls.addAll(urls.take(5));
        }
      }
      
      // Kategori haberlerini paralel olarak çek
      for (String url in categoryUrls) {
        final category = _getCategoryForUrl(url);
        futures.add(_fetchNewsFromUrl(url, category));
      }
    }

    // 2. Kullanıcının manuel olarak eklediği özel kaynakları çek
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

    for (var source in customRssList) {
      if (source is Map<String, dynamic> && source.containsKey('name') && source.containsKey('url')) {
        final String name = source['name'];
        final String url = source['url'];
        futures.add(_fetchNewsFromUrl(url, name));
      }
    }

    // 3. YouTube kanallarından haberleri çek
    final customYoutubeUrls = prefs.getStringList('youtube_channels') ?? [];
    if (customYoutubeUrls.isNotEmpty) {
      futures.add(_youtubeService.fetchAllTrackedChannelVideos());
    }

    // Eğer hiçbir kaynak yoksa boş liste döndür
    if (futures.isEmpty) {
      print('❌ Kişiselleştirilmiş akış için kaynak bulunamadı');
      return [];
    }

    // Tüm haberleri paralel olarak çek (hata toleranslı)
    final results = await Future.wait(futures.map((future) => 
      future.catchError((error) {
        print('⚠️ Kişiselleştirilmiş RSS kaynağı hatası: $error');
        return <HaberModel>[];
      })
    ));
    List<HaberModel> allPersonalizedNews = results.expand((list) => list).toList();
    
    // Tarihe göre sırala (en yeni önce)
    allPersonalizedNews.sort((a, b) {
      if (a.pubDate == null || b.pubDate == null) return 0;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    print('🎯 Toplam ${allPersonalizedNews.length} kişiselleştirilmiş haber toplandı');

    // Cache the results for future use
    await _cacheService.cachePersonalizedNews(allPersonalizedNews);
    print('💾 Kişiselleştirilmiş haberler cache\'e kaydedildi');

    return allPersonalizedNews;
  }

  /// Verilen bir URL'den RSS veya Atom beslemesini çeker ve HaberModel listesine dönüştürür.
  Future<List<HaberModel>> _fetchNewsFromUrl(String url, String sourceName) async {
    try {
      print('📡 RSS/Atom fetch başladı: $url');
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
      };
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        print('❌ HTTP hatası: ${response.statusCode} - $url');
        throw Exception('Feed yüklenemedi. Kod: ${response.statusCode}');
      }

      final responseBody = utf8.decode(response.bodyBytes);
      print('✅ RSS/Atom yüklendi: ${responseBody.length} karakter - $url');
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
            websiteName: _getWebsiteName(url),
            sourceIconUrl: _getIconUrl(item.links?.first.href ?? url, feed.logo),
            imageUrl: imageUrl,
            category: _getCategoryForUrl(url),
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
            websiteName: _getWebsiteName(url),
            sourceIconUrl: _getIconUrl(item.link ?? url, feed.image?.url),
            imageUrl: imageUrl,
            category: _getCategoryForUrl(url),
          );
        }).toList() ?? [];
      } else {
        print('❌ Geçersiz format: $url');
        throw Exception('Geçerli bir RSS veya Atom formatı değil.');
      }
      print('✅ ${newsList.length} haber parse edildi: $url');
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

  /// URL'den website adını çıkarır
  String _getWebsiteName(String url) {
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      
      // www. prefix'ini kaldır
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      
      // Domain adından site ismini çıkar
      final Map<String, String> domainToName = {
        // Bilim kategorisi
        'arkeofili.com': 'Arkeofili',
        'bilimvegelecek.com.tr': 'Bilim ve Gelecek',
        'bilimoloji.com': 'Bilimoloji',
        'bilimup.com': 'Bilimup',
        'tarihlibilim.com': 'Tarihli Bilim',
        'fizikist.com': 'Fizikist',
        'gercekbilim.com': 'Gerçek Bilim',
        'gelecekbilimde.net': 'Gelecek Bilimde',
        'herkesebilimteknoloji.com': 'Herkese Bilim Teknoloji',
        'matematiksel.org': 'Matematiksel',
        'moletik.com': 'Moletik',
        'popsci.com.tr': 'Popular Science',
        'sarkac.org': 'Sarkaç',
        
        // Teknoloji kategorisi
        'dijitalx.com': 'DijitalX',
        'chip.com.tr': 'CHIP Online',
        'donanimhaber.com': 'Donanım Haber',
        'donanimgunlugu.com': 'Donanım Günlüğü',
        'log.com.tr': 'LOG',
        'megabayt.com': 'Megabayt',
        'pchocasi.com.tr': 'PC Hocası',
        'technopat.net': 'Technopat',
        'teknoblog.com': 'Teknoblog',
        'teknolojioku.com': 'Teknolojioku',
        'teknoburada.net': 'TeknoBurada',
        'tamindir.com': 'Tam İndir',
        'webrazzi.com': 'Webrazzi',
        't24.com.tr': 'T24',
        'sabah.com.tr': 'Sabah',
        'haberturk.com': 'Habertürk',
        'ntv.com.tr': 'NTV',
        'star.com.tr': 'Star',
        
        // Haberler & Güncel Olaylar
        'ahaber.com.tr': 'A Haber',
        'aa.com.tr': 'Anadolu Ajansı',
        'bbci.co.uk': 'BBC Türkçe',
        'cnnturk.com': 'CNN Türk',
        'cumhuriyet.com.tr': 'Cumhuriyet',
        'hurriyet.com.tr': 'Hürriyet',
        'sozcu.com.tr': 'Sözcü',
        'trthaber.com': 'TRT Haber',
        'yeniakit.com.tr': 'Yeni Akit',
        'yenisafak.com': 'Yeni Şafak',
        
        // Spor kategorisi
        'aspor.com.tr': 'A Spor',
        'fotomac.com.tr': 'Fotomaç',
        'ntvspor.net': 'NTV Spor',
        'spormaraton.com': 'Spor Maraton',
        
        // Eğlence kategorisi
        'atarita.com': 'Atarita',
        'bigumigu.com': 'Bigumigu',
        'bilimkurgukulubu.com': 'Bilimkurgu Kulübü',
        'frpnet.net': 'FRPNET',
        'geekyapar.com': 'Geekyapar',
        'kayiprihtim.com': 'Kayıp Rıhtım',
        'listelist.com': 'ListeList',
        'thegeyik.com': 'The Geyik',
        'turkmmo.com': 'Turkmmo',
        'turunculevye.com': 'Turuncu Levye',
        'campaigntr.com': 'Campaign Türkiye',
        
        // Yaşam kategorisi
        'istanbullife.com': 'İstanbul Life',
        'medium.com': 'Medium Türkçe',
        'uplifers.com': 'Uplifers',
        
        // Ekonomi & Finans
        'bigpara.hurriyet.com.tr': 'Bigpara',
        'dunya.com': 'Dünya',
        'investing.com': 'Investing',
        
        // Eski kaynaklar (geriye dönük uyumluluk için)
        'bilimteknik.tubitak.gov.tr': 'Bilim Teknik',
        'bilimgunlugu.com': 'Bilim Günlüğü',
        'populerbildim.com': 'Popüler Bilim',
        'fanatik.com.tr': 'Fanatik',
        'trtspor.com.tr': 'TRT Spor',
        'sporx.com': 'Sporx',
        'gazeteduvar.com.tr': 'Gazete Duvar',
        'birgun.net': 'BirGün',
        'ekonomist.com.tr': 'Ekonomist',
        'bloomberght.com': 'Bloomberg HT',
        'beyazperde.com': 'Beyazperde',
        'arkitera.com': 'Arkitera',
        'sanathaber.com': 'Sanat Haber',
        'kulturservisi.com': 'Kültür Servisi',
        'edebiyathaber.net': 'Edebiyat Haber',
        'muzehaberleri.com': 'Müze Haberleri',
        'technologyreview.com': 'MIT Technology Review',
        'edsurge.com': 'EdSurge',
        'gamespot.com': 'GameSpot',
      };
      
      return domainToName[host] ?? host.split('.')[0].toUpperCase();
    } catch (e) {
      return 'Bilinmeyen Kaynak';
    }
  }
}