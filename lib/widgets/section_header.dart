import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: t.text, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: t.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all →',
                style: GoogleFonts.inter(
                  color: t.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
