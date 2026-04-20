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
  Season? _selectedSeason;
  bool _loading = true;
  bool _hasError = false;
  bool _loadingEpisodes = false;
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
        _api.getTVDetails(widget.id),
        _api.getTVCredits(widget.id),
        _api.getTVImages(widget.id),
        _api.getSimilarTV(widget.id),
      ]);
      if (!mounted) return;
      final s = results[0] as Movie;
      if (s.title == 'Error') throw Exception('Failed to load');

      final allSeasons = await _api.getTVSeasons(widget.id);
      final realSeasons =
          allSeasons.where((s) => s.seasonNumber > 0).toList();

      if (!mounted) return;
      setState(() {
        _show = s;
        _cast = results[1] as List<CastMember>;
        _images = results[2] as List<String>;
        _similar = results[3] as List<Movie>;
        _seasons = realSeasons;
        _selectedSeason = realSeasons.isNotEmpty ? realSeasons.first : null;
        _loading = false;
      });

      if (_selectedSeason != null) {
        _loadEpisodes(_selectedSeason!);
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _loadEpisodes(Season season) async {
    if (!mounted) return;
    setState(() {
      _loadingEpisodes = true;
      _episodes = [];
    });
    try {
      final eps =
          await _api.getSeasonEpisodes(widget.id, season.seasonNumber);
      if (!mounted) return;
      setState(() {
        _episodes = eps;
        _loadingEpisodes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEpisodes = false);
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

    if (_hasError || _show == null) {
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
                        _buildStats(t),
                        const SizedBox(height: 18),
                        _buildActionRow(t),
                        const SizedBox(height: 20),
                        const AdBannerContainer(),
                        const SizedBox(height: 20),
                        if (_show!.genres.isNotEmpty) _buildGenres(t),
                        if (_show!.genres.isNotEmpty) const SizedBox(height: 20),
                        _buildOverview(t),
                        if (_seasons.isNotEmpty) _buildEpisodesSection(t),
                        if (_cast.isNotEmpty) _buildCast(t),
                        if (_images.isNotEmpty) _buildImages(t),
                        if (_similar.isNotEmpty) _buildSimilar(t),
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
          foregroundColor: t.text),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration:
                  BoxDecoration(color: t.surface2, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  color: t.textMuted, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Failed to load',
                style: GoogleFonts.inter(
                    color: t.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Check your connection and try again',
                style: GoogleFonts.inter(
                    color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
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
    final s = _show!;
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
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child:
              const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () {
                if (s.backdropUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewerScreen(
                        images: [s.backdropUrl, ..._images],
                        initialIndex: 0,
                        title: s.title,
                      ),
                    ),
                  );
                }
              },
              child: s.backdropUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: s.backdropUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : s.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: s.posterUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: t.surface2),
            ),
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                        imageUrl: s.posterUrl,
                        width: 90,
                        height: 135,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            width: 90,
                            height: 135,
                            color: t.surface2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        _heroBadge(Icons.star_rounded,
                            s.rating, const Color(0xFFFFD700)),
                        if (s.year != 'N/A')
                          _heroBadge(Icons.calendar_today_rounded,
                              s.year, Colors.white60),
                        if (s.numberOfSeasons != null)
                          _heroBadge(Icons.layers_rounded,
                              '${s.numberOfSeasons} Seasons',
                              Colors.white60),
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
    return Text(
      _show!.title,
      style: GoogleFonts.inter(
          color: t.text,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          height: 1.2,
          letterSpacing: -0.5),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildStats(ThemeService t) {
    final s = _show!;
    return Row(
      children: [
        if (s.numberOfSeasons != null)
          _statChip(Icons.layers_rounded,
              '${s.numberOfSeasons} Seasons', t),
        if (s.numberOfEpisodes != null) ...[
          const SizedBox(width: 8),
          _statChip(Icons.video_library_rounded,
              '${s.numberOfEpisodes} Episodes', t),
        ],
        if (s.status != null) ...[
          const SizedBox(width: 8),
          _statChip(Icons.info_outline_rounded, s.status!, t),
        ],
      ],
    );
  }

  Widget _statChip(IconData icon, String text, ThemeService t) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: t.accent),
          const SizedBox(width: 5),
          Text(text,
              style: GoogleFonts.inter(
                  color: t.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionRow(ThemeService t) {
    final s = _show!;
    final isIn = WatchlistService.instance.isInWatchlist(s.id);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  id: s.id,
                  title: s.title,
                  isTV: true,
                  season: _selectedSeason?.seasonNumber ?? 1,
                  episode: 1,
                  posterPath: s.posterPath,
                  
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: Text('Play S${_selectedSeason?.seasonNumber ?? 1} E1',
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
            WatchlistService.instance.toggle(s);
            final nowIn = WatchlistService.instance.isInWatchlist(s.id);
            Fluttertoast.showToast(
              msg: nowIn
                  ? '✓ Added to Watchlist'
                  : 'Removed from Watchlist',
              backgroundColor: Colors.white,
              textColor: const Color(0xFF121212),
              gravity: ToastGravity.BOTTOM,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: isIn
                  ? t.accent.withValues(alpha: 0.15)
                  : t.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isIn ? t.accent : t.border, width: 1.5),
            ),
            child: Icon(
              isIn
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_add_outlined,
              color: isIn ? t.accent : t.textMuted,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08);
  }

  Widget _buildGenres(ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Genres', t),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _show!.genres.map((g) {
            final c = t.accent;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.withValues(alpha: 0.35)),
              ),
              child: Text(g.name,
                  style: GoogleFonts.inter(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOverview(ThemeService t) {
    final ov = _show!.overview;
    if (ov == null || ov.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Synopsis', t),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () =>
              setState(() => _expandedOverview = !_expandedOverview),
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
                      ? null
                      : TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: t.textMuted,
                      fontSize: 14,
                      height: 1.65),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _expandedOverview ? 'Show less' : 'Read more',
                style: GoogleFonts.inter(
                    color: t.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEpisodesSection(ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('Episodes', t),
            if (_episodes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_episodes.length} episodes',
                    style: GoogleFonts.inter(
                        color: t.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Season selector pills
        if (_seasons.length > 1)
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _seasons.map((season) {
                    final isSelected =
                        _selectedSeason?.seasonNumber ==
                            season.seasonNumber;
                    return GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          setState(() => _selectedSeason = season);
                          _loadEpisodes(season);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [t.accent, t.accent.withValues(alpha: 0.8)],
                                )
                              : null,
                          color: isSelected ? null : t.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : t.border,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: t.accent.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          season.name.startsWith('Season')
                              ? 'S${season.seasonNumber}'
                              : season.name,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : t.textMuted,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Episodes list
        if (_loadingEpisodes)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  color: t.accent, strokeWidth: 2.5),
            ),
          )
        else
          ..._episodes
              .take(12)
              .toList()
              .indexed
              .map((entry) =>
                  _buildEpisodeTile(entry.$2, entry.$1, t))
              .toList(),

        if (_episodes.length > 12)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.expand_more_rounded,
                    color: t.accent),
                label: Text(
                    '+${_episodes.length - 12} more episodes',
                    style: GoogleFonts.inter(
                        color: t.accent,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEpisodeTile(Episode ep, int idx, ThemeService t) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            id  : _show!.id,
            title: _show!.title,
            isTV: true,
            season: ep.seasonNumber,
            episode: ep.episodeNumber,
            posterPath: _show!.posterPath,
            
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Stack(
                children: [
                  ep.stillUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ep.stillUrl,
                          width: 130,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 130,
                            height: 80,
                            color: t.surface2,
                          ),
                        )
                      : Container(
                          width: 130,
                          height: 80,
                          color: t.surface2,
                          child: Icon(Icons.tv_rounded,
                              color: t.textMuted, size: 28),
                        ),
                  // Play overlay
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                  // Episode number badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('E${ep.episodeNumber}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ep.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (ep.runtime != null) ...[
                          Icon(Icons.timer_outlined,
                              size: 11, color: t.textMuted),
                          const SizedBox(width: 3),
                          Text('${ep.runtime} min',
                              style: GoogleFonts.inter(
                                  color: t.textMuted, fontSize: 11)),
                          const SizedBox(width: 8),
                        ],
                        if (ep.voteAverage > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFD700), size: 11),
                              const SizedBox(width: 3),
                              Text(
                                  ep.voteAverage.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                      color: t.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: t.textMuted.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * idx).ms, duration: 300.ms);
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
                  MaterialPageRoute(
                      builder: (_) => ArtistScreen(id: c.id)),
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
                          border:
                              Border.all(color: t.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.2),
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
                      title: _show!.title,
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
                      builder: (_) => TVDetailScreen(id: s.id)),
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
                                    color: Colors.black
                                        .withValues(alpha: 0.7),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD700),
                                          size: 10),
                                      const SizedBox(width: 3),
                                      Text(s.rating,
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w700)),
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

  Widget _sectionHeader(String title, ThemeService t) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                color: t.text,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
