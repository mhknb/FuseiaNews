import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/news_model.dart';

class NewsListItem extends StatefulWidget {
  final HaberModel haber;
  final VoidCallback onTap;

  const NewsListItem({super.key, required this.haber, required this.onTap});

  @override
  State<NewsListItem> createState() => _NewsListItemState();
}

class _NewsListItemState extends State<NewsListItem> {
  bool _pressed = false;

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} m ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final haber = widget.haber;
    final bool hasNetworkImage = haber.imageUrl != null && haber.imageUrl!.isNotEmpty;

    final Color metaColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final Color summaryColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    final Color headlineColor = Theme.of(context).colorScheme.onSurface;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color pressedStroke = Theme.of(context).colorScheme.outline.withOpacity(0.3);

    const double imageWidth = 96;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _pressed ? pressedStroke : Colors.transparent, width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: fixed width image 96dp
                ConstrainedBox(
                  constraints: const BoxConstraints.tightFor(width: imageWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FractionallySizedBox(
                      heightFactor: 1,
                      child: hasNetworkImage
                          ? FadeInImage.assetNetwork(
                              placeholder: _categoryAssetPath(haber.sourceName),
                              image: haber.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 180),
                              imageErrorBuilder: (context, error, stack) => Image.asset(
                                _categoryAssetPath(haber.sourceName),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              _categoryAssetPath(haber.sourceName),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right: text
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta row: source • 2 h ago • Kategori
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    haber.websiteName ?? haber.sourceName,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w500, // Medium
                                      fontSize: 12,
                                      color: metaColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(width: 3, height: 3, decoration: BoxDecoration(color: metaColor, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  _relativeTime(haber.pubDate),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: metaColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            haber.category,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: metaColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Headline
                      Text(
                        haber.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, // SemiBold
                          height: 1.2,
                          fontSize: 18,
                          color: headlineColor,
                        ),
                      ),
                      if (haber.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          haber.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: summaryColor,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    const Map<String, String> direct = {
      'teknoloji_haberleri': 'teknoloji.jpg',
      'teknoloji': 'teknoloji.jpg',
      'bilim': 'bilim.png',
      'egitim': 'egitim.png',
      'yapay_zeka': 'yz.jpg',
      'yz': 'yz.jpg',
      'finans': 'finans.png',
      'gundem': 'gundem.png',
      'genel': 'gundem.png',
      'spor': 'spor.png',
      'kultur_sanat': 'sinema.jpg',
      'eglence': 'eglence.png',
      'yasam': 'yasam.png',
      'oyun': 'oyun.jpg',
      'saglik': 'saglik.jpg',
      'sinema': 'sinema.jpg',
    };

    if (direct.containsKey(n)) {
      return 'assets/images/${direct[n]!}';
    }

    if (n.contains('teknoloji')) return 'assets/images/teknoloji.jpg';
    if (n.contains('yapay') || n.contains('zeka')) return 'assets/images/yz.jpg';
    if (n.contains('saglik')) return 'assets/images/saglik.jpg';
    if (n.contains('bilim')) return 'assets/images/bilim.png';
    if (n.contains('egitim')) return 'assets/images/egitim.png';
    if (n.contains('finans') || n.contains('ekonomi')) return 'assets/images/finans.png';
    if (n.contains('gundem') || n.contains('haber')) return 'assets/images/gundem.png';
    if (n.contains('eglence')) return 'assets/images/eglence.png';
    if (n.contains('yasam')) return 'assets/images/yasam.png';
    if (n.contains('oyun') || n.contains('gaming')) return 'assets/images/oyun.jpg';
    if (n.contains('sinema') || n.contains('film')) return 'assets/images/sinema.jpg';
    if (n.contains('spor')) return 'assets/images/spor.png';

    return 'assets/images/gundem.png';
  }
}