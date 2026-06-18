import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/iptv_channel.dart';

class IptvPlayerScreen extends StatefulWidget {
  final IptvChannel channel;
  final List<IptvChannel> allChannels;

  const IptvPlayerScreen({
    super.key,
    required this.channel,
    this.allChannels = const [],
  });

  @override
  State<IptvPlayerScreen> createState() => _IptvPlayerScreenState();
}

class _IptvPlayerScreenState extends State<IptvPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  late IptvChannel _current;

  bool _loading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _showChannelList = false;
  bool _isBuffering = false;

  Timer? _controlsTimer;
  Timer? _progressTimer;

  late AnimationController _liveCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.channel;
    _liveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer(_current);
    _startControlsTimer();
  }

  Future<void> _initPlayer(IptvChannel ch) async {
    setState(() { _loading = true; _hasError = false; });

    // Dispose old controller
    await _vpc?.dispose();
    _vpc = null;
    _progressTimer?.cancel();

    try {
      final uri = Uri.parse(ch.manifestUri);
      final ctrl = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
          'Origin': 'https://www.google.com',
          'Referer': 'https://www.google.com/',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await ctrl.initialize();

      if (!mounted) { ctrl.dispose(); return; }

      ctrl.addListener(_onPlayerUpdate);
      ctrl.play();

      setState(() {
        _vpc = ctrl;
        _loading = false;
        _hasError = false;
      });

      // Progress timer for live indicator pulse
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _hasError = true; });
    }
  }

  void _onPlayerUpdate() {
    if (!mounted || _vpc == null) return;
    final isBuffering = _vpc!.value.isBuffering;
    if (isBuffering != _isBuffering) {
      setState(() => _isBuffering = isBuffering);
    }
    if (_vpc!.value.hasError) {
      setState(() { _hasError = true; _loading = false; });
    }
  }

  void _switchChannel(IptvChannel ch) {
    setState(() {
      _current = ch;
      _showChannelList = false;
    });
    _initPlayer(ch);
    _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
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
    _progressTimer?.cancel();
    _liveCtrl.dispose();
    _vpc?.removeListener(_onPlayerUpdate);
    _vpc?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showChannelList) {
            setState(() => _showChannelList = false);
          } else {
            _toggleControls();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Native Video
            if (_vpc != null && _vpc!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _vpc!.value.aspectRatio,
                  child: VideoPlayer(_vpc!),
                ),
              )
            else
              Container(color: Colors.black),

            // Buffering spinner (subtle)
            if (_isBuffering && !_hasError && !_loading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                ),
              ),

            // Controls overlay
            if (_showControls && !_showChannelList && !_loading && !_hasError)
              _buildControls(),

            // Channel list
            if (_showChannelList)
              _buildChannelList()
                  .animate()
                  .slideX(begin: 0.2, duration: 220.ms, curve: Curves.easeOutCubic)
                  .fadeIn(duration: 200.ms),

            // Loading
            if (_loading)
              _buildLoading(),

            // Error
            if (_hasError && !_loading)
              _buildError(),
          ],
        ),
      ),
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  Widget _buildControls() {
    return Stack(
      children: [
        // Top gradient
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xDD000000), Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom gradient
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Color(0xBB000000), Colors.transparent],
              ),
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Logo + name
                if (_current.logoUrl.isNotEmpty) ...[
                  CachedNetworkImage(
                    imageUrl: _current.logoUrl,
                    width: 28, height: 28, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_current.name,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      // Live dot
                      AnimatedBuilder(
                        animation: _liveCtrl,
                        builder: (_, __) => Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: Color.lerp(Colors.red, Colors.red.withValues(alpha: 0.4), _liveCtrl.value),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('LIVE', style: GoogleFonts.inter(
                                color: Colors.red, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Channel list btn
                if (widget.allChannels.length > 1)
                  GestureDetector(
                    onTap: () {
                      _controlsTimer?.cancel();
                      setState(() => _showChannelList = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.live_tv_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text('Channels',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom play/pause control
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_vpc == null) return;
                  _vpc!.value.isPlaying ? _vpc!.pause() : _vpc!.play();
                  _startControlsTimer();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Icon(
                    _vpc?.value.isPlaying == true
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white, size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Channel List ──────────────────────────────────────────────────────────
  Widget _buildChannelList() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showChannelList = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 260, height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F0F1A), Color(0xFF0A0A12)],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text('Channels', style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _showChannelList = false),
                            child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.allChannels.length,
                        itemBuilder: (_, i) {
                          final ch = widget.allChannels[i];
                          final isCurrent = ch.id == _current.id;
                          return GestureDetector(
                            onTap: () => _switchChannel(ch),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.red.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A2E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ch.logoUrl.isNotEmpty
                                          ? CachedNetworkImage(imageUrl: ch.logoUrl, fit: BoxFit.contain,
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(Icons.live_tv_rounded, color: Colors.white38, size: 18))
                                          : const Icon(Icons.live_tv_rounded, color: Colors.white38, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(ch.name,
                                        style: GoogleFonts.inter(
                                          color: isCurrent ? Colors.white : Colors.white60,
                                          fontSize: 13,
                                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.play_arrow_rounded,
                                          color: Colors.white, size: 10),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() => Container(
    color: Colors.black,
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 44, height: 44,
          child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2.5),
        ),
        const SizedBox(height: 18),
        Text('Loading stream…', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 4),
        Text(_current.name, style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
      ]),
    ),
  );

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() => Container(
    color: Colors.black,
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.signal_wifi_off_rounded, color: Colors.white24, size: 52),
        const SizedBox(height: 16),
        Text('Stream Unavailable',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Could not connect to "${_current.name}"',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 24),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _actionBtn('Retry', Icons.refresh_rounded,
              Colors.red, () => _switchChannel(_current)),
          if (widget.allChannels.length > 1) ...[
            const SizedBox(width: 12),
            _actionBtn('Channels', Icons.live_tv_rounded,
                Colors.white70, () {
              setState(() { _showChannelList = true; _hasError = false; });
            }),
          ],
        ]),
      ]),
    ),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
