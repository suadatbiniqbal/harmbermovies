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

  // ── Premium Movie Red (Netflix Style) ──
  static const Color _accent = Color(0xFFE50914);
  Color get accent => _accent;

  // ── Deep Cinema Colors ──
  Color get bg =>
      _isDark ? const Color(0xFF000000) : const Color(0xFFF9F9F9);
  Color get surface =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2);
  Color get surface3 =>
      _isDark ? const Color(0xFF242424) : const Color(0xFFE8E8E8);
  Color get border =>
      _isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
  Color get divider =>
      _isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE);
  Color get text =>
      _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get textMuted =>
      _isDark ? const Color(0xFFB3B3B3) : const Color(0xFF666666);

  Color get accentSurface => _accent.withOpacity(_isDark ? 0.12 : 0.08);
  Color get accentBorder => _accent.withOpacity(_isDark ? 0.35 : 0.25);

  Color get shimmerBase => _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0);
  Color get shimmerHighlight => _isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0);

  ThemeData get materialTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: _isDark ? Brightness.dark : Brightness.light,
      primary: _accent,
      surface: surface,
      onSurface: text,
      secondary: _accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: _isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme.copyWith(
        surface: surface,
        onSurface: text,
        primary: _accent,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withOpacity(0.8),
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: _accent.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent);
          }
          return IconThemeData(color: textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: textMuted, fontSize: 12);
        }),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
