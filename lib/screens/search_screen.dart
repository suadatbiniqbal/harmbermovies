import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../models/anime.dart';
import '../services/tmdb_service.dart';
import '../services/anilist_service.dart';
import '../services/theme_service.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';
import 'anime_detail_screen.dart';
import 'artists_screen.dart';

enum _SearchTab { all, movies, tv, anime }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  final _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  List<Genre> _genres = [];
  bool _searching = false;
  bool _loadingGenres = true;
  bool _hasError = false;
  _SearchTab _activeTab = _SearchTab.all;

  static const _genreColors = [
    [Color(0xFFD4A847), Color(0xFF9A7B2F)],
    [Color(0xFF374151), Color(0xFF1F2937)],
    [Color(0xFF065F46), Color(0xFF064E3B)],
    [Color(0xFFFF6B35), Color(0xFFD84315)],
    [Color(0xFF1F2937), Color(0xFF111827)],
    [Color(0xFF0F4C75), Color(0xFF063361)],
    [Color(0xFFFF5252), Color(0xFFC62828)],
    [Color(0xFF1A1A2E), Color(0xFF16213E)],
    [Color(0xFFFF9800), Color(0xFFE65100)],
    [Color(0xFF004D40), Color(0xFF00251A)],
    [Color(0xFF3E2723), Color(0xFF1B0000)],
    [Color(0xFFE91E63), Color(0xFF880E4F)],
    [Color(0xFF263238), Color(0xFF1C2831)],
    [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    [Color(0xFF827717), Color(0xFF524809)],
    [Color(0xFF0D47A1), Color(0xFF082D71)],
    [Color(0xFFBF360C), Color(0xFF7F2407)],
    [Color(0xFF4A148C), Color(0xFF2D0056)],
    [Color(0xFF006064), Color(0xFF003B3F)],
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

  static const _animeGenreIcons = <String, IconData>{
    'Action': Icons.local_fire_department_rounded,
    'Adventure': Icons.explore_rounded,
    'Comedy': Icons.sentiment_very_satisfied_rounded,
    'Drama': Icons.theater_comedy_rounded,
    'Fantasy': Icons.auto_awesome_rounded,
    'Horror': Icons.nightlight_rounded,
    'Mecha': Icons.rocket_launch_rounded,
    'Music': Icons.music_note_rounded,
    'Mystery': Icons.search_rounded,
    'Psychological': Icons.psychology_rounded,
    'Romance': Icons.favorite_rounded,
    'Sci-Fi': Icons.science_rounded,
    'Slice of Life': Icons.weekend_rounded,
    'Supernatural': Icons.auto_awesome_motion_rounded,
    'Thriller': Icons.warning_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final tabs = [
        _SearchTab.all,
        _SearchTab.movies,
        _SearchTab.tv,
        _SearchTab.anime
      ];
      setState(() => _activeTab = tabs[_tabController.index]);
      if (_controller.text.trim().isNotEmpty) {
        _triggerSearch(_controller.text.trim());
      }
    });
    _loadGenres();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await TmdbService.instance.getMovieGenres();
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
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _triggerSearch(term));
  }

  Future<void> _triggerSearch(String term) async {
    if (!mounted) return;
    setState(() => _searching = true);
    try {
      List<dynamic> results = [];
      switch (_activeTab) {
        case _SearchTab.all:
          final r = await Future.wait([
            TmdbService.instance.searchMulti(term).catchError((_) => <Movie>[]),
            AnilistService.instance.searchAnime(term).catchError((_) => <Anime>[]),
          ]);
          results = [...r[0], ...r[1]];
          break;
        case _SearchTab.movies:
          results = await TmdbService.instance.searchMovies(term).catchError((_) => <Movie>[]);
          break;
        case _SearchTab.tv:
          results = await TmdbService.instance.searchTV(term).catchError((_) => <Movie>[]);
          break;
        case _SearchTab.anime:
          results = await AnilistService.instance.searchAnime(term).catchError((_) => <Anime>[]);
          break;
      }
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
  }

  void _openGenre(Genre genre) async {
    try {
      final movies = await TmdbService.instance.getMoviesByGenre(genre.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _GenreResultsScreen(genre: genre, movies: movies),
        ),
      );
    } catch (_) {}
  }

  void _openAnimeGenre(Genre genre) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      final list = await AnilistService.instance.getAnimeByGenre(genre.name);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _AnimeGenreResultsScreen(genre: genre, animeList: list),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;
    final isSearching = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: t.isDark ? 0.25 : 0.06),
                      blurRadius: 14,
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
                    hintText: _activeTab == _SearchTab.anime
                        ? 'Search anime on AniList...'
                        : _activeTab == _SearchTab.movies
                            ? 'Search movies...'
                            : _activeTab == _SearchTab.tv
                                ? 'Search TV shows...'
                                : 'Search movies, shows, anime...',
                    hintStyle:
                        GoogleFonts.inter(color: t.textMuted, fontSize: 15),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: t.accent, size: 22),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: t.textMuted, size: 20),
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
            ),

            // ── Tab bar (always visible) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: t.accent,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: t.accent,
                unselectedLabelColor: t.textMuted,
                labelStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
                dividerColor: t.border.withValues(alpha: 0.5),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Movies'),
                  Tab(text: 'TV'),
                  Tab(text: 'Anime'),
                ],
              ),
            ),

            const SizedBox(height: 4),
            const AdBannerContainer(),

            // ── Content ──
            Expanded(
              child: isSearching ? _buildSearchResults(t) : _buildGenresGrid(t),
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
              child:
                  CircularProgressIndicator(strokeWidth: 2.5, color: t.accent),
            ),
            const SizedBox(height: 14),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: t.surface2,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.search_off_rounded, color: t.textMuted, size: 48),
            ),
            const SizedBox(height: 20),
            Text('No results found',
                style: GoogleFonts.inter(
                    color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Try a different search term',
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      scrollCacheExtent: const ScrollCacheExtent.pixels(400.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 136,
        childAspectRatio: 0.52,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) => _buildResultCard(_results[i], i, t),
    );
  }

  Widget _buildResultCard(dynamic m, int i, ThemeService t) {
    final bool isAnime = m is Anime;
    final bool isPerson = !isAnime && (m as Movie).mediaType == 'person';
    final bool isTV = !isAnime && !isPerson && m.isTV;

    final String title = m.title;
    final String imageUrl = isAnime ? (m.coverImage ?? '') : m.posterUrl;

    String subtitle = '';
    if (isAnime) {
      subtitle = m.year?.toString() ?? (m.format ?? 'Anime');
    } else if (isPerson) {
      subtitle = 'Actor / Director';
    } else {
      subtitle = m.year != 'N/A' ? m.year : '';
    }

    String badgeText = '';
    if (isAnime) {
      badgeText = m.format ?? 'ANIME';
    } else if (isPerson) {
      badgeText = 'ACTOR';
    } else if (isTV) {
      badgeText = 'TV';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) {
          if (isAnime) return AnimeDetailScreen(id: m.id, initialAnime: m);
          if (isPerson) return ArtistScreen(id: m.id);
          if (isTV) return TVDetailScreen(id: m.id);
          return MovieDetailScreen(id: m.id);
        }),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            httpHeaders: AnilistService.getHeadersForUrl(imageUrl),
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: t.surface2),
                            errorWidget: (_, __, ___) => Container(
                              color: t.surface2,
                              child: Icon(
                                  isPerson
                                      ? Icons.person_rounded
                                      : isAnime
                                          ? Icons.animation_rounded
                                          : Icons.movie_rounded,
                                  color: t.textMuted,
                                  size: 36),
                            ),
                          )
                        : Container(
                            color: t.surface2,
                            child: Icon(
                                isPerson
                                    ? Icons.person_rounded
                                    : Icons.movie_rounded,
                                color: t.textMuted,
                                size: 36),
                          ),

                    // Bottom gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Rating for movies/tv
                    if (!isAnime && !isPerson && m.voteAverage > 0)
                      Positioned(
                        bottom: 6,
                        left: 7,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFD700), size: 11),
                            const SizedBox(width: 2),
                            Text(m.rating,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),

                    // AniList score for anime
                    if (isAnime && m.averageScore != null)
                      Positioned(
                        bottom: 6,
                        left: 7,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFD700), size: 11),
                            const SizedBox(width: 2),
                            Text(m.averageScore!.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),

                     if (badgeText.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(badgeText,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                color: t.text, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }

  Widget _buildGenresGrid(ThemeService t) {
    final bool isAnimeTab = _activeTab == _SearchTab.anime;

    if (!isAnimeTab && _loadingGenres) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!isAnimeTab && _hasError) {
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

    final List<Genre> displayedGenres = isAnimeTab
        ? [
            Genre(id: 1, name: 'Action'),
            Genre(id: 2, name: 'Adventure'),
            Genre(id: 3, name: 'Comedy'),
            Genre(id: 4, name: 'Drama'),
            Genre(id: 5, name: 'Fantasy'),
            Genre(id: 6, name: 'Horror'),
            Genre(id: 7, name: 'Mecha'),
            Genre(id: 8, name: 'Music'),
            Genre(id: 9, name: 'Mystery'),
            Genre(id: 10, name: 'Psychological'),
            Genre(id: 11, name: 'Romance'),
            Genre(id: 12, name: 'Sci-Fi'),
            Genre(id: 13, name: 'Slice of Life'),
            Genre(id: 15, name: 'Supernatural'),
            Genre(id: 16, name: 'Thriller'),
          ]
        : _genres;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Container(
                width: 3,
                height: 22,
                decoration: BoxDecoration(
                    color: t.accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(
              isAnimeTab ? 'Browse Anime Genres' : 'Browse Categories',
              style: GoogleFonts.inter(
                color: t.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(displayedGenres.length, (i) {
            final genre = displayedGenres[i];
            final colors = _genreColors[i % _genreColors.length];
            final icon = isAnimeTab
                ? (_animeGenreIcons[genre.name] ?? Icons.animation_rounded)
                : (_genreIcons[genre.id] ?? Icons.movie_rounded);
            return GestureDetector(
              onTap: () => isAnimeTab ? _openAnimeGenre(genre) : _openGenre(genre),
              child: Container(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        genre.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
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
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: movies.isEmpty
          ? Center(
              child: Text('No movies found',
                  style: GoogleFonts.inter(color: t.textMuted)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 136,
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
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: m.posterUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: m.posterUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Container(color: t.surface2),
                            ),
                            if (m.voteAverage > 0)
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
                                      const SizedBox(width: 2),
                                      Text(m.rating,
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
                      Text(m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: t.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      Text(m.year,
                          style: GoogleFonts.inter(
                              color: t.textMuted, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AnimeGenreResultsScreen extends StatelessWidget {
  final Genre genre;
  final List<Anime> animeList;

  const _AnimeGenreResultsScreen({required this.genre, required this.animeList});

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        foregroundColor: t.text,
        title: Text(genre.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: animeList.isEmpty
          ? Center(
              child: Text('No anime found',
                  style: GoogleFonts.inter(color: t.textMuted)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 136,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: animeList.length,
              itemBuilder: (_, i) {
                final a = animeList[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailScreen(id: a.id, initialAnime: a),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: a.coverImage != null
                                  ? CachedNetworkImage(
                                      imageUrl: a.coverImage!,
                                      httpHeaders: AnilistService.imageHeaders,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Container(color: t.surface2),
                            ),
                            if (a.averageScore != null)
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
                                      const SizedBox(width: 2),
                                      Text(a.averageScore!.toStringAsFixed(1),
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
                      Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: t.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      if (a.year != null)
                        Text(a.year.toString(),
                            style: GoogleFonts.inter(
                                color: t.textMuted, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
