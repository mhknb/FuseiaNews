import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/youtube_service.dart';
import '../../../core/models/news_model.dart';
import '../../04_settings/screens/settings_screen.dart';

class YoutubeFeedScreen extends StatefulWidget {
  const YoutubeFeedScreen({super.key});

  @override
  State<YoutubeFeedScreen> createState() => _YoutubeFeedScreenState();
}

class _YoutubeFeedScreenState extends State<YoutubeFeedScreen> {
  final YoutubeService _youtubeService = YoutubeService();
  late Future<List<HaberModel>> _videosFuture;
  String _loadingStatus = 'YouTube kanalları taranıyor...';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _videosFuture = _youtubeService.fetchAllTrackedChannelVideos();
    });
  }

  /// Verilen bir URL'yi (YouTube videosu) harici bir uygulamada açar.
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$url açılamadı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HaberModel>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_loadingStatus),
              ],
            ),
          );
        }

        else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Hata: ${snapshot.error}', textAlign: TextAlign.center),
            ),
          );
        }

        else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz YouTube kanalı takip etmiyorsunuz.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ayarlar menüsünden favori kanallarınızı ekleyerek başlayın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Ayarları Aç'),
                    onPressed: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) => _fetchData());
                    },
                  ),
                ],
              ),
            ),
          );
        }
        else if (snapshot.hasData) {
          final videos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _fetchData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: videos.length,
              itemBuilder: (context, index) {
               return _buildYoutubeVideoCard(videos[index]);
              },
            ),
          );
        }
        return const Center(child: Text('Bilinmeyen bir hata oluştu.'));
      },
    );
  }

  /// YouTube videoları için özel tasarlanmış kart widget'ı
  Widget _buildYoutubeVideoCard(HaberModel video) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _launchURL(video.link),
        child: Column(
          children: [
            if (video.thumbnailUrl != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnailUrl!,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox(height: 210, child: Center(child: CircularProgressIndicator())),
                    errorBuilder: (c, e, s) =>
                    const SizedBox(height: 210, child: Icon(Icons.error, color: Colors.grey)),
                  ),
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white.withOpacity(0.85), size: 60),
                ],
              ),
           /// Video başlığı, kanal logosu ve AI özeti
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (video.sourceIconUrl != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(video.sourceIconUrl!),
                          backgroundColor: Colors.grey[800],
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          video.sourceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}