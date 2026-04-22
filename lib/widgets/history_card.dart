import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/history.dart';
import '../services/theme_service.dart';
import '../services/tmdb_service.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/tv_detail_screen.dart';
import '../screens/anime_detail_screen.dart';

class HistoryCard extends StatelessWidget {
  final HistoryItem item;
  const HistoryCard({super.key, required this.item});

  /// Build a full image URL from a stored posterPath.
  /// posterPath may be null, a full https URL, or a partial TMDB path.
  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${TmdbService.instance.imageCdnBase}/w780$path';
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    final imageUrl = _resolveImageUrl(item.posterPath);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (item.mediaType == 'movie') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => MovieDetailScreen(id: item.id)));
          } else if (item.mediaType == 'tv') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => TVDetailScreen(id: item.id)));
          } else if (item.mediaType == 'anime') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AnimeDetailScreen(id: item.id)));
          }
        },
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with overlays
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image or simple placeholder (no shimmer — perf)
                      imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              placeholder: (_, __) => _fallbackBox(t),
                              errorWidget: (_, __, ___) => _fallbackBox(t),
                            )
                          : _fallbackBox(t),

                      // Bottom gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),

                      // Play icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),

                      // Episode label
                      if (item.episode != null)
                        Positioned(
                          bottom: 6,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.season != null
                                  ? 'S${item.season} · E${item.episode}'
                                  : 'EP ${item.episode}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                      // Progress bar
                      if (item.progress > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(
                              value: item.progress.clamp(0.0, 1.0),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.22),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(t.accent),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: t.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor(item.mediaType).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.mediaType.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: _typeColor(item.mediaType),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'anime':
        return Colors.white70;
      case 'tv':
        return Colors.white60;
      default:
        return Colors.white54;
    }
  }

  Widget _fallbackBox(ThemeService t) {
    return Container(
      color: t.surface2,
      child: Icon(Icons.image_not_supported_rounded,
          color: t.textMuted, size: 28),
    );
  }
}
