import 'package:flutter/material.dart';
import '../../../core/models/news_model.dart';

class NewsListItem extends StatelessWidget {
  final HaberModel haber;
  final VoidCallback onTap;

  const NewsListItem({super.key, required this.haber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkImage = haber.imageUrl != null && haber.imageUrl!.isNotEmpty;
    final Color secondaryText = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    // Kart yüksekliği ve görsel genişliği
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = screenWidth >= 380 ? 148 : 136;
    final double imageWidth = (screenWidth * 0.32).clamp(110.0, 150.0);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sol: tam yükseklik görsel (kare değil)
            _EdgeImage(
              networkUrl: hasNetworkImage ? haber.imageUrl! : null,
              assetPath: _categoryAssetPath(haber.sourceName),
              width: imageWidth,
              radius: 16,
            ),

            // Sağ içerik
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Başlık + açıklama
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          haber.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            fontSize: 17,
                          ),
                        ),
                        if (haber.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            haber.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Meta satırı
                    Row(
                      children: [
                        Icon(Icons.public, size: 12, color: secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${haber.websiteName ?? haber.sourceName} · ${_formatDate(haber.pubDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    try {
      return date.toString().split(' ').first;
    } catch (_) {
      return '';
    }
  }

  String _categoryAssetPath(String category) {
    String n = category.toLowerCase();
    n = n
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    n = n.replaceAll(RegExp(r"[^a-z0-9]+"), '_');
    n = n.replaceAll(RegExp(r"_+"), '_').replaceAll(RegExp(r"^_|_$"), '');

    // Explicit mappings
    const Map<String, String> direct = {
      'teknoloji_haberleri': 'teknoloji.jpg',
      'teknoloji': 'teknoloji.jpg',
      'bilim': 'bilim.jpg',
      'egitim': 'egitim.jpg',
      'yapay_zeka': 'yz.jpg',
      'yz': 'yz.jpg',
      'finans': 'finans.jpg',
      'gundem': 'gundem.jpg',
      'oyun': 'oyun.jpg',
      'saglik': 'saglik.jpg',
      'sinema': 'sinema.jpg',
    };

    if (direct.containsKey(n)) {
      return 'assets/images/${direct[n]!}';
    }

    // Contains-based fallbacks
    if (n.contains('teknoloji')) return 'assets/images/teknoloji.jpg';
    if (n.contains('yapay') || n.contains('zeka')) return 'assets/images/yz.jpg';
    if (n.contains('saglik')) return 'assets/images/saglik.jpg';
    if (n.contains('bilim')) return 'assets/images/bilim.jpg';
    if (n.contains('egitim')) return 'assets/images/egitim.jpg';
    if (n.contains('finans') || n.contains('ekonomi')) return 'assets/images/finans.jpg';
    if (n.contains('gundem') || n.contains('haber')) return 'assets/images/gundem.jpg';
    if (n.contains('oyun') || n.contains('gaming')) return 'assets/images/oyun.jpg';
    if (n.contains('sinema') || n.contains('film')) return 'assets/images/sinema.jpg';

    return 'assets/images/default.jpg';
  }
}

class _EdgeImage extends StatelessWidget {
  final String? networkUrl;
  final String assetPath;
  final double width;
  final double radius;
  const _EdgeImage({required this.networkUrl, required this.assetPath, required this.width, required this.radius});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    Widget imageWidget;
    if (networkUrl != null) {
      imageWidget = Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            color: bg,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ),
      );
    } else {
      imageWidget = Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          color: bg,
          alignment: Alignment.center,
          child: Icon(
            Icons.image,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
      ),
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(color: bg),
          child: imageWidget,
        ),
      ),
    );
  }
}


