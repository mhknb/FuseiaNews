import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/news_model.dart';
import 'gemini_api_service.dart';

class YoutubeService {
  final _yt = YoutubeExplode();
  final _geminiService = GeminiApiService();

  /// Ayarlar'da takip edilen tüm YouTube kanallarından en son videoları çeker.
  Future<List<HaberModel>> fetchAllTrackedChannelVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final channelUrls = prefs.getStringList('youtube_channels') ?? [];
    if (channelUrls.isEmpty) {
      _yt.close();
      return [];
    }

    List<Future<List<HaberModel>>> futures = [];
    for (final url in channelUrls) {
      futures.add(_fetchAndSummarizeVideosFromChannel(url));
    }

    final results = await Future.wait(futures);
    final allVideos = results.expand((list) => list).toList();

    allVideos.sort((a, b) {
      if (a.pubDate == null || b.pubDate == null) return 0;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    _yt.close();
    return allVideos;
  }

  /// Tek bir standart YouTube kanal URL'sinden son 3 videoyu çeker ve özetler.
  Future<List<HaberModel>> _fetchAndSummarizeVideosFromChannel(String channelUrl) async {
    List<HaberModel> videoList = [];
    try {
      final channelId = ChannelId.fromString(channelUrl);
      var channel = await _yt.channels.get(channelId);

     var uploads = await _yt.channels.getUploads(channelId);

     await for (var video in uploads) {
        if (videoList.length >= 3) {
          break;
        }

       final fullVideo = await _yt.videos.get(video.id);

      if (fullVideo.duration != null && fullVideo.duration!.inSeconds <= 61) {
          print("Shorts videosu atlandı: ${fullVideo.title}");
          continue;
      }


        final description = fullVideo.description;
        final summary = await _geminiService.summarizeText(description);

        videoList.add(HaberModel(
          title: video.title,
          link: video.url,
          description: summary ?? 'Bu video için özet oluşturulamadı.',
          pubDate: video.uploadDate,
          isYoutubeVideo: true,
          videoId: video.id.value,
          thumbnailUrl: video.thumbnails.highResUrl,
          sourceName: channel.title,
          sourceIconUrl: channel.logoUrl,
        ));

        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print("YouTube kanalı işlenirken veya özetlenirken hata ($channelUrl): $e");
    }
    return videoList;
  }
}