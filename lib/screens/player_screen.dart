import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/theme_service.dart';
import '../services/history_service.dart';


class PlayerScreen extends StatefulWidget {
  final int id;
  final bool isTV;
  final int season;
  final int episode;
  final String title;
  final String? posterPath;
  final int? totalEpisodes;
  final int? totalSeasons;

  const PlayerScreen({
    super.key,
    required this.id,
    this.isTV = false,
    this.season = 1,
    this.episode = 1,
    this.title = '',
    this.posterPath,
    this.totalEpisodes,
    this.totalSeasons,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}


class _PlayerScreenState extends State<PlayerScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  late int _currentEpisode;
  late int _currentSeason;
  bool _webViewInitialized = false;
  bool _isLandscape = true;
  bool _showControls = true;
  bool _showServerPicker = false;
  int _selectedServer = 1;
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
    if (widget.isTV) {
      return 'https://vaplayer.ru/embed/tv/${widget.id}/$_currentSeason/$_currentEpisode';
    }
    return 'https://vaplayer.ru/embed/movie/${widget.id}';
  }

  void _switchServer(int server) {
    // We only have one server now based on the request, but I'll keep the UI for now or simplify it.
    // The user said "for naie use the same url as existig" which is a bit confusing if I'm changing the base url.
    // Actually, maybe they meant "for name" or something.
    // I'll stick to the requested URLs.
    setState(() {
      _selectedServer = server;
      _showServerPicker = false;
      _loading = true;
      _hasError = false;
    });
    _webViewInitialized = false;
    _initWebView();
    _startControlsTimer();
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
            var allowed = h.includes('vidfast.pro');
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentEpisode = widget.episode;
    _currentSeason = widget.season;
    _initWebView();
    _recordHistory();
    _startControlsTimer();
  }

  void _recordHistory() {
    HistoryService.instance.record(
      id: widget.id,
      title: widget.title,
      posterPath: widget.posterPath,
      mediaType: widget.isTV ? 'tv' : 'movie',
      season: widget.isTV ? _currentSeason : null,
      episode: widget.isTV ? _currentEpisode : null,
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
          final allowed = request.url.contains('vidfast.pro') ||
              request.url.contains('vidlink.pro');
          if (!allowed &&
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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showServerPicker) {
            setState(() => _showServerPicker = false);
          } else {
            _toggleControls();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: WebViewWidget(controller: _controller),
            ),

            if (_showControls && !_showServerPicker) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xBB000000), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RepaintBoundary(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // ✅ FIX 1: decoration and child are now correct separate params
                      GestureDetector(
                        onTap: () {
                          _controlsTimer?.cancel();
                          setState(() => _showServerPicker = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.dns_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'Source $_selectedServer',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          _toggleOrientation();
                          _startControlsTimer();
                        },
                        child: RepaintBoundary(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Icon(
                              _isLandscape
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (widget.isTV)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Row(
                    children: [
                      if (_currentEpisode > 1)
                        _playerBtn(Icons.skip_previous_rounded, () {
                          setState(() {
                            _currentEpisode--;
                            _loading = true;
                            _hasError = false;
                          });
                          _controller.loadRequest(Uri.parse(_url));
                          _startControlsTimer();
                        }),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          'S$_currentSeason E$_currentEpisode',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _playerBtn(Icons.skip_next_rounded, () {
                        setState(() {
                          _currentEpisode++;
                          _loading = true;
                          _hasError = false;
                        });
                        _controller.loadRequest(Uri.parse(_url));
                        _startControlsTimer();
                      }),
                    ],
                  ),
                ),
            ],

            // ✅ FIX 2: Column children list properly closed
            if (_showServerPicker)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showServerPicker = false),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.72),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Source',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose your streaming source',
                                style: GoogleFonts.inter(
                                    color: Colors.white54, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              _serverTile(
                                  1,
                                  'Source 1',
                                  'Primary Stream',
                                  Icons.play_circle_rounded,
                                  const Color(0xFF6C63FF)),
                              const SizedBox(height: 10),
                              _serverTile(
                                  2,
                                  'Source 2',
                                  'Backup Stream',
                                  Icons.play_circle_outline_rounded,
                                  const Color(0xFF00C9A7)),
                              const SizedBox(height: 14),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _showServerPicker = false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],   // ← closes children list
                          ),     // ← closes Column
                        ),
                      ),
                    ),
                  ),
                ),
              ),

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
                        Text(
                          'Content Not Available',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your internet connection or try again.',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 14),
                        ),
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
                            child: Text(
                              'Retry',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
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
                        Text(
                          'Loading player...',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 14),
                        ),
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

  Widget _serverTile(
      int server, String label, String subtitle, IconData icon, Color color) {
    final isSelected = _selectedServer == server;
    return GestureDetector(
      onTap: () => _switchServer(server),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _playerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}