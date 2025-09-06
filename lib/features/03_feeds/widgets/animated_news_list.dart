import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/news_model.dart';
import 'news_list_item.dart';

class AnimatedNewsList extends StatefulWidget {
  final List<HaberModel> haberler;
  final Function(HaberModel) onItemTap;
  final Function() onRefresh;
  final bool isBackgroundRefreshing;

  const AnimatedNewsList({
    super.key,
    required this.haberler,
    required this.onItemTap,
    required this.onRefresh,
    this.isBackgroundRefreshing = false,
  });

  @override
  State<AnimatedNewsList> createState() => _AnimatedNewsListState();
}

class _AnimatedNewsListState extends State<AnimatedNewsList>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _setupItemAnimations();
    _animationController.forward();
  }

  void _setupItemAnimations() {
    _itemControllers = List.generate(
      widget.haberler.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    // Stagger the animations
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _itemControllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedNewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.haberler.length != oldWidget.haberler.length) {
      _disposeControllers();
      _setupItemAnimations();
    }
  }

  void _disposeControllers() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _animationController.reset();
            await widget.onRefresh();
            _animationController.forward();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            itemCount: widget.haberler.length,
            itemBuilder: (context, index) {
              final haber = widget.haberler[index];
              final animation = index < _itemAnimations.length
                  ? _itemAnimations[index]
                  : const AlwaysStoppedAnimation(1.0);

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - animation.value)),
                    child: Opacity(
                      opacity: animation.value.clamp(0.0, 1.0),
                      child: Dismissible(
                        key: Key(haber.link),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          await _openInBrowser(haber.link);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.open_in_browser, color: Colors.white, size: 28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: NewsListItem(
                            haber: haber,
                            onTap: () => widget.onItemTap(haber),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Background refresh indicator
        if (widget.isBackgroundRefreshing)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Güncelleniyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening URL: $e');
    }
  }
}
