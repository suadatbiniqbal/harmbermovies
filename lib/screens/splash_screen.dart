import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _spinnerOpacity;
  late Animation<double> _pulseAnim;



  @override
  void initState() {
    super.initState();

    // Rotating orbs — slow continuous loop
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Logo entrance — scale up + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Content stagger — title then tagline then spinner
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));
    _spinnerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Logo breathing/pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer bar sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Kick off animation sequence
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Precache logo so it shows instantly — no white flash on first run
    if (mounted) {
      await precacheImage(
        const AssetImage('assets/logo.png'),
        context,
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _contentController.forward();

    // Start splash flow after animations settle
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _handleSplashFlow();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _logoController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleSplashFlow() {
    if (mounted) _navigateToApp();
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RootScreen(),
        transitionsBuilder: (_, a, __, child) {
          final fade = CurvedAnimation(parent: a, curve: Curves.easeInOut);
          return FadeTransition(opacity: fade, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Rotating orbs ──
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, __) => CustomPaint(
              painter: _OrbsPainter(_orbController.value),
            ),
          ),

          // ── Radial vignette ──
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),

          // ── Centered content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with scale + fade + pulse
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_logoController, _pulseController]),
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value * _pulseAnim.value,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.15 + 0.05 * _pulseAnim.value),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white
                                  .withValues(alpha: 0.06 * _pulseAnim.value),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: const Color(0xFF1A1A1A),
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Title — slide up + fade
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (_, __) => SlideTransition(
                    position: _titleSlide,
                    child: Opacity(
                      opacity: _titleOpacity.value,
                      child: Text(
                        'Harmber Movies',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline — staggered slide up + fade
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (_, __) => SlideTransition(
                    position: _taglineSlide,
                    child: Opacity(
                      opacity: _taglineOpacity.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 24, height: 1, color: Colors.white24),
                          const SizedBox(width: 12),
                          Text(
                            'STREAM  ·  WATCH  ·  ENJOY',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                              width: 24, height: 1, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom loading area ──
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (_, __) => Opacity(
                opacity: _spinnerOpacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated shimmer bar instead of spinner
                    SizedBox(
                      width: 64,
                      height: 3,
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (_, __) => CustomPaint(
                          painter: _ShimmerBarPainter(
                              _shimmerController.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Loading...',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Bar Painter ──
class _ShimmerBarPainter extends CustomPainter {
  final double progress;
  _ShimmerBarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Background track
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Moving highlight
    final center = progress * size.width;
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final shaderRect = Rect.fromCenter(
      center: Offset(center, size.height / 2),
      width: size.width * 0.5,
      height: size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..shader = gradient.createShader(shaderRect),
    );
  }

  @override
  bool shouldRepaint(_ShimmerBarPainter old) => old.progress != progress;
}

// ── Toast Overlay Widget ──
class _ToastWidget extends StatefulWidget {
  final String message;
  const _ToastWidget({required this.message});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(
        const Duration(seconds: 3), () => _ctrl.reverse());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_anim),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Orbs Painter ──
class _OrbsPainter extends CustomPainter {
  final double progress;
  _OrbsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final angle = progress * 2 * math.pi;

    void drawOrb(Offset center, double radius, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: alpha),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    drawOrb(
      Offset(cx + math.cos(angle) * size.width * 0.25,
          cy + math.sin(angle) * size.height * 0.15),
      size.width * 0.35,
      0.07,
    );
    drawOrb(
      Offset(cx + math.cos(angle + 2.1) * size.width * 0.3,
          cy + math.sin(angle + 2.1) * size.height * 0.2),
      size.width * 0.3,
      0.05,
    );
    drawOrb(
      Offset(cx + math.cos(angle + 4.2) * size.width * 0.2,
          cy + math.sin(angle + 4.2) * size.height * 0.25),
      size.width * 0.25,
      0.04,
    );
  }

  @override
  bool shouldRepaint(_OrbsPainter old) => old.progress != progress;
}
