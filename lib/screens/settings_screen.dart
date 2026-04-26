import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../widgets/ad_banner.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? _updateInfo;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    final info = await UpdateService.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _updateInfo = info;
      _checkingUpdate = false;
    });
  }

  void _openUpdate() async {
    if (_updateInfo == null) return;
    final url = UpdateService.getApkUrl(_updateInfo!) ??
        'https://github.com/suadatbiniqbal/harmbermovies/releases';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final t = ThemeService.instance;
        int cardIndex = 0;

        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 8),
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    color: t.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // App branding card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: t.isDark
                          ? [const Color(0xFF151525), const Color(0xFF0E0E1B)]
                          : [Colors.grey.shade100, Colors.grey.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: t.isDark ? 0.2 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo_main.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A1A1A),
                                    Color(0xFF2A2A2A),
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harmber Movies',
                              style: GoogleFonts.inter(
                                color: t.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${UpdateService.currentVersion}',
                                style: GoogleFonts.inter(
                                  color: t.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AdBannerContainer(),
                const SizedBox(height: 16),

                // Update banner
                if (_updateInfo != null) ...[
                  GestureDetector(
                    onTap: _openUpdate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B5E20).withValues(alpha: 0.15),
                            const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.system_update_rounded,
                                color: Color(0xFF4CAF50), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Available!',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF4CAF50),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${_updateInfo!['tag_name']} • Tap to download',
                                  style: GoogleFonts.inter(
                                    color: t.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.download_rounded,
                                color: Color(0xFF4CAF50), size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section label
                _sectionLabel('General', t, cardIndex++),
                const SizedBox(height: 8),

                // Dark mode
                _settingsCard(
                  t,
                  icon: t.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: t.isDark ? 'Currently dark' : 'Currently light',
                  trailing: Switch.adaptive(
                    value: t.isDark,
                    onChanged: (_) => t.toggle(),
                    activeTrackColor: t.accent,
                    activeThumbColor: Colors.black,
                    inactiveTrackColor: t.surface2,
                  ),
                  index: cardIndex++,
                ),

                const SizedBox(height: 20),
                _sectionLabel('App', t, cardIndex++),
                const SizedBox(height: 8),

                _settingsCard(
                  t,
                  icon: Icons.update_rounded,
                  title: 'Check for Updates',
                  subtitle: _checkingUpdate
                      ? 'Checking...'
                      : _updateInfo != null
                          ? 'New version available!'
                          : 'You\'re up to date',
                  onTap: _checkUpdate,
                  trailing: _checkingUpdate
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.textMuted,
                          ),
                        )
                      : null,
                  index: cardIndex++,
                ),

                _settingsCard(
                  t,
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'App info & credits',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutScreen())),
                  index: cardIndex++,
                ),

                _settingsCard(
                  t,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Push notifications enabled',
                  index: cardIndex++,
                ),

                const SizedBox(height: 20),
                _sectionLabel('Links', t, cardIndex++),
                const SizedBox(height: 8),

                _settingsCard(
                  t,
                  icon: Icons.code_rounded,
                  title: 'GitHub',
                  subtitle: 'View source & releases',
                  onTap: () async {
                    final uri = Uri.parse(
                        'https://github.com/suadatbiniqbal/harmbermovies/releases');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  index: cardIndex++,
                ),

                _settingsCard(
                  t,
                  icon: Icons.forum_rounded,
                  title: 'Discord',
                  subtitle: 'Join our community',
                  onTap: () async {
                    final uri = Uri.parse('https://discord.gg/BMTnet53E6');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  index: cardIndex++,
                ),

                _settingsCard(
                  t,
                  icon: Icons.movie_filter_rounded,
                  title: 'Data Source',
                  subtitle: 'Powered by TMDB',
                  index: cardIndex++,
                ),

                _settingsCard(
                  t,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  index: cardIndex++,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text, ThemeService t, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: t.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsCard(
    ThemeService t, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    int index = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: t.isDark ? 0.12 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: t.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon,
                    color: t.isDark ? Colors.white : Colors.black, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: t.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(Icons.chevron_right_rounded,
                          color: t.textMuted, size: 22)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
