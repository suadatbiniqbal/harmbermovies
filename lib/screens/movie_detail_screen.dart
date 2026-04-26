import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/theme_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/ad_banner.dart';
import 'player_screen.dart';
import 'artists_screen.dart';
import 'image_viewer_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final int id;
  const MovieDetailScreen({super.key, required this.id});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _api = TmdbService.instance;
  Movie? _movie;
  List<CastMember> _cast = [];
  List<String> _images = [];
  List<Movie> _similar = [];
  bool _loading = true;
  bool _hasError = false;
  bool _expandedOverview = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _api.getMovieDetails(widget.id),
        _api.getMovieCredits(widget.id),
        _api.getMovieImages(widget.id),
        _api.getSimilarMovies(widget.id),
      ]);
      if (!mounted) return;
      final m = results[0] as Movie;
      if (m.title == 'Error') throw Exception('Failed to load');
      setState(() {
        _movie = m;
        _cast = results[1] as List<CastMember>;
        _images = results[2] as List<String>;
        _similar = results[3] as List<Movie>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;

    if (_loading) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Center(child: CircularProgressIndicator(color: t.accent)),
      );
    }

    if (_hasError || _movie == null) {
      return _buildError(t);
    }

    return ListenableBuilder(
      listenable: WatchlistService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: t.bg,
          body: RefreshIndicator(
            color: t.accent,
            backgroundColor: t.surface,
            onRefresh: _loadData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildAppBar(t),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(t),
                        const SizedBox(height: 18),
                        _buildActionRow(t),
                        const SizedBox(height: 20),
                        const AdBannerContainer(),
                        const SizedBox(height: 20),
                        if (_movie!.genres.isNotEmpty) _buildGenres(t),
                        if (_movie!.genres.isNotEmpty)
                          const SizedBox(height: 20),
                        _buildOverview(t),
                        if (_cast.isNotEmpty) _buildCast(t),
                        if (_images.isNotEmpty) _buildImages(t),
                        if (_similar.isNotEmpty) _buildSimilar(t),
                        _buildProductionInfo(t),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(ThemeService t) {
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: t.text,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration:
                  BoxDecoration(color: t.surface2, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, color: t.textMuted, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Failed to load',
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Check your connection and try again',
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildAppBar(ThemeService t) {
    final m = _movie!;
    return SliverAppBar(
      expandedHeight: 440,
      pinned: true,
      backgroundColor: t.bg,
      foregroundColor: Colors.white,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Poster / Backdrop
            GestureDetector(
              onTap: () {
                if (m.backdropUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewerScreen(
                        images: [
                          m.backdropUrl,
                          ...?(_images.isNotEmpty ? _images : null)
                        ],
                        initialIndex: 0,
                        title: m.title,
                      ),
                    ),
                  );
                }
              },
              child: m.backdropUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: m.backdropUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : m.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: m.posterUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: t.surface2),
            ),

            // Gradient overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    t.bg.withValues(alpha: 0.6),
                    t.bg.withValues(alpha: 0.92),
                    t.bg,
                  ],
                  stops: const [0.0, 0.3, 0.58, 0.78, 1.0],
                ),
              ),
            ),

            // Bottom poster + title + rating
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Floating poster
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: m.posterUrl,
                        width: 90,
                        height: 135,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            width: 90, height: 135, color: t.surface2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.tagline != null && m.tagline!.isNotEmpty)
                          Text(
                            '"${m.tagline}"',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (m.tagline != null && m.tagline!.isNotEmpty)
                          const SizedBox(height: 6),
                        // Meta row
                        Wrap(
                          spacing: 7,
                          runSpacing: 5,
                          children: [
                            _heroBadge(Icons.star_rounded, m.rating,
                                const Color(0xFFFFD700)),
                            if (m.year != 'N/A')
                              _heroBadge(Icons.calendar_today_rounded, m.year,
                                  Colors.white60),
                            if (m.runtime != null)
                              _heroBadge(Icons.timer_outlined, m.runtime!,
                                  Colors.white60),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTitleSection(ThemeService t) {
    final m = _movie!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(m.title,
            style: GoogleFonts.inter(
                color: t.text,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: -0.5)),
        if (m.status != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: m.status == 'Released'
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : t.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: m.status == 'Released'
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : t.accent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              m.status!,
              style: GoogleFonts.inter(
                color:
                    m.status == 'Released' ? const Color(0xFF10B981) : t.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildActionRow(ThemeService t) {
    final m = _movie!;
    final isIn = WatchlistService.instance.isInWatchlist(m.id);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  id: m.id,
                  title: m.title,
                  isTV: false,
                  posterPath: m.posterPath,
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: Text('Play Movie',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            WatchlistService.instance.toggle(m);
            final nowIn = WatchlistService.instance.isInWatchlist(m.id);
            Fluttertoast.showToast(
              msg: nowIn ? '✓ Added to Watchlist' : 'Removed from Watchlist',
              backgroundColor: t.accent,
              textColor: Colors.white,
              gravity: ToastGravity.BOTTOM,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: isIn ? t.accent.withValues(alpha: 0.15) : t.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isIn ? t.accent : t.border, width: 1.5),
            ),
            child: Icon(
              isIn ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
              color: isIn ? t.accent : t.textMuted,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08);
  }

  Widget _buildGenres(ThemeService t) {
    const genreColors = {
      28: Color(0xFFEF4444),
      12: Color(0xFFF59E0B),
      16: Color(0xFF06B6D4),
      35: Color(0xFFFBBF24),
      80: Color(0xFF6B7280),
      99: Color(0xFF10B981),
      18: Color(0xFF9CA3AF),
      10751: Color(0xFF22C55E),
      14: Color(0xFF6B7280),
      36: Color(0xFFCA8A04),
      27: Color(0xFFDC2626),
      10402: Color(0xFFEC4899),
      9648: Color(0xFF9CA3AF),
      10749: Color(0xFFF43F5E),
      878: Color(0xFF3B82F6),
      53: Color(0xFFEA580C),
      10752: Color(0xFF374151),
      37: Color(0xFF84CC16),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Genres', t),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _movie!.genres.map((g) {
            final c = genreColors[g.id] ?? t.accent;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.withValues(alpha: 0.38)),
              ),
              child: Text(g.name,
                  style: GoogleFonts.inter(
                      color: c, fontSize: 12, fontWeight: FontWeight.w700)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOverview(ThemeService t) {
    final ov = _movie!.overview;
    if (ov == null || ov.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Synopsis', t),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _expandedOverview = !_expandedOverview),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: Text(
                  ov,
                  maxLines: _expandedOverview ? null : 4,
                  overflow: _expandedOverview
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: t.textMuted, fontSize: 14, height: 1.65),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _expandedOverview ? 'Show less' : 'Read more',
                style: GoogleFonts.inter(
                    color: t.accent, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCast(ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Cast', t),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _cast.take(15).length,
            itemBuilder: (_, i) {
              final c = _cast[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArtistScreen(id: c.id)),
                ),
                child: Container(
                  width: 84,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: t.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: c.profileUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: c.profileUrl,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: t.surface2,
                                  child: Icon(Icons.person_rounded,
                                      color: t.textMuted, size: 32),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: t.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      if (c.character != null)
                        Text(c.character!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: t.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildImages(ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Gallery', t),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _images.length,
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageViewerScreen(
                      images: _images,
                      initialIndex: i,
                      title: _movie!.title,
                    ),
                  ),
                ),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: _images[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSimilar(ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('More Like This', t),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _similar.length,
            itemBuilder: (_, i) {
              final s = _similar[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(id: s.id),
                  ),
                ),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: s.posterUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: s.posterUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Container(color: t.surface2),
                            ),
                            if (s.voteAverage > 0)
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD700), size: 10),
                                      const SizedBox(width: 3),
                                      Text(s.rating,
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: t.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductionInfo(ThemeService t) {
    final m = _movie!;
    final hasInfo = m.budget != null ||
        m.revenue != null ||
        m.homepage != null ||
        m.productionCompanies.isNotEmpty ||
        m.spokenLanguages.isNotEmpty;
    if (!hasInfo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Production', t),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
          ),
          child: Column(
            children: [
              if (m.budget != null && m.budget! > 0)
                _infoRow('Budget',
                    '\$${(m.budget! / 1000000).toStringAsFixed(1)}M', t),
              if (m.revenue != null && m.revenue! > 0)
                _infoRow('Revenue',
                    '\$${(m.revenue! / 1000000).toStringAsFixed(1)}M', t),
              if (m.spokenLanguages.isNotEmpty)
                _infoRow('Languages',
                    m.spokenLanguages.map((l) => l.englishName).join(', '), t),
              if (m.productionCompanies.isNotEmpty)
                _infoRow(
                    'Studios',
                    m.productionCompanies.take(2).map((c) => c.name).join(', '),
                    t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, ThemeService t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.inter(
                    color: t.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeService t) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
              color: t.accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
