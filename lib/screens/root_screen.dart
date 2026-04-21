import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _RootScreenState extends State<RootScreen> {
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
    setState(() => _index = i);
    _pageController.jumpToPage(i);
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
          bottomNavigationBar: _buildBottomBar(t),
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeService t) {
    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.animation_outlined, activeIcon: Icons.animation_rounded, label: 'Anime'),
      _NavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Search'),
      _NavItem(icon: Icons.bookmark_border_rounded, activeIcon: Icons.bookmark_rounded, label: 'Watchlist'),
      _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.black.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: t.border.withValues(alpha: 0.5), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: t.isDark ? 0.3 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(
              items.length,
              (i) => Expanded(child: _buildNavItem(items[i], i, t)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int i, ThemeService t) {
    final selected = _index == i;
    final activeColor = t.accent;
    final inactiveColor = t.textMuted;

    return GestureDetector(
      onTap: () => _onDestinationSelected(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? activeColor : inactiveColor,
                size: 22,
              )
                  .animate(target: selected ? 1 : 0)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    duration: 200.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                color: selected ? activeColor : inactiveColor,
                fontSize: selected ? 10.5 : 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
