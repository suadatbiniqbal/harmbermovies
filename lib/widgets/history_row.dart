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
            ? allItems.where((i) => i.mediaType == 'movie' || i.mediaType == 'tv').toList()
            : allItems.where((i) => i.mediaType == 'anime').toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: t.accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Watching',
                    style: GoogleFonts.inter(
                      color: t.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
