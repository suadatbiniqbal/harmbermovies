import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        foregroundColor: t.text,
        title: Text('About',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Logo section
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 50),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Harmber Movies',
                  style: GoogleFonts.inter(
                    color: t.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.inter(color: t.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.border),
                  ),
                  child: Text(
                    'Stream Movies & TV Shows',
                    style: GoogleFonts.inter(
                      color: t.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // GitHub releases card
          GestureDetector(
            onTap: () => _openUrl(
                'https://github.com/suadatbiniqbal/harmbermovies/releases'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.code_rounded,
                        color: t.isDark ? Colors.white : Colors.black,
                        size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GitHub Releases',
                            style: GoogleFonts.inter(
                                color: t.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text('Download latest APK & view changelog',
                            style: GoogleFonts.inter(
                                color: t.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, color: t.textMuted, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About the App',
                    style: GoogleFonts.inter(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  'Harmber Movies is a premium streaming discovery app that lets you explore, search, and watch movies and TV shows from a vast library. '
                  'Browse trending content, discover new releases, explore genres, and save your favorites to your personal watchlist.\n\n'
                  'Our platform provides detailed information about every title, including cast details, images, ratings, and much more.',
                  style: GoogleFonts.inter(
                      color: t.textMuted, fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Features
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Features',
                    style: GoogleFonts.inter(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _featureRow(Icons.movie_rounded, 'Vast Movie Library', t),
                _featureRow(Icons.tv_rounded, 'TV Shows & Series', t),
                _featureRow(Icons.search_rounded, 'Smart Search', t),
                _featureRow(Icons.category_rounded, 'Genre Categories', t),
                _featureRow(Icons.bookmark_rounded, 'Personal Watchlist', t),
                _featureRow(Icons.person_rounded, 'Artist Profiles', t),
                _featureRow(Icons.dark_mode_rounded, 'Dark & Light Themes', t),
                _featureRow(Icons.play_circle_rounded, 'Built-in Player', t),
                _featureRow(
                    Icons.notifications_rounded, 'Push Notifications', t),
                _featureRow(Icons.update_rounded, 'Auto Update Check', t),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Credits
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credits',
                    style: GoogleFonts.inter(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _creditRow(
                    Icons.api_rounded, 'Data by TMDB', 'themoviedb.org', t),
                _creditRow(
                    Icons.code_rounded, 'Built with Flutter', 'flutter.dev', t),
                _creditRow(Icons.play_circle_outline, 'Player by harmber',
                    'harmber.xyz', t),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: t.textMuted, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This product uses the TMDB API but is not endorsed or certified by TMDB. All movie data and images are provided by The Movie Database.',
                    style: GoogleFonts.inter(
                        color: t.textMuted, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Made with ❤️',
              style: GoogleFonts.inter(color: t.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, ThemeService t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon,
              color: t.isDark ? Colors.white70 : Colors.black87, size: 20),
          const SizedBox(width: 12),
          Text(text,
              style: GoogleFonts.inter(
                  color: t.text, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _creditRow(
      IconData icon, String title, String subtitle, ThemeService t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon,
              color: t.isDark ? Colors.white70 : Colors.black87, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      color: t.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.inter(color: t.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
