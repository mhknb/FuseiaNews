class HaberModel {
  String title;
  String description;

  final String link;
  final DateTime? pubDate;
  final bool isYoutubeVideo;
  final String? videoId;
  final String? thumbnailUrl;
  final String sourceName;
  final String? sourceIconUrl;

  HaberModel({
    required this.title,
    required this.link,
    required this.description,
    this.pubDate,
    this.isYoutubeVideo = false,
    this.videoId,
    this.thumbnailUrl,
    required this.sourceName,
    this.sourceIconUrl,
  });
}