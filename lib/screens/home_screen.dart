import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      final releaseNotes = updateData['body'] as String? ?? 'A new version of Harmber Movies is available.';
      
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
                    launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication);
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please wait, loading data...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Chunk 1: Hero & Trending (Crucial for first paint)
      final trending = await _api.getTrending();
      if (trending.isEmpty) throw Exception('Network failed');
      
      if (!mounted) return;
      setState(() {
        _trending = trending;
        _loading = false;
      });

      // Background logo fetch for heroes
      _fetchHeroLogos(trending.take(6).toList());

      // Start chunk 2 straight away to be faster
      _loadChunk2();

    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: _isScrolled 
                ? t.isDark ? Colors.black.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95)
                : Colors.transparent,
            gradient: _isScrolled
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
            boxShadow: _isScrolled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
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
              const Spacer(),
              _glassButton(
                icon: t.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onTap: () => ThemeService.instance.toggle(),
                isScrolledAndLight: _isScrolled && !t.isDark,
              ),
            ],
          ),
        ),
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
              placeholder: (_, __) =>
                  Container(color: const Color(0xFF0A0A0F)),
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

          // Content with staggered animations
          Positioned(
            left: 20,
            right: 20,
            bottom: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating + year + type badges
                Row(
                  children: [
                    _glassBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 14),
                          const SizedBox(width: 4),
                          Text(movie.rating,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (movie.year != 'N/A')
                      _glassBadge(
                        child: Text(movie.year,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    if (movie.isTV) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 4, 138, 210), Color.fromARGB(255, 25, 89, 199)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('TV SERIES',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideX(begin: -0.05),

                const SizedBox(height: 12),

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
                        : _heroTitle(movie))
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutCubic),

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
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms),

                const SizedBox(height: 18),

                // Action buttons
                Row(
                  children: [
                    // Watch button with gradient
                    _heroButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Watch Now',
                      filled: true,
                      onTap: () => _navigateToDetail(movie),
                    ),
                    const SizedBox(width: 12),
                    // Details button
                    _heroButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      filled: false,
                      onTap: () => _navigateToDetail(movie),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 500.ms)
                    .slideY(begin: 0.1),
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

  Widget _heroButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: filled ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: filled ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _glassBadge({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap, bool isScrolledAndLight = false}) {
    final color = isScrolledAndLight ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: color, size: 20),
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
