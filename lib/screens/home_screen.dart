import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../widgets/section_row.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';
import '../widgets/history_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _api = TmdbService.instance;
  final _scrollController = ScrollController();
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _topRated = [];
  List<Movie> _nowPlaying = [];
  List<Movie> _upcoming = [];
  List<Movie> _popularTV = [];
  List<Movie> _airingToday = [];
  List<Movie> _topRatedTV = [];
  bool _loading = true;
  bool _hasError = false;
  int _heroIndex = 0;
  bool _isScrolled = false;
  bool _chunk2Loaded = false;
  bool _chunk3Loaded = false;
  bool _isLoadingChunk2 = false;
  bool _isLoadingChunk3 = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUpdate();
    _checkDiscordPromo();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }

    if (_scrollController.offset > 100 && !_chunk2Loaded && !_isLoadingChunk2) {
      _loadChunk2();
    }

    if (_scrollController.offset > 400 && !_chunk3Loaded && !_isLoadingChunk3) {
      _loadChunk3();
    }
  }

  Future<void> _checkUpdate() async {
    final updateData = await UpdateService.checkForUpdate();
    if (updateData != null && mounted) {
      final apkUrl = UpdateService.getApkUrl(updateData);
      final releaseNotes = updateData['body'] as String? ??
          'A new version of Harmber Movies is available.';

      if (apkUrl != null) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: CupertinoAlertDialog(
              title: const Text('New Update Available!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please update to continue enjoying the app.'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      releaseNotes,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    launchUrl(Uri.parse(apkUrl),
                        mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Update Now'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _checkDiscordPromo() {
    if (Random().nextDouble() < 0.25) {
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Join Our Community!'),
            content: const Text(
                'Connect with other movie fans, request features, and stay up to date on our Discord server!'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse('https://discord.gg/BMTnet53E6'),
                      mode: LaunchMode.externalApplication);
                },
                child: const Text('Let\'s Go!'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _chunk2Loaded = false;
      _chunk3Loaded = false;
      _isLoadingChunk2 = false;
      _isLoadingChunk3 = false;
      _popular = [];
      _topRated = [];
      _nowPlaying = [];
      _upcoming = [];
      _popularTV = [];
      _airingToday = [];
      _topRatedTV = [];
    });

    try {
      // Chunk 1: Hero & Trending (Crucial for first paint)
      final trending = await _api.getTrending();

      if (!mounted) return;
      setState(() {
        if (trending.isNotEmpty) _trending = trending;
        _loading = false;
        _hasError = trending.isEmpty && _trending.isEmpty;
      });

      if (!_hasError) {
        _fetchHeroLogos((_trending).take(6).toList());
        _loadChunk2();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = _trending.isEmpty;
        });
        if (!_hasError) {
          // Quietly show cached content with a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Showing cached content — offline mode'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              duration: const Duration(seconds: 3),
            ),
          );
          _loadChunk2();
        }
      }
    }
  }

  Future<void> _loadChunk2() async {
    if (_isLoadingChunk2 || _chunk2Loaded) return;
    setState(() => _isLoadingChunk2 = true);
    try {
      final nextChunk = await Future.wait([
        _api.getPopularMovies(),
        _api.getTopRatedMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _popular = nextChunk[0];
        _topRated = nextChunk[1];
        _chunk2Loaded = true;
        _isLoadingChunk2 = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingChunk2 = false);
    }
  }

  Future<void> _loadChunk3() async {
    if (_isLoadingChunk3 || _chunk3Loaded) return;
    setState(() => _isLoadingChunk3 = true);
    try {
      final finalChunk = await Future.wait([
        _api.getNowPlaying(),
        _api.getUpcoming(),
        _api.getPopularTV(),
        _api.getAiringToday(),
        _api.getTopRatedTV(),
      ]);
      if (!mounted) return;
      setState(() {
        _nowPlaying = finalChunk[0];
        _upcoming = finalChunk[1];
        _popularTV = finalChunk[2];
        _airingToday = finalChunk[3];
        _topRatedTV = finalChunk[4];
        _chunk3Loaded = true;
        _isLoadingChunk3 = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingChunk3 = false);
    }
  }

  Future<void> _fetchHeroLogos(List<Movie> heroItems) async {
    try {
      final logoPathResults = await Future.wait(
          heroItems.map((m) => _api.getLogoPath(m.id, isTV: m.isTV)));

      if (!mounted) return;
      setState(() {
        _trending = _trending.asMap().entries.map((entry) {
          if (entry.key < 6 && entry.key < logoPathResults.length) {
            return entry.value.copyWith(logoPath: logoPathResults[entry.key]);
          }
          return entry.value;
        }).toList();
      });
    } catch (_) {}
  }

  void _navigateToDetail(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => movie.isTV
            ? TVDetailScreen(id: movie.id)
            : MovieDetailScreen(id: movie.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    final Widget content;

    if (_loading) {
      content = _buildShimmer(t);
    } else if (_hasError) {
      content = Center(
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
      );
    } else {
      content = RefreshIndicator(
        color: t.accent,
        backgroundColor: t.surface,
        onRefresh: _loadData,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHeroCarousel(t),
            const AdBannerContainer(),
            const HistoryRow(mediaTypeFilter: 'tmdb'),
            SectionRow(
                title: 'Trending Now',
                icon: Icons.trending_up_rounded,
                movies: _trending),
            SectionRow(
                title: 'Popular Movies',
                icon: Icons.local_fire_department_rounded,
                movies: _popular,
                isLoading: !_chunk2Loaded),
            SectionRow(
                title: 'Now Playing',
                icon: Icons.play_circle_outline_rounded,
                movies: _nowPlaying,
                isLoading: !_chunk3Loaded),
            SectionRow(
                title: 'Top Rated',
                icon: Icons.star_rounded,
                movies: _topRated,
                isLoading: !_chunk2Loaded),
            SectionRow(
                title: 'Coming Soon',
                icon: Icons.upcoming_rounded,
                movies: _upcoming,
                isLoading: !_chunk3Loaded),
            SectionRow(
                title: 'Popular TV',
                icon: Icons.tv_rounded,
                movies: _popularTV,
                isLoading: !_chunk3Loaded),
            SectionRow(
                title: 'Airing Today',
                icon: Icons.live_tv_rounded,
                movies: _airingToday,
                isLoading: !_chunk3Loaded),
            SectionRow(
                title: 'Top Rated TV',
                icon: Icons.emoji_events_rounded,
                movies: _topRatedTV,
                isLoading: !_chunk3Loaded),
            const SizedBox(height: 16),
            const AdBannerContainer(),
            const SizedBox(height: 60),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        scrolledUnderElevation: 4,
        backgroundColor: _isScrolled
            ? (t.isDark ? const Color(0xFF0A0A0F) : Colors.white)
            : Colors.transparent,
        surfaceTintColor: t.isDark ? const Color(0xFF0A0A0F) : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Harmber Movies',
              style: GoogleFonts.inter(
                color: _isScrolled && !t.isDark ? Colors.black87 : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ThemeService.instance.toggle(),
            icon: Icon(
              t.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color:
                  _isScrolled && !t.isDark ? Colors.black87 : Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  (_isScrolled && !t.isDark ? Colors.black87 : Colors.white)
                      .withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }

  Widget _buildHeroCarousel(ThemeService t) {
    final heroes = _trending.take(6).toList();
    if (heroes.isEmpty) return const SizedBox(height: 500);

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: heroes.length,
          options: CarouselOptions(
            height: 520,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 1000),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (i, _) => setState(() => _heroIndex = i),
          ),
          itemBuilder: (_, i, __) => _buildHeroItem(heroes[i], t, i),
        ),

        // Page indicators
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              heroes.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _heroIndex == i ? 28 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: _heroIndex == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: _heroIndex == i
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroItem(Movie movie, ThemeService t, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetail(movie),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop with parallax feel
          if (movie.backdropUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: movie.backdropUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF0A0A0F)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF0A0A0F)),
            ),

          // Multi-layer gradient for cinematic depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  t.bg.withValues(alpha: 0.4),
                  t.bg.withValues(alpha: 0.85),
                  t.bg,
                ],
                stops: const [0.0, 0.25, 0.55, 0.75, 1.0],
              ),
            ),
          ),
          // Left edge gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  t.bg.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating + year + type badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroBadge(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFD700),
                      text: movie.rating,
                    ),
                    if (movie.year != 'N/A')
                      _heroBadge(
                        icon: Icons.calendar_today_rounded,
                        text: movie.year,
                      ),
                    if (movie.isTV)
                      _heroBadge(
                        icon: Icons.live_tv_rounded,
                        text: 'TV SERIES',
                        gradient: const [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Logo or title
                (movie.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: movie.logoUrl,
                        height: 70,
                        width: MediaQuery.of(context).size.width * 0.65,
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => _heroTitle(movie),
                      )
                    : _heroTitle(movie)),

                const SizedBox(height: 10),

                // Overview
                if (movie.overview != null && movie.overview!.isNotEmpty)
                  Text(
                    movie.overview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 18),

                // Material 3 action buttons
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _navigateToDetail(movie),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text('Watch Now',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToDetail(movie),
                      icon: const Icon(Icons.info_outline_rounded, size: 20),
                      label: Text('Details',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTitle(Movie movie) {
    return Text(
      movie.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.15,
      ),
    );
  }

  Widget _heroBadge({
    required IconData icon,
    required String text,
    Color? iconColor,
    List<Color>? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient != null ? LinearGradient(colors: gradient) : null,
        color: gradient == null ? Colors.white.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
        border: gradient == null
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? Colors.white70),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeService t) {
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(height: 520, color: Colors.white),
          const SizedBox(height: 24),
          ...List.generate(
            4,
            (section) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 140,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (_, __) => Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
