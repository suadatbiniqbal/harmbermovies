import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  double _scale = 1.0;
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    // Staggered entrance — each card delays based on index
    final delay = (widget.index * 60).clamp(0, 400);
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.94);
  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.movie.isTV
            ? TVDetailScreen(id: widget.movie.id)
            : MovieDetailScreen(id: widget.movie.id),
      ),
    );
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    final movie = widget.movie;

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeInOut,
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
                        clipBehavior: Clip.none,
                        children: [
                          // Shadow container
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.55),
                                    blurRadius: 18,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Poster image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: widget.width,
                              height: widget.height,
                              child: movie.posterUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: movie.posterUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          _placeholder(t),
                                      errorWidget: (_, __, ___) =>
                                          _placeholder(t),
                                    )
                                  : _placeholder(t),
                            ),
                          ),

                          // Bottom info gradient
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16)),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                    9, 28, 9, 9),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black
                                          .withValues(alpha: 0.92),
                                      Colors.black
                                          .withValues(alpha: 0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFFFFD700),
                                        size: 12),
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
                                          color: Colors.white60,
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
                                  color: Colors.white
                                      .withValues(alpha: 0.09),
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
                              child:
                                  _badge('TV', icon: Icons.tv_rounded),
                            ),
                        ],
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(7),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 10),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
            color: t.textMuted.withValues(alpha: 0.4), size: 32),
      ),
    );
  }
}
