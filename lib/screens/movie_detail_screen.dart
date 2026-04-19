import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (m.title == 'Error') {
        throw Exception('Failed to load movie details');
      }

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
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasError || _movie == null) {
      return Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: t.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: t.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load data\nPlease check your connection',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final m = _movie!;
    final wl = WatchlistService.instance;

    return Scaffold(
      backgroundColor: t.bg,
      body: CustomScrollView(
        slivers: [
          // Hero backdrop
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: t.bg,
            foregroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            actions: [
              // Watchlist icon removed from here, moved next to Watch Now
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (m.backdropUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: m.backdropUrl,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          t.bg.withValues(alpha: 0.3),
                          t.bg.withValues(alpha: 0.8),
                          t.bg,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: m.posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: m.posterUrl,
                                width: 110,
                                height: 165,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 110,
                                height: 165,
                                color: t.surface2,
                              ),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: GoogleFonts.inter(
                                color: t.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            if (m.tagline != null && m.tagline!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                m.tagline!,
                                style: GoogleFonts.inter(
                                  color: t.textMuted,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Meta chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _metaChip(Icons.star_rounded, m.rating,
                                    const Color(0xFFFFD700), t),
                                if (m.year != 'N/A')
                                  _metaChip(Icons.calendar_today_rounded,
                                      m.year, t.textMuted, t),
                                if (m.runtime != null)
                                  _metaChip(Icons.schedule_rounded, m.runtime!,
                                      t.textMuted, t),
                                if (m.status != null)
                                  _metaChip(Icons.info_outline_rounded,
                                      m.status!, t.textMuted, t),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlayerScreen(id: m.id, title: m.title, posterPath: m.posterUrl),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text('Watch Now',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ListenableBuilder(
                        listenable: wl,
                        builder: (context, _) {
                          final isInWatchlist = wl.isInWatchlist(m.id);
                          return Container(
                            decoration: BoxDecoration(
                              color: t.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isInWatchlist ? t.accent : Colors.transparent),
                            ),
                            child: IconButton(
                              onPressed: () => wl.toggle(m),
                              icon: Icon(
                                isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                                color: isInWatchlist ? t.accent : t.text,
                              ),
                              tooltip: isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  const AdBannerContainer(),
                  const SizedBox(height: 16),

                  // Genres
                  if (m.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: m.genres
                          .map((g) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: t.surface2,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: t.border),
                                ),
                                child: Text(g.name,
                                    style: GoogleFonts.inter(
                                        color: t.text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 20),

                  // Overview
                  if (m.overview != null && m.overview!.isNotEmpty) ...[
                    Text('Overview',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(
                          () => _expandedOverview = !_expandedOverview),
                      child: Text(
                        m.overview!,
                        maxLines: _expandedOverview ? null : 4,
                        overflow:
                            _expandedOverview ? null : TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: t.textMuted,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Cast
                  if (_cast.isNotEmpty) ...[
                    Text('Cast',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length.clamp(0, 20),
                        itemBuilder: (_, i) => _buildCastCard(_cast[i], t, i),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Images (tappable with download)
                  if (_images.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('Images',
                            style: GoogleFonts.inter(
                                color: t.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageViewerScreen(
                                images: _images,
                                initialIndex: 0,
                                title: m.title,
                              ),
                            ),
                          ),
                          child: Text('View All',
                              style: GoogleFonts.inter(
                                  color: t.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageViewerScreen(
                                images: _images,
                                initialIndex: i,
                                title: m.title,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: _images[i],
                                    fit: BoxFit.cover,
                                    width: 260,
                                    height: 160,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.download_rounded,
                                        color: Colors.white70, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (50 * i).ms, duration: 300.ms),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Movie info
                  _buildInfoSection(m, t),
                  const SizedBox(height: 24),

                  // Similar movies
                  if (_similar.isNotEmpty) ...[
                    Text('Similar Movies',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
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
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: s.posterUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: s.posterUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            )
                                          : Container(color: t.surface2),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(s.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: t.text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(
      IconData icon, String text, Color iconColor, ThemeService t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(
                  color: t.text, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCastCard(CastMember c, ThemeService t, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtistScreen(id: c.id)),
      ),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: t.surface2,
              backgroundImage:
                  c.profileUrl.isNotEmpty ? CachedNetworkImageProvider(c.profileUrl) : null,
              child: c.profileUrl.isEmpty
                  ? Icon(Icons.person, color: t.textMuted)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(c.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 11, fontWeight: FontWeight.w600)),
            if (c.character != null)
              Text(c.character!,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: t.textMuted, fontSize: 10)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (40 * i).ms, duration: 300.ms);
  }

  Widget _buildInfoSection(Movie m, ThemeService t) {
    final items = <MapEntry<String, String>>[];
    if (m.budget != null && m.budget! > 0) {
      items.add(MapEntry('Budget', '\$${_formatNumber(m.budget!)}'));
    }
    if (m.revenue != null && m.revenue! > 0) {
      items.add(MapEntry('Revenue', '\$${_formatNumber(m.revenue!)}'));
    }
    if (m.spokenLanguages.isNotEmpty) {
      items.add(MapEntry(
          'Languages', m.spokenLanguages.map((l) => l.englishName).join(', ')));
    }
    if (m.productionCompanies.isNotEmpty) {
      items.add(MapEntry(
          'Production', m.productionCompanies.map((c) => c.name).join(', ')));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details',
            style: GoogleFonts.inter(
                color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...items.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(e.key,
                        style: GoogleFonts.inter(
                            color: t.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text(e.value,
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
