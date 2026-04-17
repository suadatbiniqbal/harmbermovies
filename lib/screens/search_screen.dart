import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/theme_service.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';
import 'artists_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _controller = TextEditingController();
  final _api = TmdbService.instance;
  Timer? _debounce;
  List<Movie> _results = [];
  List<Genre> _genres = [];
  bool _searching = false;
  bool _loadingGenres = true;
  bool _hasError = false;

  static const _genreColors = [
    [Color(0xFFE50914), Color(0xFF831010)],
    [Color(0xFF667EEA), Color(0xFF3B49DF)],
    [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    [Color(0xFFFF6B35), Color(0xFFD84315)],
    [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
    [Color(0xFF00BCD4), Color(0xFF00838F)],
    [Color(0xFFFF5252), Color(0xFFC62828)],
    [Color(0xFF3F51B5), Color(0xFF1A237E)],
    [Color(0xFFFF9800), Color(0xFFE65100)],
    [Color(0xFF009688), Color(0xFF004D40)],
    [Color(0xFF795548), Color(0xFF3E2723)],
    [Color(0xFFE91E63), Color(0xFF880E4F)],
    [Color(0xFF607D8B), Color(0xFF37474F)],
    [Color(0xFF8BC34A), Color(0xFF558B2F)],
    [Color(0xFFCDDC39), Color(0xFF9E9D24)],
    [Color(0xFF2196F3), Color(0xFF0D47A1)],
    [Color(0xFFFF7043), Color(0xFFBF360C)],
    [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
    [Color(0xFF26C6DA), Color(0xFF00695C)],
  ];

  static const _genreIcons = <int, IconData>{
    28: Icons.local_fire_department_rounded,
    12: Icons.explore_rounded,
    16: Icons.animation_rounded,
    35: Icons.sentiment_very_satisfied_rounded,
    80: Icons.security_rounded,
    99: Icons.camera_alt_rounded,
    18: Icons.theater_comedy_rounded,
    10751: Icons.family_restroom_rounded,
    14: Icons.auto_awesome_rounded,
    36: Icons.history_edu_rounded,
    27: Icons.nightlight_rounded,
    10402: Icons.music_note_rounded,
    9648: Icons.psychology_rounded,
    10749: Icons.favorite_rounded,
    878: Icons.rocket_launch_rounded,
    10770: Icons.tv_rounded,
    53: Icons.warning_rounded,
    10752: Icons.shield_rounded,
    37: Icons.landscape_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _api.getMovieGenres();
      if (genres.isEmpty) throw Exception('Network error');
      if (!mounted) return;
      setState(() {
        _genres = genres;
        _loadingGenres = false;
        _hasError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingGenres = false;
          _hasError = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final term = query.trim();
    if (term.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await _api.searchMulti(term);
        if (!mounted || _controller.text.trim() != term) return;
        setState(() {
          _results = results;
          _searching = false;
        });
      } catch (_) {
        if (mounted && _controller.text.trim() == term) {
          setState(() => _searching = false);
        }
      }
    });
  }

  void _openGenre(Genre genre) async {
    try {
      final movies = await _api.getMoviesByGenre(genre.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _GenreResultsScreen(genre: genre, movies: movies),
        ),
      );
    } catch (_) {
      // Ignored for now, fallback to empty screen or no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: t.isDark ? 0.2 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(color: t.text, fontSize: 16),
                  cursorColor: t.accent,
                  decoration: InputDecoration(
                    hintText: 'Search movies, TV shows, actors...',
                    hintStyle: GoogleFonts.inter(color: t.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: t.textMuted),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: t.textMuted),
                            onPressed: () {
                              _controller.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

            // Content
            Expanded(
              child: Column(
                children: [
                  const AdBannerContainer(),
                  Expanded(
                    child: _controller.text.isNotEmpty
                        ? _buildSearchResults(t)
                        : _buildGenresGrid(t),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeService t) {
    if (_searching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: t.accent),
            ),
            const SizedBox(height: 12),
            Text('Searching...',
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: t.textMuted, size: 64)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 1500.ms, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            Text('No results found',
                style: GoogleFonts.inter(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Try a different search term',
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 14)),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }
      return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        childAspectRatio: 0.52,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final m = _results[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                if (m.mediaType == 'person') return ArtistScreen(id: m.id);
                if (m.isTV) return TVDetailScreen(id: m.id);
                return MovieDetailScreen(id: m.id);
              },
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        m.posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: m.posterUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) =>
                                    Container(color: t.surface2),
                                errorWidget: (_, __, ___) =>
                                    Container(color: t.surface2),
                              )
                            : Container(
                                color: t.surface2,
                                child: Icon(m.mediaType == 'person' ? Icons.person : Icons.movie, color: t.textMuted),
                              ),
                        if (m.isTV || m.mediaType == 'person')
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [t.accent, t.accent.withValues(alpha: 0.8)],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(m.mediaType == 'person' ? 'PERSON' : 'TV',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                m.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                m.mediaType == 'person' ? 'Actor' : m.year,
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 11),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (40 * i).ms, duration: 350.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.0, 1.0),
              delay: (40 * i).ms,
              duration: 350.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Widget _buildGenresGrid(ThemeService t) {
    if (_loadingGenres) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: t.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load genres\nPlease check your connection',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: t.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadingGenres = true;
                  _hasError = false;
                });
                _loadGenres();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Browse Categories',
          style: GoogleFonts.inter(
            color: t.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_genres.length, (i) {
            final genre = _genres[i];
            final colors = _genreColors[i % _genreColors.length];
            final icon = _genreIcons[genre.id] ?? Icons.movie_rounded;
            return GestureDetector(
              onTap: () => _openGenre(genre),
              child: Container(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        color: Colors.white.withValues(alpha: 0.9), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        genre.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (40 * i).ms, duration: 400.ms)
                .slideY(begin: 0.1);
          }),
        ),
      ],
    );
  }
}

// ── Genre Results Screen ──
class _GenreResultsScreen extends StatelessWidget {
  final Genre genre;
  final List<Movie> movies;

  const _GenreResultsScreen({required this.genre, required this.movies});

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        foregroundColor: t.text,
        title: Text(genre.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 130,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: movies.length,
        itemBuilder: (_, i) {
          final m = movies[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => m.isTV
                    ? TVDetailScreen(id: m.id)
                    : MovieDetailScreen(id: m.id),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: m.posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: m.posterUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(color: t.surface2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: t.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate().fadeIn(delay: (40 * i).ms, duration: 300.ms);
        },
      ),
    );
  }
}
