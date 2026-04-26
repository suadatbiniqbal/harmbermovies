import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'anime_home_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final PageController _pageController;

  final _screens = const [
    HomeScreen(),
    AnimeHomeScreen(),
    SearchScreen(),
    WatchlistScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final t = ThemeService.instance;

        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
          extendBody: true,
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: t.isDark
                      ? const Color(0xFF08080C).withValues(alpha: 0.82)
                      : Colors.white.withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(
                      color: t.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (i) {
                        final isSelected = _index == i;
                        final icons = [
                          Icons.home_rounded,
                          Icons.animation_rounded,
                          Icons.search_rounded,
                          Icons.bookmark_rounded,
                          Icons.settings_rounded,
                        ];
                        final outlinedIcons = [
                          Icons.home_outlined,
                          Icons.animation_outlined,
                          Icons.search_outlined,
                          Icons.bookmark_border_rounded,
                          Icons.settings_outlined,
                        ];
                        final labels = [
                          'Home',
                          'Anime',
                          'Search',
                          'Watchlist',
                          'Settings',
                        ];
                        return _NavItem(
                          icon: isSelected ? icons[i] : outlinedIcons[i],
                          label: labels[i],
                          isSelected: isSelected,
                          onTap: () => _onDestinationSelected(i),
                          accent: t.accent,
                          textColor: t.text,
                          mutedColor: t.textMuted,
                          isDark: t.isDark,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? accent
                    : mutedColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? accent
                    : mutedColor.withValues(alpha: 0.7),
                letterSpacing: isSelected ? 0.1 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
