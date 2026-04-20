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
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
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
      onTapDown: (_) {
        _tapController.forward();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        _tapController.reverse();
        setState(() => _pressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => movie.isTV
                ? TVDetailScreen(id: movie.id)
                : MovieDetailScreen(id: movie.id),
          ),
        );
      },
      onTapCancel: () {
        _tapController.reverse();
        setState(() => _pressed = false);
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          width: widget.width,
          margin: const EdgeInsets.only(right: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Poster ──
              SizedBox(
                height: widget.height,
                child: Stack(
                  children: [
                    // Main poster with shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: t.accent.withValues(alpha: _pressed ? 0.25 : 0.12),
                            blurRadius: 18,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: movie.posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: movie.posterUrl,
                                width: widget.width,
                                height: widget.height,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _placeholder(t),
                                errorWidget: (_, __, ___) =>
                                    _placeholder(t),
                              )
                            : _placeholder(t),
                      ),
                    ),

                    // Bottom gradient info bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFD700), size: 12),
                              const SizedBox(width: 3),
                              Text(
                                movie.rating,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (movie.year != 'N/A')
                                Text(
                                  movie.year,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Glass border overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    // TV badge
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
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
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

              const SizedBox(height: 9),

              // Title
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: t.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

  Widget _placeholder(ThemeService t) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(Icons.movie_outlined,
            color: t.textMuted.withValues(alpha: 0.5), size: 36),
      ),
    );
  }
}
