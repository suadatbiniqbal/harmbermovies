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
import '../widgets/ad_banner.dart';
import 'anime_player_screen.dart';
import 'image_viewer_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final int id;
  final Anime? initialAnime;
  final Movie? initialMovie;
  const AnimeDetailScreen({super.key, required this.id, this.initialAnime, this.initialMovie});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final _api = AnilistService.instance;
  Anime? _anime;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAnime != null) {
      _anime = widget.initialAnime;
      _loading = false;
    } else if (widget.initialMovie != null) {
      _anime = Anime(
        id: widget.initialMovie!.id,
        title: widget.initialMovie!.title,
        coverImage: widget.initialMovie!.posterPath,
        bannerImage: widget.initialMovie!.backdropPath,
        averageScore: widget.initialMovie!.voteAverage,
        year: int.tryParse(widget.initialMovie!.year),
        description: widget.initialMovie!.overview,
      );
      _loading = false;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
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
        throw Exception('Failed to load Anime details');
      }

      setState(() {
        _anime = a;
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
              body: const Center(child: CircularProgressIndicator()));
        }
        if (_hasError || _anime == null) {
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
                      if (a.nextAiringEpisode != null) _buildNextEpisodeCard(a.nextAiringEpisode!, t),
                      const AdBannerContainer(),
                      const SizedBox(height: 20),
                      _buildGenres(a, t),
                      const SizedBox(height: 20),
                      _buildDescription(a, t),
                       if (a.relations.isNotEmpty) _buildRelations(a, t),
                      if (a.format != 'MOVIE') _buildEpisodes(a, t),
                      if (a.recommendations.isNotEmpty) _buildSimilarSeries(a, t),
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
            Icon(Icons.wifi_off_rounded, color: t.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load Anime data\nPlease check your connection',
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

  Widget _buildAppBar(Anime a, ThemeService t) {
    return SliverAppBar(
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
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (a.bannerImage != null || a.coverImage != null)
              CachedNetworkImage(
                  imageUrl: a.bannerImage ?? a.coverImage!, 
                  fit: BoxFit.cover, 
                  alignment: Alignment.topCenter),
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
    );
  }

  Widget _buildHeaderInfo(Anime a, ThemeService t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (a.coverImage != null) _openImageViewer(a.coverImage!);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: a.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: a.coverImage!,
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover)
                : Container(width: 120, height: 180, color: t.surface2),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title,
                  style: GoogleFonts.inter(
                      color: t.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2)),
              const SizedBox(height: 6),
              if (a.studios.isNotEmpty)
                Text(a.studios.first,
                    style: GoogleFonts.inter(
                        color: t.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (a.format != null)
                Text(a.format!,
                    style: GoogleFonts.inter(
                        color: t.textMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (a.averageScore != null)
                    _chip(Icons.star_rounded, a.averageScore!.toStringAsFixed(1),
                        const Color(0xFFFFD700), t),
                  if (a.episodes != null)
                    _chip(Icons.video_library_rounded, '${a.episodes} Eps',
                        t.textMuted, t),
                  if (a.status != null)
                    _chip(Icons.info_outline_rounded, a.status!, t.textMuted, t),
                  if (a.year != null)
                    _chip(Icons.calendar_today_rounded, a.year.toString(),
                        t.textMuted, t),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Anime a, ThemeService t) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _playEpisode(1),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(a.format == 'MOVIE' ? 'Watch Movie' : 'Watch Episode 1',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ListenableBuilder(
          listenable: WatchlistService.instance,
          builder: (context, _) {
            final isInWatchlist = WatchlistService.instance.isInWatchlist(a.id);
            return GestureDetector(
              onTap: () {
                final movie = a.toMovie();
                WatchlistService.instance.toggle(movie);
                final isNowIn = WatchlistService.instance.isInWatchlist(a.id);
                Fluttertoast.showToast(
                  msg: isNowIn ? 'Added to Watchlist' : 'Removed from Watchlist',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF121212),
                  gravity: ToastGravity.BOTTOM,
                );
              },
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isInWatchlist ? t.accent : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(
                  isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                  color: isInWatchlist ? t.accent : Colors.white70,
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
    final time = next['timeUntilAiring']; // in seconds
    final hours = (time / 3600).floor();
    final days = (hours / 24).floor();
    final remainingHours = hours % 24;

    String countdown = '';
    if (days > 0) {
      countdown = '$days days, $remainingHours hours';
    } else {
      countdown = '$hours hours';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.accent.withValues(alpha: 0.2), t.surface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: t.accent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Episode ($ep)',
                    style: GoogleFonts.inter(
                        color: t.text, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text('Airing in $countdown',
                    style: GoogleFonts.inter(color: t.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }

  Widget _buildGenres(Anime a, ThemeService t) {
    if (a.genres.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: a.genres
          .map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.border),
                ),
                child: Text(g,
                    style: GoogleFonts.inter(
                        color: t.text, fontSize: 12, fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  Widget _buildDescription(Anime a, ThemeService t) {
    if (a.description == null || a.description!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Storyline',
            style: GoogleFonts.inter(
                color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(a.description!.replaceAll(RegExp(r'<[^>]*>'), ''),
            style: GoogleFonts.inter(
                color: t.textMuted, fontSize: 14, height: 1.6)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRelations(Anime a, ThemeService t) {
    // Group relations into categories for a "Season" feel
    final sequels = a.relations.where((r) => r.relationType == 'SEQUEL').toList();
    final prequels = a.relations.where((r) => r.relationType == 'PREQUEL').toList();
    final others = a.relations.where((r) => r.relationType != 'SEQUEL' && r.relationType != 'PREQUEL').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seasons & Related',
            style: GoogleFonts.inter(
                color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (prequels.isNotEmpty) _buildRelationRow('Prequel', prequels, t),
        if (sequels.isNotEmpty) _buildRelationRow('Sequel', sequels, t),
        if (others.isNotEmpty) _buildRelationRow('Related', others, t),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRelationRow(String label, List<AnimeRelation> items, ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label.toUpperCase(), 
              style: GoogleFonts.inter(color: t.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AnimeDetailScreen(id: r.id)),
                  );
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                              imageUrl: r.coverImage ?? '', 
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: t.surface2)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: t.text, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
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
            Text('Episodes',
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
            if (a.streamingEpisodes.isNotEmpty)
              Text('${a.streamingEpisodes.length} Available',
                  style: GoogleFonts.inter(color: t.accent, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (a.streamingEpisodes.isNotEmpty)
          ...a.streamingEpisodes.map((ep) => _buildRichEpisodeTile(ep, t))
        else
          ...List.generate(a.episodes ?? 1, (i) => _buildSimpleEpisodeTile(i + 1, t)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRichEpisodeTile(AnimeEpisode ep, ThemeService t) {
    return GestureDetector(
      onTap: () => _playEpisode(ep.number),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: ep.thumbnail ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: t.surface2, child: Icon(Icons.play_arrow_rounded, color: t.textMuted)),
                    ),
                    Container(color: Colors.black26),
                    const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 30)),
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
                      style: GoogleFonts.inter(color: t.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(ep.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: t.text, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSimpleEpisodeTile(int epNum, ThemeService t) {
    return GestureDetector(
      onTap: () => _playEpisode(epNum),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(8)),
              child: Text(epNum.toString(),
                  style: GoogleFonts.inter(color: t.text, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Episode $epNum',
                  style: GoogleFonts.inter(color: t.text, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.play_circle_fill_rounded, color: t.accent, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarSeries(Anime a, ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Similar Series',
            style: GoogleFonts.inter(color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: a.recommendations.length,
            itemBuilder: (context, i) {
              final r = a.recommendations[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AnimeDetailScreen(id: r.id)),
                  );
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                              imageUrl: r.coverImage ?? '', 
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: t.surface2)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: t.text, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color ic, ThemeService t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ic),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(color: t.text, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
