class HaberModel {
  String title;
  String description;

  final String link;
  final DateTime? pubDate;
  final bool isYoutubeVideo;
  final String? videoId;
  final String? thumbnailUrl;
  final String sourceName;
  final String? websiteName;
  final String? sourceIconUrl;
  final String? imageUrl;
  final String category;

  HaberModel({
    required this.title,
    required this.link,
    required this.description,
    this.pubDate,
    this.isYoutubeVideo = false,
    this.videoId,
    this.thumbnailUrl,
    required this.sourceName,
    this.websiteName,
    this.sourceIconUrl,
    this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'link': link,
    'pubDate': pubDate?.toIso8601String(),
    'isYoutubeVideo': isYoutubeVideo,
    'videoId': videoId,
    'thumbnailUrl': thumbnailUrl,
    'sourceName': sourceName,
    'websiteName': websiteName,
    'sourceIconUrl': sourceIconUrl,
    'imageUrl': imageUrl,
    'category': category,
  };

  factory HaberModel.fromJson(Map<String, dynamic> json) => HaberModel(
    title: json['title'] as String,
    description: json['description'] as String,
    link: json['link'] as String,
    pubDate: json['pubDate'] != null ? DateTime.parse(json['pubDate'] as String) : null,
    isYoutubeVideo: json['isYoutubeVideo'] as bool? ?? false,
    videoId: json['videoId'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    sourceName: json['sourceName'] as String,
    websiteName: json['websiteName'] as String?,
    sourceIconUrl: json['sourceIconUrl'] as String?,
    imageUrl: json['imageUrl'] as String?,
    category: json['category'] as String? ?? 'Genel',
  );
}