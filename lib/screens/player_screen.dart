import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/theme_service.dart';

class PlayerScreen extends StatefulWidget {
  final int id;
  final bool isTV;
  final int season;
  final int episode;
  final String title;
  final int? totalEpisodes;
  final int? totalSeasons;

  const PlayerScreen({
    super.key,
    required this.id,
    this.isTV = false,
    this.season = 1,
    this.episode = 1,
    this.title = '',
    this.totalEpisodes,
    this.totalSeasons,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with AutomaticKeepAliveClientMixin {
  // Keep alive so orientation rebuild never destroys WebView state
  @override
  bool get wantKeepAlive => true;

  late WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  int _selectedServer = 0;
  late int _currentEpisode;
  late int _currentSeason;

  // Guard: init WebView only once
  bool _webViewInitialized = false;

  final _servers = const ['Server 1', 'Server 2', 'Server 3'];

  String get _url {
    if (_selectedServer == 0) {
      if (widget.isTV) {
        return 'https://player.videasy.net/tv/${widget.id}/$_currentSeason/$_currentEpisode';
      }
      return 'https://player.videasy.net/movie/${widget.id}';
    } else if (_selectedServer == 1) {
      if (widget.isTV) {
        return 'https://vidfast.pro/tv/${widget.id}/$_currentSeason/$_currentEpisode?autoPlay=true';
      }
      return 'https://vidfast.pro/movie/${widget.id}?autoPlay=true';
    } else {
      if (widget.isTV) {
        return 'https://vidsrc.net/embed/tv?tmdb=${widget.id}&season=$_currentSeason&episode=$_currentEpisode';
      }
      return 'https://vidsrc.net/embed/movie?tmdb=${widget.id}';
    }
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
            var allowed = h.includes('videasy.net') || h.includes('vidfast.pro') || h.includes('vidsrc');
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
      style.textContent = '* { touch-action: manipulation !important; } body { overflow: hidden !important; }';
      document.head.appendChild(style);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _currentEpisode = widget.episode;
    _currentSeason = widget.season;
    _initWebView();
  }

  void _initWebView() {
    if (_webViewInitialized) return; // ← KEY FIX: never re-init
    _webViewInitialized = true;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _loading = true; _hasError = false; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _controller.runJavaScript(_playerScript);
        },
        onWebResourceError: (error) {
          // Only treat as fatal error for main frame, not sub-resources
          if (error.isForMainFrame == true) {
            if (mounted) setState(() { _loading = false; _hasError = true; });
          }
        },
        onNavigationRequest: (request) {
          if (!request.url.contains('videasy.net') &&
              !request.url.contains('vidfast.pro') &&
              !request.url.contains('vidsrc.net') &&
              !request.url.contains('vidsrc') &&
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

  // Reload with a fresh URL (episode/server change), resetting error state
  void _reloadPlayer() {
    if (!mounted) return;
    setState(() { _loading = true; _hasError = false; });
    _controller.loadRequest(Uri.parse(_url));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextEpisode() {
    if (!widget.isTV) return;
    final maxEp = widget.totalEpisodes ?? 999;
    if (_currentEpisode < maxEp) {
      setState(() => _currentEpisode++);
      _reloadPlayer();
    }
  }

  void _previousEpisode() {
    if (!widget.isTV || _currentEpisode <= 1) return;
    setState(() => _currentEpisode--);
    _reloadPlayer();
  }

  String get _currentTitle {
    if (widget.isTV) return '${widget.title} S$_currentSeason E$_currentEpisode';
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final t = ThemeService.instance;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // System UI: don't call setState here — just side effects
    if (isLandscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isLandscape
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0A0A0F),
              foregroundColor: Colors.white,
              title: Text(
                _currentTitle,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70),
                  tooltip: 'Full Screen',
                  onPressed: () {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                  },
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.dns_rounded,
                      color: Colors.white70, size: 22),
                  color: const Color(0xFF1A1A26),
                  onSelected: (i) {
                    setState(() => _selectedServer = i);
                    _reloadPlayer();
                  },
                  itemBuilder: (_) => List.generate(
                    _servers.length,
                    (i) => PopupMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Icon(
                            _selectedServer == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _selectedServer == i
                                ? t.accent
                                : Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(_servers[i],
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // WebView is always in the tree — never conditionally removed
                WebViewWidget(controller: _controller),

                if (isLandscape)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      tooltip: 'Exit Full Screen',
                      onPressed: () {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                        ]);
                      },
                    ),
                  ),

                if (_hasError)
                  Container(
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
                          Text(
                              'Try a different server or check back later.',
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _reloadPlayer,
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

                if (_loading)
                  Container(
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
              ],
            ),
          ),

          if (widget.isTV && !isLandscape)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  _episodeButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Prev',
                    onTap: _currentEpisode > 1 ? _previousEpisode : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Season $_currentSeason · Episode $_currentEpisode',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _episodeButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Next',
                    onTap: _nextEpisode,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _episodeButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: enabled ? Colors.white : Colors.white24, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: enabled ? Colors.white : Colors.white24,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}