import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: t.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: t.surface,
              surfaceTintColor: Colors.transparent,
              indicatorColor:
                  Colors.white.withValues(alpha: t.isDark ? 0.1 : 0.0),
              selectedIndex: _index,
              onDestinationSelected: _onDestinationSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 72,
              elevation: 0,
              animationDuration: const Duration(milliseconds: 400),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: t.textMuted),
                  selectedIcon: Icon(Icons.home_rounded,
                          color: t.isDark ? Colors.white : Colors.black)
                      .animate(target: _index == 0 ? 1 : 0)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms,
                      ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded, color: t.textMuted),
                  selectedIcon: Icon(Icons.search_rounded,
                          color: t.isDark ? Colors.white : Colors.black)
                      .animate(target: _index == 1 ? 1 : 0)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms,
                      ),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_border_rounded, color: t.textMuted),
                  selectedIcon: Icon(Icons.bookmark_rounded,
                          color: t.isDark ? Colors.white : Colors.black)
                      .animate(target: _index == 2 ? 1 : 0)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms,
                      ),
                  label: 'Watchlist',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: t.textMuted),
                  selectedIcon: Icon(Icons.settings_rounded,
                          color: t.isDark ? Colors.white : Colors.black)
                      .animate(target: _index == 3 ? 1 : 0)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms,
                      ),
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
