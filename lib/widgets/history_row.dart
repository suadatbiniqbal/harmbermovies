import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/history_service.dart';
import '../services/theme_service.dart';
import 'history_card.dart';

class HistoryRow extends StatelessWidget {
  final String mediaTypeFilter; // 'tmdb' (for movies/tv) or 'anime'
  const HistoryRow({super.key, required this.mediaTypeFilter});

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    return ListenableBuilder(
      listenable: HistoryService.instance,
      builder: (context, _) {
        final allItems = HistoryService.instance.items;
        final items = mediaTypeFilter == 'tmdb'
            ? allItems
                .where((i) => i.mediaType == 'movie' || i.mediaType == 'tv')
                .toList()
            : allItems.where((i) => i.mediaType == 'anime').toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child:
                        Icon(Icons.history_rounded, color: t.accent, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue Watching',
                    style: GoogleFonts.inter(
                      color: t.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 162,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, i) => HistoryCard(item: items[i]),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
