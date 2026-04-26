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

  // ── Original Action Red ──
  static const Color _accent = Color(0xFFE50914);

  Color get accent => _accent;

  // ── Dark mode: deep charcoal layers with subtle blue undertone ──
  // ── Light mode: warm off-white with soft gray surfaces ──
  Color get bg =>
      _isDark ? const Color(0xFF08080C) : const Color(0xFFF7F6F3);
  Color get surface =>
      _isDark ? const Color(0xFF101016) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      _isDark ? const Color(0xFF18181F) : const Color(0xFFEFEEEB);
  Color get surface3 =>
      _isDark ? const Color(0xFF1F1F28) : const Color(0xFFE5E4E0);
  Color get border =>
      _isDark ? const Color(0xFF28283A) : const Color(0xFFDCDBD6);
  Color get divider =>
      _isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE3E2DD);
  Color get text =>
      _isDark ? const Color(0xFFF2F0EB) : const Color(0xFF141310);
  Color get textMuted =>
      _isDark ? const Color(0xFF8A8898) : const Color(0xFF6B6A64);

  // ── Accent derivatives ──
  Color get accentSurface => _accent.withValues(alpha: _isDark ? 0.10 : 0.08);
  Color get accentBorder => _accent.withValues(alpha: _isDark ? 0.28 : 0.22);
  Color get accentLight => _isDark ? _accent.withValues(alpha: 0.88) : _accent;

  // ── Convenience ──
  Color get shimmerBase => _isDark ? const Color(0xFF151520) : const Color(0xFFEBEAE6);
  Color get shimmerHighlight => _isDark ? const Color(0xFF1C1C28) : const Color(0xFFF5F4F0);

  // ── Card glow shadow ──
  Color get cardShadow =>
      _isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.08);

  ThemeData get materialTheme => ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme(
          brightness: _isDark ? Brightness.dark : Brightness.light,
          primary: _accent,
          onPrimary: Colors.black,
          secondary: _accent,
          onSecondary: Colors.black,
          error: const Color(0xFFCF6679),
          onError: Colors.black,
          surface: surface,
          onSurface: text,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        splashFactory: InkSparkle.splashFactory,
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: border, width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        useMaterial3: true,
      );
}
