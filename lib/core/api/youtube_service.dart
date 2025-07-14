// lib/services/youtube_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/news_model.dart';

class YoutubeService {
  final _yt = YoutubeExplode();

  //--- Bu fonksiyon dışarıdan çağrılacak ---
  Future<List<HaberModel>> fetchVideosFromSingleChannel(String channelUrl) async {
    List<HaberModel> videoList = [];
    try {
      final channelId = ChannelId.fromString(channelUrl);
      var uploads = await _yt.channels.getUploads(channelId).toList();
      var channel = await _yt.channels.get(channelId);

      for (var video in uploads.take(15)) {
        videoList.add(HaberModel(
          title: video.title,
          link: video.url,
          description: channel.title,
          pubDate: video.uploadDate,
          isYoutubeVideo: true,
          videoId: video.id.value,
          thumbnailUrl: video.thumbnails.highResUrl,
        ));
      }
    } catch (e) {
      print("YouTube kanalı işlenirken hata ($channelUrl): $e");
    }
    return videoList;
  }

  //--- Bu fonksiyon, YouTube sekmesi için kullanılacak ---
  Future<List<HaberModel>> fetchAllTrackedChannelVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final channelUrls = prefs.getStringList('youtube_channels') ?? [];

    if (channelUrls.isEmpty) return [];

    List<Future<List<HaberModel>>> futures = [];
    for (final url in channelUrls) {
      // Yukarıdaki fonksiyonu yeniden kullanıyoruz
      futures.add(fetchVideosFromSingleChannel(url));
    }

    final results = await Future.wait(futures);
    final allVideos = results.expand((list) => list).toList();

    allVideos.sort((a, b) {
      if(a.pubDate == null || b.pubDate == null) return 0;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allVideos;
  }
}