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

class TVDetailScreen extends StatefulWidget {
  final int id;
  const TVDetailScreen({super.key, required this.id});

  @override
  State<TVDetailScreen> createState() => _TVDetailScreenState();
}

class _TVDetailScreenState extends State<TVDetailScreen> {
  final _api = TmdbService.instance;
  Movie? _show;
  List<CastMember> _cast = [];
  List<String> _images = [];
  List<Movie> _similar = [];
  List<Season> _seasons = [];
  List<Episode> _episodes = [];
  int _selectedSeason = 1;
  bool _loading = true;
  bool _loadingEpisodes = false;
  bool _hasError = false;

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
        _api.getTVDetails(widget.id),
        _api.getTVCredits(widget.id),
        _api.getTVImages(widget.id),
        _api.getSimilarTV(widget.id),
        _api.getTVSeasons(widget.id),
      ]);
      if (!mounted) return;
      
      final m = results[0] as Movie;
      if (m.title == 'Error') {
        throw Exception('Failed to load TV details');
      }

      setState(() {
        _show = m;
        _cast = results[1] as List<CastMember>;
        _images = results[2] as List<String>;
        _similar = results[3] as List<Movie>;
        _seasons = results[4] as List<Season>;
        _loading = false;
      });
      if (_seasons.isNotEmpty) {
        _loadEpisodes(_seasons.first.seasonNumber);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadEpisodes(int season) async {
    setState(() {
      _selectedSeason = season;
      _loadingEpisodes = true;
    });
    final eps = await _api.getSeasonEpisodes(widget.id, season);
    if (!mounted) return;
    setState(() {
      _episodes = eps;
      _loadingEpisodes = false;
    });
  }

  void _playEpisode(int season, int episode) {
    final s = _show!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          id: widget.id,
          isTV: true,
          season: season,
          episode: episode,
          title: s.title,
          totalEpisodes: _episodes.length,
          totalSeasons: _seasons.length,
        ),
      ),
    );
  }

  void _openImageViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          images: _images,
          initialIndex: index,
          title: _show?.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    if (_loading) {
      return Scaffold(
          backgroundColor: t.bg,
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_hasError || _show == null) {
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
    final s = _show!;
    final wl = WatchlistService.instance;

    return Scaffold(
      backgroundColor: t.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: t.bg,
            foregroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.black45, shape: BoxShape.circle),
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
                  if (s.backdropUrl.isNotEmpty)
                    CachedNetworkImage(
                        imageUrl: s.backdropUrl, fit: BoxFit.cover),
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
                  // Title row with poster
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: s.posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: s.posterUrl,
                                width: 110,
                                height: 165,
                                fit: BoxFit.cover)
                            : Container(
                                width: 110, height: 165, color: t.surface2),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title,
                                style: GoogleFonts.inter(
                                    color: t.text,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2)),
                            if (s.tagline != null && s.tagline!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(s.tagline!,
                                  style: GoogleFonts.inter(
                                      color: t.textMuted,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _chip(Icons.star_rounded, s.rating,
                                    const Color(0xFFFFD700), t),
                                if (s.numberOfSeasons != null)
                                  _chip(
                                      Icons.video_library_rounded,
                                      '${s.numberOfSeasons} Seasons',
                                      t.textMuted,
                                      t),
                                if (s.year != 'N/A')
                                  _chip(Icons.calendar_today_rounded, s.year,
                                      t.textMuted, t),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _playEpisode(
                            _seasons.isNotEmpty ? _seasons.first.seasonNumber : 1,
                            1,
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
                          final isInWatchlist = wl.isInWatchlist(s.id);
                          return Container(
                            decoration: BoxDecoration(
                              color: t.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isInWatchlist ? t.accent : Colors.transparent),
                            ),
                            child: IconButton(
                              onPressed: () => wl.toggle(s),
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
                  if (s.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: s.genres
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
                  const SizedBox(height: 16),

                  // Overview
                  if (s.overview != null && s.overview!.isNotEmpty) ...[
                    Text(s.overview!,
                        style: GoogleFonts.inter(
                            color: t.textMuted, fontSize: 14, height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  // Season selector
                  if (_seasons.isNotEmpty) ...[
                    Text('Seasons & Episodes',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _seasons.length,
                        itemBuilder: (_, i) {
                          final sn = _seasons[i];
                          final sel = sn.seasonNumber == _selectedSeason;
                          return GestureDetector(
                            onTap: () => _loadEpisodes(sn.seasonNumber),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? t.accent : t.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel ? t.accent : t.border),
                              ),
                              child: Text(
                                sn.name,
                                style: GoogleFonts.inter(
                                  color: sel ? Colors.white : t.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Episodes list
                    if (_loadingEpisodes)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      ...List.generate(_episodes.length, (i) {
                        final ep = _episodes[i];
                        return GestureDetector(
                          onTap: () =>
                              _playEpisode(_selectedSeason, ep.episodeNumber),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: t.border),
                            ),
                            child: Row(
                              children: [
                                // Episode thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 130,
                                    height: 75,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ep.stillUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: ep.stillUrl,
                                                fit: BoxFit.cover)
                                            : Container(color: t.surface2),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'E${ep.episodeNumber} · ${ep.name}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: t.text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (ep.runtime != null)
                                        Text('${ep.runtime} min',
                                            style: GoogleFonts.inter(
                                                color: t.textMuted,
                                                fontSize: 12)),
                                      if (ep.overview != null &&
                                          ep.overview!.isNotEmpty)
                                        Text(ep.overview!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                color: t.textMuted,
                                                fontSize: 12,
                                                height: 1.3)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (40 * i).ms, duration: 300.ms);
                      }),
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
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length.clamp(0, 20),
                        itemBuilder: (_, i) {
                          final c = _cast[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ArtistScreen(id: c.id))),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: t.surface2,
                                    backgroundImage: c.profileUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(c.profileUrl)
                                        : null,
                                    child: c.profileUrl.isEmpty
                                        ? Icon(Icons.person, color: t.textMuted)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: t.text,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
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
                          onTap: () => _openImageViewer(0),
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
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _openImageViewer(i),
                          child: Container(
                            width: 240,
                            margin: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                      imageUrl: _images[i],
                                      fit: BoxFit.cover,
                                      width: 240,
                                      height: 150),
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
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Similar
                  if (_similar.isNotEmpty) ...[
                    Text('Similar Shows',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similar.length,
                        itemBuilder: (_, i) {
                          final sim = _similar[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        TVDetailScreen(id: sim.id))),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: sim.posterUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: sim.posterUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity)
                                          : Container(color: t.surface2),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(sim.title,
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

  Widget _chip(IconData icon, String text, Color ic, ThemeService t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: t.surface2, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ic),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(
                  color: t.text, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
