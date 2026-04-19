import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';

class AdBannerContainer extends StatefulWidget {
  const AdBannerContainer({super.key});

  @override
  State<AdBannerContainer> createState() => _AdBannerContainerState();
}

class _AdBannerContainerState extends State<AdBannerContainer> {
  WebViewController? _controller;
  bool _isLoading = true;

  final String _adHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body { 
      padding: 0; 
      margin: 0; 
      background-color: transparent; 
      display: flex; 
      justify-content: center; 
      align-items: center; 
      height: 100vh; 
      overflow: hidden; 
    }
    /* Simple fallback for generic desktop */
    .static-banner {
      width: 320px;
      height: 50px;
      background: #1A1A26;
      color: #FFF;
      display: flex;
      justify-content: center;
      align-items: center;
      font-family: sans-serif;
      text-decoration: none;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <script>
    atOptions = {
        'key' : '3af8077771d8c8c51f2f926c3b2f21bf',
        'format' : 'iframe',
        'height' : 50,
        'width' : 320,
        'params' : {}
    };
  </script>
  <script src="https://www.highperformanceformat.com/3af8077771d8c8c51f2f926c3b2f21bf/invoke.js"></script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith('https://movies.harmber.xyz')) {
              return NavigationDecision.navigate;
            }
            final uri = Uri.parse(request.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (String url) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) setState(() => _isLoading = false);
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: \${error.description}');
          },
        ),
      )
      ..loadHtmlString(_adHtml, baseUrl: 'https://movies.harmber.xyz/');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;

    Widget buildWebView() {
      if (_controller != null) {
        return WebViewWidget(controller: _controller!);
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 340,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AD',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SPONSORED CONTENT',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.info_outline_rounded, size: 14, color: t.textMuted),
                      ],
                    ),
                  ),
                  Container(
                    width: 320,
                    height: 50,
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.border.withValues(alpha: 0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          if (_isLoading)
                            Shimmer.fromColors(
                              baseColor: t.surface2,
                              highlightColor: t.surface,
                              child: Container(
                                width: 320,
                                height: 50,
                                color: Colors.white,
                              ),
                            ),
                          AnimatedOpacity(
                            opacity: _isLoading ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            child: buildWebView(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}
