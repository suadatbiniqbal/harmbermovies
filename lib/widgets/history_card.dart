import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/history.dart';
import '../services/theme_service.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/tv_detail_screen.dart';
import '../screens/anime_detail_screen.dart';

class HistoryCard extends StatelessWidget {
  final HistoryItem item;
  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    return GestureDetector(
      onTap: () {
        if (item.mediaType == 'movie') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(id: item.id)));
        } else if (item.mediaType == 'tv') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TVDetailScreen(id: item.id)));
        } else if (item.mediaType == 'anime') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AnimeDetailScreen(id: item.id)));
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.posterPath != null && item.posterPath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.posterPath!,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : Container(color: t.surface2),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 32),
                    ),
                    if (item.episode != null)
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: Text(
                          item.season != null
                              ? 'S${item.season} E${item.episode}'
                              : 'EP ${item.episode}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: t.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              item.mediaType.toUpperCase(),
              style: GoogleFonts.inter(
                color: t.accent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
