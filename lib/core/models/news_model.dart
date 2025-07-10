class HaberModel {
  final String title;
  final String link;
  final String description;
  final DateTime? pubDate;

  // YENİ ALANLAR
  final bool isYoutubeVideo; // Bu bir video mu?
  final String? videoId; // Video ID'si (örn: d_s8w9_y7Jg)
  final String? thumbnailUrl; // Küçük resmin URL'si

  HaberModel({
    required this.title,
    required this.link,
    required this.description,
    this.pubDate,
    this.isYoutubeVideo = false, // Varsayılan olarak false
    this.videoId,
    this.thumbnailUrl,
  });
}