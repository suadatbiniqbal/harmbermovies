import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sports_match.dart';

class SportsPlayerScreen extends StatefulWidget {
  final SportsMatch match;
  const SportsPlayerScreen({super.key, required this.match});

  @override
  State<SportsPlayerScreen> createState() => _SportsPlayerScreenState();
}

class _SportsPlayerScreenState extends State<SportsPlayerScreen>
    with TickerProviderStateMixin {
  WebViewController? _controller;
  bool _loading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _showServerPicker = false;
  int _selectedServer = 1;
  Timer? _controlsTimer;
  Timer? _countdownTimer;
  Duration? _remaining;
  bool _streamNowOpen = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _streamNowOpen = widget.match.isStreamOpen;
    if (_streamNowOpen) {
      _initPlayer();
    } else {
      _remaining = widget.match.timeUntilStreamOpen;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final r = widget.match.timeUntilStreamOpen;
        if (r == null || r.isNegative) {
          _countdownTimer?.cancel();
          setState(() { _streamNowOpen = true; _remaining = null; });
          _initPlayer();
        } else {
          setState(() => _remaining = r);
        }
      });
    }
  }

  void _initPlayer() {
    final allowedHosts = <String>[];
    for (final url in [widget.match.server1Url, widget.match.server2Url]) {
      final u = Uri.tryParse(url);
      if (u != null && u.host.isNotEmpty) allowedHosts.add(u.host);
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() { _loading = true; _hasError = false; }); },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _controller?.runJavaScript(_playerScript);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) setState(() { _loading = false; _hasError = true; });
        },
        onNavigationRequest: (req) {
          if (req.url.startsWith('about:') || req.url.startsWith('data:') || req.url.startsWith('blob:')) return NavigationDecision.navigate;
          final uri = Uri.tryParse(req.url);
          if (uri != null) {
            for (final h in allowedHosts) {
              if (uri.host.contains(h) || h.contains(uri.host)) return NavigationDecision.navigate;
            }
          }
          return NavigationDecision.prevent;
        },
      ))
      ..setOnConsoleMessage((_) {})
      ..loadRequest(Uri.parse(_currentUrl.isNotEmpty ? _currentUrl : 'about:blank'));
    setState(() {});
    _startControlsTimer();
  }

  static const _playerScript = '''
    (function(){
      var meta = document.querySelector('meta[name=viewport]');
      if(!meta){ meta = document.createElement('meta'); meta.name='viewport'; document.head.appendChild(meta); }
      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
      window.open = function(){ return null; };
      var style = document.createElement('style');
      style.textContent = '* { touch-action: manipulation !important; } body, html { overflow: hidden !important; margin: 0 !important; padding: 0 !important; width: 100% !important; height: 100% !important; background: #000 !important; } iframe { position: fixed !important; top: 0 !important; left: 0 !important; width: 100vw !important; height: 100vh !important; z-index: 999999 !important; border: none !important; } video { width: 100% !important; height: 100% !important; object-fit: contain !important; }';
      document.head.appendChild(style);
    })();
  ''';

  String get _currentUrl => _selectedServer == 2
      ? widget.match.server2Url
      : widget.match.server1Url;

  void _switchServer(int server) {
    setState(() { _selectedServer = server; _showServerPicker = false; _loading = true; _hasError = false; });
    final url = server == 2 ? widget.match.server2Url : widget.match.server1Url;
    if (url.isNotEmpty) _controller?.loadRequest(Uri.parse(url));
    _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── COUNTDOWN UI ───────────────────────────────────────────────────────────
  Widget _buildCountdown() {
    final r = _remaining ?? Duration.zero;
    final h = r.inHours;
    final m = r.inMinutes % 60;
    final s = r.inSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero image
          if (widget.match.heroImageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.match.heroImageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF0A0A15)),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [Color(0xFF1A1040), Color(0xFF0A0A15)],
                ),
              ),
            ),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.97),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),

                const Spacer(),

                // League logo + name
                if (widget.match.leagueLogoUrl.isNotEmpty) ...[
                  CachedNetworkImage(
                    imageUrl: widget.match.leagueLogoUrl,
                    width: 48, height: 48, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 6),
                ],
                if (widget.match.leagueName.isNotEmpty)
                  Text(widget.match.leagueName,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600,
                          letterSpacing: 1.5))
                      .animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 28),

                // Team logos + VS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _teamBlock(widget.match.team1LogoUrl, widget.match.team1Name),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              const Color(0xFF6C63FF).withValues(alpha: 0.5),
                              _pulseCtrl.value,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color.lerp(
                                const Color(0xFF6C63FF).withValues(alpha: 0.4),
                                const Color(0xFF6C63FF),
                                _pulseCtrl.value,
                              )!,
                            ),
                          ),
                          child: Text('VS',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    _teamBlock(widget.match.team2LogoUrl, widget.match.team2Name),
                  ],
                ).animate().slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOutCubic)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 32),

                // "Stream opens in" label
                Text('Stream opens in',
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 16),

                // Countdown timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _countdownUnit(h.toString().padLeft(2, '0'), 'HOURS'),
                    _countdownColon(),
                    _countdownUnit(m.toString().padLeft(2, '0'), 'MINS'),
                    _countdownColon(),
                    _countdownUnit(s.toString().padLeft(2, '0'), 'SECS'),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 28),

                // Match title
                Text(widget.match.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3))
                    .animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 8),

                // Match time IST
                Text(
                  _formatIST(widget.match.matchTimeIST),
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamBlock(String logoUrl, String name) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.25), blurRadius: 20)],
            ),
            child: ClipOval(
              child: logoUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: logoUrl, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer_rounded, color: Colors.white38, size: 32))
                  : const Icon(Icons.sports_soccer_rounded, color: Colors.white38, size: 32),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, maxLines: 2,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
        ],
      ),
    );
  }

  Widget _countdownUnit(String value, String label) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color.lerp(
              const Color(0xFF6C63FF).withValues(alpha: 0.25),
              const Color(0xFF6C63FF).withValues(alpha: 0.55),
              _pulseCtrl.value,
            )!,
          ),
          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.08 + 0.08 * _pulseCtrl.value), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _countdownColon() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Text(':',
          style: GoogleFonts.inter(
              color: Color.lerp(Colors.white38, Colors.white70, _pulseCtrl.value),
              fontSize: 28, fontWeight: FontWeight.w900)),
    ),
  );

  String _formatIST(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} · ${h.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} $period IST';
  }

  // ─── PLAYER UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!_streamNowOpen) return _buildCountdown();

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
            if (_controller != null)
              RepaintBoundary(child: WebViewWidget(controller: _controller!)),

            if (_showControls && !_showServerPicker) ...[
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xBB000000), Colors.transparent]),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65), shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () { _controlsTimer?.cancel(); setState(() => _showServerPicker = true); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.dns_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text('Server $_selectedServer',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
                          width: 300, padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('Select Server', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Choose your stream source', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                            const SizedBox(height: 20),
                             _serverTile(1, 'Server 1', 'Primary Stream', Icons.play_circle_rounded, const Color(0xFF6C63FF),
                                widget.match.server1Url.isNotEmpty),
                            const SizedBox(height: 10),
                            _serverTile(2, 'Server 2', 'Backup Stream', Icons.play_circle_outline_rounded, const Color(0xFF00C9A7),
                                widget.match.server2Url.isNotEmpty),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => setState(() => _showServerPicker = false),
                              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (_loading)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text('Loading stream...', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                  ]),
                ),
              ),

            if (_hasError && !_loading)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.signal_wifi_off_rounded, color: Colors.white38, size: 52),
                    const SizedBox(height: 16),
                    Text('Stream Unavailable', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Try another server', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 20),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      _actionBtn('Retry', Icons.refresh_rounded, const Color(0xFF6C63FF), () {
                        setState(() { _loading = true; _hasError = false; });
                        _controller?.reload();
                      }),
                      const SizedBox(width: 12),
                      _actionBtn('Switch', Icons.dns_rounded, const Color(0xFF00C9A7), () {
                        setState(() { _showServerPicker = true; _showControls = true; _hasError = false; });
                      }),
                    ]),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _serverTile(int server, String label, String subtitle, IconData icon, Color color, bool available) {
    final isSel = _selectedServer == server;
    return GestureDetector(
      onTap: available ? () => _switchServer(server) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.1),
              width: isSel ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: available ? Colors.white : Colors.white38, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
          ])),
          if (!available)
            _badge('N/A', Colors.white24)
          else if (isSel)
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12)),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}
