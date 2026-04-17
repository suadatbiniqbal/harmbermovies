import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/theme_service.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/tv_detail_screen.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final double width;
  final double height;
  final int index;

  const MovieCard({
    super.key,
    required this.movie,
    this.width = 140,
    this.height = 210,
    this.index = 0,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    final movie = widget.movie;

    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => movie.isTV
                ? TVDetailScreen(id: movie.id)
                : MovieDetailScreen(id: movie.id),
          ),
        );
      },
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          width: widget.width,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster with glow shadow
              Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: t.accent.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      movie.posterUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: movie.posterUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _posterPlaceholder(t),
                              errorWidget: (_, __, ___) =>
                                  _posterPlaceholder(t),
                            )
                          : _posterPlaceholder(t),

                      // Subtle gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Glassmorphism border overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      // Rating badge with glassmorphism
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFD700), size: 12),
                              const SizedBox(width: 3),
                              Text(
                                movie.rating,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // TV badge with gradient
                      if (movie.isTV)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1), 
                                  Color(0xFF8B5CF6)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'TV',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: t.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              // Year
              Text(
                movie.year,
                style: GoogleFonts.inter(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (50 * widget.index).ms, duration: 400.ms)
        .slideX(begin: 0.06, curve: Curves.easeOutCubic);
  }

  Widget _posterPlaceholder(ThemeService t) {
    return Container(
      color: t.surface2,
      child: Center(
        child: Icon(Icons.movie_outlined, color: t.textMuted, size: 32),
      ),
    );
  }
}
