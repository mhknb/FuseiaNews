import 'package:flutter/material.dart';
import '../../../core/models/news_model.dart';

class NewsListItem extends StatelessWidget {
  final HaberModel haber;
  final VoidCallback onTap;

  const NewsListItem({super.key, required this.haber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = haber.imageUrl != null && haber.imageUrl!.isNotEmpty;
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
            if (hasImage)
              _EdgeImage(
                url: haber.imageUrl!,
                width: imageWidth,
                radius: 16,
              )
            else
              SizedBox(width: imageWidth),

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
}

class _EdgeImage extends StatelessWidget {
  final String url;
  final double width;
  final double radius;
  const _EdgeImage({required this.url, required this.width, required this.radius});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
      ),
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(color: bg),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => Container(
              color: bg,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


