// lib/features/03_feeds/screens/web_view_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool asModal;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.asModal = false,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _dragDistance = 0;
  static const double _closeThreshold = 120;

  @override
  void initState() {
    super.initState();

    // Platform spesifik WebView controller oluştur
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
      // Android spesifik optimizasyonlar ayrıca yapılacak
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // WebView controller'ı oluştur - performans optimizasyonları ile
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false) // Zoom'u kapat
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Yükleme ilerlemesi
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            // Sayfa yüklendikten sonra JavaScript ile scroll ve performans optimizasyonları
            try {
              await _controller.runJavaScript('''
                // Universal scroll fix - tüm platformlar için
                console.log('Starting universal scroll optimization...');
                
                // Önce mevcut viewport'u temizle
                var existingViewports = document.querySelectorAll('meta[name="viewport"]');
                existingViewports.forEach(function(vp) { vp.remove(); });
                
                // Yeni viewport ekle
                var viewport = document.createElement('meta');
                viewport.name = 'viewport';
                viewport.content = 'width=device-width, initial-scale=1.0, user-scalable=no, maximum-scale=1.0';
                document.head.appendChild(viewport);

                // Body ve HTML için temel scroll ayarları
                document.documentElement.style.cssText = `
                  overflow: auto !important;
                  overflow-x: hidden !important;
                  overflow-y: auto !important;
                  -webkit-overflow-scrolling: touch !important;
                  height: auto !important;
                  min-height: 100vh !important;
                  touch-action: pan-y !important;
                  position: relative !important;
                `;
                
                document.body.style.cssText = `
                  overflow: auto !important;
                  overflow-x: hidden !important;
                  overflow-y: auto !important;
                  -webkit-overflow-scrolling: touch !important;
                  height: auto !important;
                  min-height: 100vh !important;
                  touch-action: pan-y !important;
                  position: relative !important;
                  margin: 0 !important;
                  padding: 0 !important;
                `;

                // Global CSS injection - scroll'u zorla etkinleştir
                var globalStyle = document.createElement('style');
                globalStyle.id = 'webview-scroll-fix';
                globalStyle.textContent = `
                  * {
                    -webkit-overflow-scrolling: touch !important;
                  }
                  
                  html, body {
                    overflow: auto !important;
                    overflow-x: hidden !important;
                    overflow-y: auto !important;
                    height: auto !important;
                    min-height: 100vh !important;
                    touch-action: pan-y !important;
                    position: relative !important;
                  }
                  
                  /* Scroll'u engelleyen common class'ları override et */
                  .no-scroll, .overflow-hidden, .locked, .modal-open {
                    overflow: auto !important;
                    overflow-y: auto !important;
                    height: auto !important;
                    position: relative !important;
                  }
                  
                  /* Fixed positioning sorunlarını çöz */
                  .fixed, .sticky {
                    position: relative !important;
                  }
                `;
                document.head.appendChild(globalStyle);

                // Android Chrome WebView için özel touch handling
                var scrollMultiplier = 1.5;
                var lastTouchY = 0;
                var isActivelyScrolling = false;
                
                document.addEventListener('touchstart', function(e) {
                  lastTouchY = e.touches[0].clientY;
                  isActivelyScrolling = false;
                }, {passive: true});
                
                document.addEventListener('touchmove', function(e) {
                  var currentTouchY = e.touches[0].clientY;
                  var deltaY = lastTouchY - currentTouchY;
                  
                  if (Math.abs(deltaY) > 3) {
                    isActivelyScrolling = true;
                    
                    // Direkt window.scrollBy kullan - en güvenilir yöntem
                    window.scrollBy(0, deltaY * scrollMultiplier);
                    
                    // Element bazlı scroll da dene
                    if (document.documentElement.scrollTop !== undefined) {
                      document.documentElement.scrollTop += deltaY * scrollMultiplier;
                    }
                    if (document.body.scrollTop !== undefined) {
                      document.body.scrollTop += deltaY * scrollMultiplier;
                    }
                    
                    lastTouchY = currentTouchY;
                  }
                }, {passive: true});
                
                // Daha agresif scroll enforcement
                setInterval(function() {
                  if (document.body.style.overflow !== 'auto') {
                    document.body.style.overflow = 'auto';
                    document.documentElement.style.overflow = 'auto';
                  }
                }, 100);
                
                // Force enable scrolling after DOM changes
                setTimeout(function() {
                  document.documentElement.style.overflow = 'auto';
                  document.body.style.overflow = 'auto';
                  console.log('Delayed scroll enforcement applied');
                }, 1000);
                
                // Mutation observer to catch dynamic content blocking scroll
                if (window.MutationObserver) {
                  var observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                      if (mutation.type === 'attributes' && 
                          (mutation.attributeName === 'style' || mutation.attributeName === 'class')) {
                        // Re-enforce scroll settings
                        var target = mutation.target;
                        if (target === document.body || target === document.documentElement) {
                          target.style.overflow = 'auto';
                          target.style.overflowY = 'auto';
                          target.style.touchAction = 'pan-y';
                        }
                      }
                    });
                  });
                  
                  observer.observe(document.body, {
                    attributes: true,
                    attributeFilter: ['style', 'class']
                  });
                  
                  observer.observe(document.documentElement, {
                    attributes: true,
                    attributeFilter: ['style', 'class']
                  });
                }

                console.log('Universal scroll optimization completed');
              ''');
            } catch (e) {
              print('JavaScript optimization error: $e');
            }

            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Cache-Control': 'max-age=3600',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        },
      );

    // Platform spesifik ayarlar
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = _controller.platform as AndroidWebViewController;
      
      // Android WebView ayarları - scroll'u tamamen serbest bırak
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setTextZoom(100);
      
      // Agresif scroll düzeltmeleri - direkt controller üzerinden
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await androidController.runJavaScript('''
            // Tüm scroll engellerini kaldır
            document.documentElement.style.cssText = 'overflow: auto !important; height: auto !important; -webkit-overflow-scrolling: touch !important;';
            document.body.style.cssText = 'overflow: auto !important; height: auto !important; -webkit-overflow-scrolling: touch !important; position: relative !important;';
            
            // Touch event'leri için manuel scroll
            var scrollSensitivity = 2;
            var isScrolling = false;
            var startY = 0;
            
            function forceScroll(deltaY) {
              window.scrollBy(0, deltaY * scrollSensitivity);
            }
            
            document.addEventListener('touchstart', function(e) {
              startY = e.touches[0].clientY;
              isScrolling = false;
            }, {passive: true});
            
            document.addEventListener('touchmove', function(e) {
              var currentY = e.touches[0].clientY;
              var deltaY = startY - currentY;
              
              if (Math.abs(deltaY) > 5) {
                isScrolling = true;
                forceScroll(deltaY);
                startY = currentY;
              }
            }, {passive: true});
            
            // Wheel events için
            document.addEventListener('wheel', function(e) {
              forceScroll(e.deltaY);
            }, {passive: true});
            
            console.log('Android agresif scroll düzeltmeleri uygulandı');
          ''');
        } catch (e) {
          print('Android scroll fix error: \$e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = widget.asModal
        ? PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          )
        : AppBar(
            title: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _controller.reload(),
              ),
            ],
          );

    return Scaffold(
      appBar: appBar is PreferredSizeWidget ? appBar as PreferredSizeWidget : appBar,
      body: widget.asModal
          ? Stack(
              children: [
                WebViewWidget(
                  controller: _controller,
                ),
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // Modal kapatma için üst kısımda gesture detector
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.delta.dy > 0) {
                        _dragDistance += details.delta.dy;
                      }
                    },
                    onVerticalDragEnd: (details) {
                      if (_dragDistance > _closeThreshold && mounted) {
                        Navigator.of(context).maybePop();
                      }
                      _dragDistance = 0;
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: const Center(
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                WebViewWidget(
                  controller: _controller,
                ),
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}
