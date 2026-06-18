// ignore_for_file: unnecessary_string_escapes
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdBannerContainer  –  320×50 banner (highperformanceformat)
// ─────────────────────────────────────────────────────────────────────────────
class AdBannerContainer extends StatefulWidget {
  const AdBannerContainer({super.key});

  @override
  State<AdBannerContainer> createState() => _AdBannerContainerState();
}

class _AdBannerContainerState extends State<AdBannerContainer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _retries = 0;
  static const _maxRetries = 3;
  Timer? _timeoutTimer;

  static const String _adHtml = '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 320px; height: 50px;
      overflow: hidden;
      background: transparent;
      display: flex; align-items: center; justify-content: center;
    }
  </style>
</head>
<body>
  <script>
    atOptions = {
      'key': '3af8077771d8c8c51f2f926c3b2f21bf',
      'format': 'iframe',
      'height': 50,
      'width': 320,
      'params': {}
    };
  </script>
  <script src="https://www.highperformanceformat.com/3af8077771d8c8c51f2f926c3b2f21bf/invoke.js"></script>
</body>
</html>''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initWebView() async {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          // Always allow subframes (ad iframes)
          if (!request.isMainFrame) return NavigationDecision.navigate;
          // Allow the base page itself
          if (request.url.startsWith('https://movies.harmber.xyz') ||
              request.url == 'about:blank') {
            return NavigationDecision.navigate;
          }
          // Open external links in browser
          final uri = Uri.tryParse(request.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return NavigationDecision.prevent;
        },
        onPageFinished: (url) {
          _timeoutTimer?.cancel();
          // Give ad script 800ms to render
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _isLoading = false);
          });
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) {
            _timeoutTimer?.cancel();
            if (_retries < _maxRetries) {
              _retries++;
              Future.delayed(const Duration(seconds: 2), _initWebView);
            } else {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            }
          }
        },
      ))
      ..loadHtmlString(_adHtml, baseUrl: 'https://movies.harmber.xyz/');

    // Timeout fallback: if not finished in 10s, hide loader anyway
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    if (_hasError) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('AD',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 7,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 6),
                  Text('SPONSORED',
                      style: TextStyle(
                          color: t.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ],
              ),
              const SizedBox(height: 6),
              // Ad WebView
              SizedBox(
                width: 320,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      if (_isLoading)
                        Container(
                          width: 320,
                          height: 50,
                          decoration: BoxDecoration(
                            color: t.surface2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: t.accent),
                            ),
                          ),
                        ),
                      if (_controller != null)
                        AnimatedOpacity(
                          opacity: _isLoading ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: WebViewWidget(controller: _controller!),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdNativeContainer  –  300×300 native square (breedsmuteexams)
// ─────────────────────────────────────────────────────────────────────────────
class AdNativeContainer extends StatefulWidget {
  const AdNativeContainer({super.key});

  @override
  State<AdNativeContainer> createState() => _AdNativeContainerState();
}

class _AdNativeContainerState extends State<AdNativeContainer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _retries = 0;
  static const _maxRetries = 3;
  Timer? _timeoutTimer;

  static const String _adHtml = '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 300px; height: 300px;
      overflow: hidden;
      background: transparent;
      display: flex; align-items: center; justify-content: center;
    }
    #container-2bea6e53cbe4335cdbb64a1bec89739f {
      width: 300px; height: 300px;
    }
  </style>
</head>
<body>
  <script async="async" data-cfasync="false" src="https://breedsmuteexams.com/2bea6e53cbe4335cdbb64a1bec89739f/invoke.js"></script>
  <div id="container-2bea6e53cbe4335cdbb64a1bec89739f"></div>
</body>
</html>''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initWebView() async {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          if (!request.isMainFrame) return NavigationDecision.navigate;
          if (request.url.startsWith('https://movies.harmber.xyz') ||
              request.url == 'about:blank') {
            return NavigationDecision.navigate;
          }
          final uri = Uri.tryParse(request.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return NavigationDecision.prevent;
        },
        onPageFinished: (url) {
          _timeoutTimer?.cancel();
          // Give ad script 1200ms to render
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _isLoading = false);
          });
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) {
            _timeoutTimer?.cancel();
            if (_retries < _maxRetries) {
              _retries++;
              Future.delayed(const Duration(seconds: 2), _initWebView);
            } else {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            }
          }
        },
      ))
      ..loadHtmlString(_adHtml, baseUrl: 'https://movies.harmber.xyz/');

    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    if (_hasError) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.border.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('AD',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 7),
                  Text('RECOMMENDED FOR YOU',
                      style: TextStyle(
                          color: t.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                  const Spacer(),
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: t.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              // Ad WebView
              SizedBox(
                width: 300,
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      if (_isLoading)
                        Container(
                          width: 300,
                          height: 300,
                          color: t.surface2,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: t.accent, strokeWidth: 2),
                          ),
                        ),
                      if (_controller != null)
                        AnimatedOpacity(
                          opacity: _isLoading ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          child: WebViewWidget(controller: _controller!),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
