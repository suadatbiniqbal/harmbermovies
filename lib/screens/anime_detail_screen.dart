import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/anime.dart';
import '../models/movie.dart';
import '../services/anilist_service.dart';
import '../services/theme_service.dart';
import '../services/watchlist_service.dart';
import '../services/tmdb_service.dart';
import '../widgets/ad_banner.dart';
import 'anime_player_screen.dart';
import 'image_viewer_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final int id;
  final Anime? initialAnime;
  final Movie? initialMovie;
  const AnimeDetailScreen(
      {super.key, required this.id, this.initialAnime, this.initialMovie});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final _api = AnilistService.instance;
  Anime? _anime;
  bool _loading = true;
  bool _hasError = false;
  bool _expandDesc = false;

  @override
  void initState() {
    super.initState();

    // ── Immediately show data from initialAnime (from anime home) ──
    if (widget.initialAnime != null) {
      _anime = widget.initialAnime;
      _loading = false;
    }
    // ── Immediately show data from initialMovie (from watchlist) ──
    // This prevents "no internet" when reopening app from watchlist
    else if (widget.initialMovie != null) {
      final m = widget.initialMovie!;
      _anime = Anime(
        id: m.id,
        title: m.title,
        coverImage: m.posterPath?.startsWith('http') == true
            ? m.posterPath
            : (m.posterPath != null
                ? '${TmdbService.instance.imageCdnBase}/w500${m.posterPath}'
                : null),
        bannerImage: m.backdropPath?.startsWith('http') == true
            ? m.backdropPath
            : (m.backdropPath != null
                ? '${TmdbService.instance.imageCdnBase}/original${m.backdropPath}'
                : null),
        averageScore: m.voteAverage > 0 ? m.voteAverage : null,
        year: int.tryParse(m.year != 'N/A' ? m.year : '0'),
        description: m.overview,
      );
      _loading = false;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // Only show spinner if we have NO data at all
    if (_anime == null) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final a = await _api.getAnimeDetails(widget.id);
      if (!mounted) return;

      if (a == null) {
        // KEY FIX: if we already have data (from watchlist/initialAnime),
        // DON'T show error — just keep displaying existing data
        if (_anime == null) {
          setState(() {
            _loading = false;
            _hasError = true;
          });
        } else {
          setState(() => _loading = false);
        }
        return;
      }

      setState(() {
        _anime = a;
        _loading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      // KEY FIX: Only show error if we have zero data
      if (_anime == null) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  void _playEpisode(int episode) {
    if (_anime == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimePlayerScreen(
          anilistId: widget.id,
          episode: episode,
          title: _anime!.title,
          posterPath: _anime!.coverImage,
          totalEpisodes: _anime!.episodes ?? episode,
          isMovie: _anime!.format == 'MOVIE',
        ),
      ),
    );
  }

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          images: [url],
          initialIndex: 0,
          title: _anime?.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final t = ThemeService.instance;

        if (_loading) {
          return Scaffold(
            backgroundColor: t.bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: t.accent),
                  const SizedBox(height: 16),
                  Text('Loading...',
                      style: GoogleFonts.inter(color: t.textMuted)),
                ],
              ),
            ),
          );
        }

        if (_hasError && _anime == null) {
          return _buildErrorState(t);
        }

        final a = _anime!;
        return Scaffold(
          backgroundColor: t.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(a, t),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(a, t),
                      const SizedBox(height: 20),
                      _buildActionButtons(a, t),
                      const SizedBox(height: 20),
                      if (a.nextAiringEpisode != null)
                        _buildNextEpisodeCard(a.nextAiringEpisode!, t),
                      const AdBannerContainer(),
                      const SizedBox(height: 20),
                      if (a.genres.isNotEmpty) _buildGenres(a, t),
                      if (a.genres.isNotEmpty) const SizedBox(height: 20),
                      _buildDescription(a, t),
                      if (a.relations.isNotEmpty) _buildRelations(a, t),
                      if (a.format != 'MOVIE') _buildEpisodes(a, t),
                      if (a.recommendations.isNotEmpty)
                        _buildSimilarSeries(a, t),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeService t) {
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: t.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: t.textMuted, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Connection Failed',
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Could not load anime details.\nPlease check your connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: t.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildAppBar(Anime a, ThemeService t) {
    return SliverAppBar(
      expandedHeight: 380,
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
            if (a.bannerImage != null || a.coverImage != null)
              GestureDetector(
                onTap: () {
                  final url = a.bannerImage ?? a.coverImage!;
                  _openImageViewer(url);
                },
                child: CachedNetworkImage(
                  imageUrl: a.bannerImage ?? a.coverImage!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            // Gradient bottom
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    t.bg.withValues(alpha: 0.5),
                    t.bg.withValues(alpha: 0.9),
                    t.bg,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            // Format badge top right
            if (a.format != null)
              Positioned(
                top: 56,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    a.format!,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Anime a, ThemeService t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover poster
        GestureDetector(
          onTap: () {
            if (a.coverImage != null) _openImageViewer(a.coverImage!);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: a.coverImage != null
                  ? CachedNetworkImage(
                      imageUrl: a.coverImage!,
                      width: 120,
                      height: 178,
                      fit: BoxFit.cover)
                  : Container(
                      width: 120,
                      height: 178,
                      color: t.surface2,
                      child: Icon(Icons.animation_rounded,
                          color: t.textMuted, size: 40),
                    ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(a.title,
                  style: GoogleFonts.inter(
                      color: t.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25)),
              const SizedBox(height: 6),
              // Studio
              if (a.studios.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 13, color: t.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        a.studios.first,
                        style: GoogleFonts.inter(
                            color: t.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              // Meta chips
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (a.averageScore != null)
                    _chip(
                        Icons.star_rounded,
                        '${a.averageScore!.toStringAsFixed(1)} / 10',
                        const Color(0xFFFFD700),
                        t),
                  if (a.episodes != null)
                    _chip(Icons.video_library_rounded, '${a.episodes} Eps',
                        t.textMuted, t),
                  if (a.status != null)
                    _chip(
                        Icons.info_outline_rounded, a.status!, t.textMuted, t),
                  if (a.year != null)
                    _chip(Icons.calendar_today_rounded, a.year.toString(),
                        t.textMuted, t),
                  if (a.season != null)
                    _chip(Icons.wb_sunny_rounded, _formatSeason(a.season!),
                        t.textMuted, t),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSeason(String season) {
    switch (season.toUpperCase()) {
      case 'WINTER':
        return '❄️ Winter';
      case 'SPRING':
        return '🌸 Spring';
      case 'SUMMER':
        return '☀️ Summer';
      case 'FALL':
        return '🍂 Fall';
      default:
        return season;
    }
  }

  Widget _buildActionButtons(Anime a, ThemeService t) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _playEpisode(1),
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: Text(a.format == 'MOVIE' ? 'Watch Movie' : 'Watch Episode 1',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ListenableBuilder(
          listenable: WatchlistService.instance,
          builder: (context, _) {
            final isIn = WatchlistService.instance.isInWatchlist(a.id);
            return GestureDetector(
              onTap: () {
                final movie = a.toMovie();
                WatchlistService.instance.toggle(movie);
                final nowIn = WatchlistService.instance.isInWatchlist(a.id);
                Fluttertoast.showToast(
                  msg:
                      nowIn ? '✓ Added to Watchlist' : 'Removed from Watchlist',
                  backgroundColor: t.accent,
                  textColor: Colors.white,
                  gravity: ToastGravity.BOTTOM,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: isIn ? t.accent.withValues(alpha: 0.15) : t.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: isIn ? t.accent : t.border, width: 1.5),
                ),
                child: Icon(
                  isIn ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                  color: isIn ? t.accent : t.textMuted,
                  size: 24,
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildNextEpisodeCard(Map<String, dynamic> next, ThemeService t) {
    final ep = next['episode'];
    final time = next['timeUntilAiring'] as int;
    final days = time ~/ 86400;
    final hours = (time % 86400) ~/ 3600;

    String countdown = days > 0 ? '$days days $hours hrs' : '$hours hours';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.accent.withValues(alpha: 0.18), t.surface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_outlined, color: t.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Episode $ep Coming Soon',
                    style: GoogleFonts.inter(
                        color: t.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text('Airing in $countdown',
                    style: GoogleFonts.inter(color: t.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .shimmer(duration: 2200.ms, color: t.accent.withValues(alpha: 0.08));
  }

  Widget _buildGenres(Anime a, ThemeService t) {
    const genreColors = {
      'Action': Color(0xFFEF4444),
      'Adventure': Color(0xFFF59E0B),
      'Comedy': Color(0xFFFBBF24),
      'Drama': Color(0xFF9CA3AF),
      'Fantasy': Color(0xFF6B7280),
      'Horror': Color(0xFF1F2937),
      'Mecha': Color(0xFF3B82F6),
      'Music': Color(0xFFEC4899),
      'Mystery': Color(0xFF6B7280),
      'Psychological': Color(0xFF9CA3AF),
      'Romance': Color(0xFFF43F5E),
      'Sci-Fi': Color(0xFF06B6D4),
      'Slice of Life': Color(0xFF10B981),
      'Sports': Color(0xFF22C55E),
      'Supernatural': Color(0xFF9CA3AF),
      'Thriller': Color(0xFFDC2626),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: a.genres.map((g) {
        final color = genreColors[g] ?? t.accent;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(g,
              style: GoogleFonts.inter(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        );
      }).toList(),
    );
  }

  Widget _buildDescription(Anime a, ThemeService t) {
    if (a.description == null || a.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    final clean = a.description!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Storyline', t),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _expandDesc = !_expandDesc),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  clean,
                  maxLines: _expandDesc ? null : 4,
                  overflow: _expandDesc ? null : TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: t.textMuted, fontSize: 14, height: 1.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _expandDesc ? 'Show less' : 'Read more',
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

  Widget _buildRelations(Anime a, ThemeService t) {
    final sequels =
        a.relations.where((r) => r.relationType == 'SEQUEL').toList();
    final prequels =
        a.relations.where((r) => r.relationType == 'PREQUEL').toList();
    final others = a.relations
        .where((r) => r.relationType != 'SEQUEL' && r.relationType != 'PREQUEL')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Seasons & Related', t),
        const SizedBox(height: 12),
        if (prequels.isNotEmpty)
          _buildRelationRow('Prequel', prequels, t.textMuted, t),
        if (sequels.isNotEmpty)
          _buildRelationRow('Sequel', sequels, t.textMuted, t),
        if (others.isNotEmpty)
          _buildRelationRow('Related', others, t.accent, t),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRelationRow(String label, List<AnimeRelation> items,
      Color badgeColor, ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1),
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AnimeDetailScreen(id: r.id)),
                ),
                child: Container(
                  width: 106,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                              imageUrl: r.coverImage ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: t.surface2)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: t.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.3)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildEpisodes(Anime a, ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('Episodes', t),
            if (a.streamingEpisodes.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${a.streamingEpisodes.length} Available',
                    style: GoogleFonts.inter(
                        color: t.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (a.streamingEpisodes.isNotEmpty)
          ...a.streamingEpisodes.map((ep) => _buildRichEpisodeTile(ep, t))
        else
          ...List.generate(
              a.episodes ?? 1, (i) => _buildSimpleEpisodeTile(i + 1, t)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRichEpisodeTile(AnimeEpisode ep, ThemeService t) {
    return GestureDetector(
      onTap: () => _playEpisode(ep.number),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 84,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: ep.thumbnail ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: t.surface2,
                        child: Icon(Icons.play_arrow_rounded,
                            color: t.textMuted, size: 32),
                      ),
                    ),
                    Container(color: Colors.black26),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Episode ${ep.number}',
                      style: GoogleFonts.inter(
                          color: t.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(ep.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: t.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: t.textMuted.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSimpleEpisodeTile(int epNum, ThemeService t) {
    return GestureDetector(
      onTap: () => _playEpisode(epNum),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$epNum',
                  style: GoogleFonts.inter(
                      color: t.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Episode $epNum',
                  style: GoogleFonts.inter(
                      color: t.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.play_circle_fill_rounded, color: t.accent, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarSeries(Anime a, ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('You May Also Like', t),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: a.recommendations.length,
            itemBuilder: (context, i) {
              final r = a.recommendations[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AnimeDetailScreen(id: r.id)),
                ),
                child: Container(
                  width: 126,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                  imageUrl: r.coverImage ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: t.surface2)),
                            ),
                            if (r.averageScore != null)
                              Positioned(
                                top: 6,
                                right: 6,
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
                                      const SizedBox(width: 2),
                                      Text(
                                        r.averageScore!.toStringAsFixed(1),
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: t.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color ic, ThemeService t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: t.surface2, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ic),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(
                  color: t.text, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
