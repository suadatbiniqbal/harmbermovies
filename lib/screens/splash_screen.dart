import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  static const String _adUrl =
      'https://www.profitablecpmratenetwork.com/hpp7szbwc?key=e427111ef791f9b6b39b05710a5e3ca2';
  static const String _lastAdKey = 'last_ad_shown_time';
  static const int _adCooldownHours = 6;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _startSplashFlow();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  Future<bool> _shouldShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_lastAdKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceLastAd =
        (now - lastShown) / (1000 * 60 * 60);
    return hoursSinceLastAd >= _adCooldownHours;
  }

  Future<void> _markAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAdKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _startSplashFlow() async {
    // Phase 1: Show splash animation for 2.5s
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Phase 2: Check if we should show ad (6-hour cooldown)
    final showAd = await _shouldShowAd();

    if (showAd) {
      try {
        final uri = Uri.parse(_adUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _markAdShown();
        _showToast('Opening Sponser Page Support us and  Wait for the page to load, then come back and enjoy the show!');
      } catch (_) {
        // If browser launch fails, just continue
      }

      // Wait a bit before navigating to app
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (mounted) _navigateToApp();
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: const Color(0xFF1A1A2E),
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      fontSize: 13,
    );
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background with rotating orbs
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => CustomPaint(
              painter: _OrbsPainter(_rotateController.value),
              size: size,
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

          // Centered logo and text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
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
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 60),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App name
                Text(
                  'Harmber Movies',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Stream Movies & TV Shows',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Loading spinner at bottom
          Positioned(
            bottom: size.height * 0.18,
            left: 0,
            right: 0,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
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
        ).createShader(
            Rect.fromCircle(center: p1, radius: size.width * 0.35)),
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
        ).createShader(
            Rect.fromCircle(center: p2, radius: size.width * 0.3)),
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
        ).createShader(
            Rect.fromCircle(center: p3, radius: size.width * 0.25)),
    );
  }

  @override
  bool shouldRepaint(_OrbsPainter old) => true;
}
