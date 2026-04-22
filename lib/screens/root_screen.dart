import 'package:flutter/material.dart';
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
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.isDark ? Colors.white : Colors.black,
                    );
                  }
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: t.textMuted,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor:
                  t.isDark ? const Color(0xFF0A0A0F) : Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor:
                  (t.isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.10),
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              height: 72,
              elevation: 3,
              shadowColor: Colors.black,
              animationDuration: const Duration(milliseconds: 400),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: t.textMuted),
                  selectedIcon: Icon(Icons.home_rounded,
                      color: t.isDark ? Colors.white : Colors.black),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.animation_outlined,
                      color: t.textMuted),
                  selectedIcon: Icon(Icons.animation_rounded,
                      color: t.isDark ? Colors.white : Colors.black),
                  label: 'Anime',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined,
                      color: t.textMuted),
                  selectedIcon: Icon(Icons.search_rounded,
                      color: t.isDark ? Colors.white : Colors.black),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_border_rounded,
                      color: t.textMuted),
                  selectedIcon: Icon(Icons.bookmark_rounded,
                      color: t.isDark ? Colors.white : Colors.black),
                  label: 'Watchlist',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined,
                      color: t.textMuted),
                  selectedIcon: Icon(Icons.settings_rounded,
                      color: t.isDark ? Colors.white : Colors.black),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
