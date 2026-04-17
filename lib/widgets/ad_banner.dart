import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    if (!kIsWeb) {
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
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView Error: \${error.description}');
            },
          ),
        )
        ..loadHtmlString(_adHtml, baseUrl: 'https://movies.harmber.xyz/');

    } else {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    return Center(
      child: Container(
        width: 320,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: kIsWeb
                    ? const Center(
                        child: Text('Ad Banner',
                            style: TextStyle(color: Colors.grey)))
                    : WebViewWidget(controller: _controller!),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }
}
