import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _startSplash();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  final bool _hasError = false;

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) _navigateToApp();
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RootScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background with rotating orbs
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => CustomPaint(
              painter: _OrbsPainter(_rotateController.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Subtle vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo without glow
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 60),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shakeX(amount: 2, duration: 400.ms)
                    .then()
                    .shimmer(duration: 800.ms, color: Colors.white24),

                const SizedBox(height: 32),

                // App name
                Text(
                  'Harmber Movies',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.5, curve: Curves.easeOutCubic),

                const SizedBox(height: 10),

                // Tagline
                Text(
                  'Stream Movies & TV Shows',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.3),

                const SizedBox(height: 48),

                // iOS-style loader or error text
                if (_hasError)
                  Text(
                    'No Internet Connection',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(duration: 400.ms)
                else
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  ).animate().fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints subtle rotating gradient orbs
class _OrbsPainter extends CustomPainter {
  final double progress;
  _OrbsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final angle = progress * 2 * math.pi;

    // Orb 1 - purple
    final p1 = Offset(
      cx + math.cos(angle) * size.width * 0.25,
      cy + math.sin(angle) * size.height * 0.15,
    );
    canvas.drawCircle(
      p1,
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p1, radius: size.width * 0.35)),
    );

    // Orb 2 - blue
    final p2 = Offset(
      cx + math.cos(angle + 2.1) * size.width * 0.3,
      cy + math.sin(angle + 2.1) * size.height * 0.2,
    );
    canvas.drawCircle(
      p2,
      size.width * 0.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p2, radius: size.width * 0.3)),
    );

    // Orb 3 - teal
    final p3 = Offset(
      cx + math.cos(angle + 4.2) * size.width * 0.2,
      cy + math.sin(angle + 4.2) * size.height * 0.25,
    );
    canvas.drawCircle(
      p3,
      size.width * 0.25,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF14B8A6).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p3, radius: size.width * 0.25)),
    );
  }

  @override
  bool shouldRepaint(_OrbsPainter old) => true;
}
