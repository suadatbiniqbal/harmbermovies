import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  bool _isDark = true;
  bool get isDark => _isDark;

  static const _key = 'theme_dark';

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, _isDark);
    notifyListeners();
  }

  static const Color _accent = Color(0xFFE50914);

  Color get accent => _accent;
  Color get bg => _isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF4F4F8);
  Color get surface =>
      _isDark ? const Color(0xFF13131A) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      _isDark ? const Color(0xFF1A1A26) : const Color(0xFFEEEEF4);
  Color get border =>
      _isDark ? const Color(0xFF2A2A3A) : const Color(0xFFDDDDE8);
  Color get divider =>
      _isDark ? const Color(0xFF232330) : const Color(0xFFDDDDE5);
  Color get text => _isDark ? const Color(0xFFF0F0F8) : const Color(0xFF111118);
  Color get textMuted =>
      _isDark ? const Color(0xFF9090A8) : const Color(0xFF55556A);
  Color get accentSurface => _accent.withValues(alpha: _isDark ? 0.12 : 0.10);
  Color get accentBorder => _accent.withValues(alpha: _isDark ? 0.30 : 0.25);
  Color get accentLight => _isDark ? _accent.withValues(alpha: 0.85) : _accent;

  ThemeData get materialTheme => ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme(
          brightness: _isDark ? Brightness.dark : Brightness.light,
          primary: _accent,
          onPrimary: Colors.white,
          secondary: _accent,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: surface,
          onSurface: text,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
        ),
        useMaterial3: true,
      );
}
