// lib/features/03_feeds/screens/web_view_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    
    // WebView controller'ı oluştur
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Sadece aşağı yönlü çekişi say
          if (details.delta.dy > 0) {
            _dragDistance += details.delta.dy;
          }
        },
        onVerticalDragEnd: (_) {
          if (_dragDistance > _closeThreshold && mounted) {
            Navigator.of(context).maybePop();
          }
          _dragDistance = 0;
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
