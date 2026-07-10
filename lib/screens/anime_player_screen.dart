import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/theme_service.dart';
import '../services/history_service.dart';

class AnimePlayerScreen extends StatefulWidget {
  final int anilistId;
  final int episode;
  final String title;
  final String? posterPath;
  final int totalEpisodes;
  final bool isMovie;
  final bool isDub;

  const AnimePlayerScreen({
    super.key,
    required this.anilistId,
    required this.episode,
    required this.title,
    this.posterPath,
    required this.totalEpisodes,
    this.isMovie = false,
    this.isDub = false,
  });

  @override
  State<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends State<AnimePlayerScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  late int _currentEpisode;
  bool _webViewInitialized = false;
  bool _isDub = false;
  bool _isLandscape = true;
  bool _showControls = true;
  Timer? _controlsTimer;

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  String get _url {
    final ep = _currentEpisode < 1 ? 1 : _currentEpisode;
    final lang = _isDub ? 'dub' : 'sub';
    return 'https://animeplay.cfd/stream/ani/${widget.anilistId}/$ep/$lang';
  }

  static const _playerScript = '''
    (function(){
      var meta = document.querySelector('meta[name=viewport]');
      if(!meta){ meta = document.createElement('meta'); meta.name='viewport'; document.head.appendChild(meta); }
      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=yes';

      document.addEventListener('touchstart', function(e) {
        if (e.touches.length > 1) { e.preventDefault(); }
      }, { passive: false });

      var lastTouchEnd = 0;
      document.addEventListener('touchend', function(e) {
        var now = Date.now();
        if (now - lastTouchEnd <= 300) { e.preventDefault(); }
        lastTouchEnd = now;
      }, false);

      document.addEventListener('click', function(e){
        var t = e.target;
        while(t){
          if(t.tagName==='A'){
            var h = t.getAttribute('href')||'';
            var tg = t.getAttribute('target')||'';
            var allowed = h.includes('animeplay.cfd');
            if(tg==='_blank' || (!allowed && !h.startsWith('#') && h.length>1)){
              e.preventDefault(); e.stopPropagation(); return false;
            }
          }
          t = t.parentElement;
        }
      }, true);

      function clean(){
        var sels = [
          'iframe[src*="ads"]','iframe[src*="doubleclick"]',
          'iframe[src*="googlesyndication"]','ins.adsbygoogle',
          'div[id*="google_ad"]','div[class*=" ad"]',
          '.overlay','#overlay','[class*="popup"]','[id*="popup"]',
          'a[target="_blank"]','div[class*="banner"]','div[id*="banner"]',
          '[class*="advertisement"]','[id*="advertisement"]'
        ];
        sels.forEach(function(s){
          try { document.querySelectorAll(s).forEach(function(el){ el.remove(); }); } catch(e){}
        });
      }
      clean();
      new MutationObserver(clean).observe(document.documentElement,
        {childList:true,subtree:true});

      window.open = function(){ return null; };

      var style = document.createElement('style');
      style.textContent = '* { touch-action: manipulation !important; } body, html { overflow: hidden !important; margin: 0 !important; padding: 0 !important; width: 100% !important; height: 100% !important; background: #000 !important; } iframe:not([src*="ads"]):not([src*="doubleclick"]) { position: fixed !important; top: 0 !important; left: 0 !important; width: 100vw !important; height: 100vh !important; z-index: 999999 !important; border: none !important; } video { width: 100% !important; height: 100% !important; object-fit: contain !important; }';
      document.head.appendChild(style);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    // Enforce landscape immediately
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentEpisode = widget.episode;
    _isDub = widget.isDub; // carry language pref from detail screen
    _initWebView();
    _recordHistory();
    _startControlsTimer();
  }

  void _recordHistory() {
    HistoryService.instance.record(
      id: widget.anilistId,
      title: widget.title,
      posterPath: widget.posterPath,
      mediaType: 'anime',
      episode: widget.isMovie ? null : _currentEpisode,
    );
  }

  void _initWebView() {
    if (_webViewInitialized) return;
    _webViewInitialized = true;

    // Force hide loading after 10 seconds as a fallback
    Timer(const Duration(seconds: 10), () {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          if (progress > 50 && mounted && _loading) {
            setState(() => _loading = false);
          }
        },
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _loading = true;
              _hasError = false;
            });
          }
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _controller.runJavaScript(_playerScript);
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) {
            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = true;
              });
            }
          }
        },
        onNavigationRequest: (request) {
          if (!request.url.contains('animeplay.cfd') &&
              !request.url.startsWith('about:') &&
              !request.url.startsWith('data:') &&
              !request.url.startsWith('blob:')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..setOnConsoleMessage((_) {})
      ..loadRequest(Uri.parse(_url));
  }

  void _reloadPlayer() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _controller.loadRequest(Uri.parse(_url));
    _recordHistory();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    // Maintain sticky immersive in build
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // WebView player with RepaintBoundary for maximum rendering performance
            RepaintBoundary(
              child: WebViewWidget(controller: _controller),
            ),

            if (_showControls) ...[
              // Floating Back Button (top-left)
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    // Consume gesture and go back
                    Navigator.pop(context);
                  },
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Fullscreen / Orientation Toggle Button (top-right)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    // Consume gesture
                    _toggleOrientation();
                    _startControlsTimer();
                  },
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Icon(
                        _isLandscape ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Sub/Dub Toggle (bottom-right only)
              Positioned(
                bottom: 20,
                right: 20,
                child: RepaintBoundary(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isDub = !_isDub);
                      _reloadPlayer();
                      _startControlsTimer();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isDub ? t.accent : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isDub ? Icons.subtitles_off_rounded : Icons.subtitles_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDub ? 'DUB' : 'SUB',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (_hasError)
              RepaintBoundary(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_off_rounded,
                            color: Colors.white54, size: 48),
                        const SizedBox(height: 16),
                        Text('Content Not Available',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Please check your internet connection or try again.',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            _reloadPlayer();
                            _startControlsTimer();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: t.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Retry',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

            if (_loading)
              RepaintBoundary(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: t.accent,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Loading player...',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms),
              ),
          ],
        ),
      ),
    );
  }
}
