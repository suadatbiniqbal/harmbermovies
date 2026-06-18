import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/movie.dart';
import '../models/sports_match.dart';
import '../models/iptv_channel.dart';
import '../services/tmdb_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../services/sports_service.dart';
import '../widgets/section_row.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';
import 'sports_player_screen.dart';
import 'iptv_player_screen.dart';
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
  // Sports
  List<SportsMatch> _sports = [];
  StreamSubscription<List<SportsMatch>>? _sportsSub;
  // Countdown tickers per match id
  final Map<String, Duration> _countdowns = {};
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUpdate();
    _checkDiscordPromo();
    _scrollController.addListener(_onScroll);
    _initSports();
  }

  void _initSports() {
    SportsService.instance.startListening();
    _sportsSub = SportsService.instance.matchesStream.listen((matches) {
      if (!mounted) return;
      setState(() => _sports = matches);
      _startCountdownTicker();
    });
  }

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      bool needsRebuild = false;
      for (final m in _sports) {
        final r = m.timeUntilStreamOpen;
        if (r != null) {
          _countdowns[m.id] = r;
          needsRebuild = true;
        } else {
          _countdowns.remove(m.id);
        }
      }
      if (needsRebuild) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _sportsSub?.cancel();
    _countdownTicker?.cancel();
    SportsService.instance.stopListening();
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
        // Precache hero backdrop images for instant carousel rendering
        _precacheHeroImages();
        _loadChunk2();
        _loadChunk3();
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
          _loadChunk3();
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

  void _precacheHeroImages() {
    // Eagerly cache the first few hero backdrops for instant rendering
    final heroItems = _trending.take(4);
    for (final m in heroItems) {
      if (m.backdropUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(m.backdropUrl),
          context,
        );
      }
      if (m.posterUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(m.posterUrl),
          context,
        );
      }
    }
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
            _buildSportsSection(t),
            SectionRow(
                title: 'Trending Now',
                icon: Icons.trending_up_rounded,
                movies: _trending),
            const AdBannerContainer(),
            SectionRow(
                title: 'Popular Movies',
                icon: Icons.local_fire_department_rounded,
                movies: _popular,
                isLoading: !_chunk2Loaded),
            const AdBannerContainer(),
            SectionRow(
                title: 'Now Playing',
                icon: Icons.play_circle_outline_rounded,
                movies: _nowPlaying,
                isLoading: !_chunk3Loaded),
            const AdNativeContainer(),
            SectionRow(
                title: 'Top Rated',
                icon: Icons.star_rounded,
                movies: _topRated,
                isLoading: !_chunk2Loaded),
            const AdBannerContainer(),
            SectionRow(
                title: 'Coming Soon',
                icon: Icons.upcoming_rounded,
                movies: _upcoming,
                isLoading: !_chunk3Loaded),
            const AdBannerContainer(),
            SectionRow(
                title: 'Popular TV',
                icon: Icons.tv_rounded,
                movies: _popularTV,
                isLoading: !_chunk3Loaded),
            const AdBannerContainer(),
            SectionRow(
                title: 'Airing Today',
                icon: Icons.live_tv_rounded,
                movies: _airingToday,
                isLoading: !_chunk3Loaded),
            const AdBannerContainer(),
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
                'assets/logo_main.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF1A1A1A),
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
    // Latest 2 sports matches with a hero image prepended
    final sportsHeroes = _sports
        .where((m) => m.heroImageUrl.isNotEmpty)
        .take(2)
        .toList();
    final movieHeroes = _trending.take(6).toList();
    final totalCount = sportsHeroes.length + movieHeroes.length;
    if (totalCount == 0) return const SizedBox(height: 560);

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: totalCount,
          options: CarouselOptions(
            height: 560,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (i, _) => setState(() => _heroIndex = i),
          ),
          itemBuilder: (_, i, __) {
            if (i < sportsHeroes.length) {
              return _buildSportsHeroItem(sportsHeroes[i], t);
            }
            return _buildHeroItem(movieHeroes[i - sportsHeroes.length], t, i);
          },
        ),
        Positioned(
          bottom: 24,
          right: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              totalCount,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: _heroIndex == i ? 22 : 6,
                height: 3,
                decoration: BoxDecoration(
                  color: _heroIndex == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportsHeroItem(SportsMatch match, ThemeService t) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SportsPlayerScreen(match: match))),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: match.heroImageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF0A0A15)),
            errorWidget: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center, radius: 1.4,
                  colors: [Color(0xFF1A1040), Color(0xFF0A0A15)],
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0x00000000), Color(0xBB000000), Color(0xFF000000)],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Live badge
          if (match.isLive)
            Positioned(
              top: 60, left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('LIVE', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ]),
              ),
            ),
          Positioned(
            left: 20, right: 20, bottom: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (match.leagueName.isNotEmpty)
                  _heroBadge(icon: Icons.sports_soccer_rounded, text: match.leagueName),
                const SizedBox(height: 12),
                // Teams
                Row(
                  children: [
                    _sportsLogoSmall(match.team1LogoUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${match.team1Name}  vs  ${match.team2Name}',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w900, letterSpacing: -0.3, height: 1.2),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _sportsLogoSmall(match.team2LogoUrl),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SportsPlayerScreen(match: match))),
                  icon: const Icon(Icons.sports_rounded, size: 20),
                  label: Text(match.isLive ? 'Watch Live' : 'View Match',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    backgroundColor: match.isLive ? Colors.red : Colors.white,
                    foregroundColor: match.isLive ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sportsLogoSmall(String url) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.1),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: ClipOval(
      child: url.isNotEmpty
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer_rounded, color: Colors.white38, size: 18))
          : const Icon(Icons.sports_soccer_rounded, color: Colors.white38, size: 18),
    ),
  );

  Widget _buildHeroItem(Movie movie, ThemeService t, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetail(movie),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop
          if (movie.backdropUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: movie.backdropUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF080808)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF080808)),
            ),

          // Cinematic letterbox bar — top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 5,
            child: Container(color: Colors.black),
          ),

          // Dark overlay scrim
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x44000000),
                  Color(0x00000000),
                  Color(0x66000000),
                  Color(0xCC000000),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.2, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          // Left edge vignette
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4],
              ),
            ),
          ),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
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
                        solid: true,
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Logo or title
                (movie.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: movie.logoUrl,
                        height: 68,
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
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 20),

                // Action buttons
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
                            horizontal: 22, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToDetail(movie),
                      icon: const Icon(Icons.info_outline_rounded, size: 20),
                      label: Text('Info',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
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
    bool solid = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: solid
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
        ),
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

  // ─── SPORTS SECTION ────────────────────────────────────────────────────────
  Widget _buildSportsSection(ThemeService t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.red, Colors.orange]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Live Sports',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: t.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Text('LIVE', style: GoogleFonts.inter(
                    color: Colors.red, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: IptvChannels.all.length + _sports.length,
            itemBuilder: (_, i) {
              if (i < IptvChannels.all.length) {
                return _buildIptvChannelCard(IptvChannels.all[i], t);
              }
              return _buildSportsMatchCard(_sports[i - IptvChannels.all.length], t);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSportsMatchCard(SportsMatch match, ThemeService t) {
    final countdown = _countdowns[match.id];
    final isOpen = match.isStreamOpen;
    final isLive = match.isLive;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SportsPlayerScreen(match: match))),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(
            color: isLive
                ? Colors.red
                : Colors.black.withValues(alpha: 0.08),
            width: isLive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 16, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League + badge row
              Row(
                children: [
                  if (match.leagueLogoUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: match.leagueLogoUrl,
                      width: 16, height: 16, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      match.leagueName.isNotEmpty ? match.leagueName : 'Match',
                      style: GoogleFonts.inter(
                          color: Colors.black54,
                          fontSize: 10, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLive)
                    _liveBadge()
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(match.status.toUpperCase(),
                          style: GoogleFonts.inter(
                              color: Colors.black87,
                              fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Teams row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _matchTeam(match.team1LogoUrl, match.team1Name, t),
                  Text('vs',
                      style: GoogleFonts.inter(
                          color: Colors.black26,
                          fontSize: 12, fontWeight: FontWeight.w800)),
                  _matchTeam(match.team2LogoUrl, match.team2Name, t),
                ],
              ),
              const Spacer(),
              // Bottom strip — countdown or watch now
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.black.withValues(alpha: 0.04)
                      : Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOpen
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: isOpen
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.play_circle_rounded,
                            color: Colors.black87, size: 14),
                        const SizedBox(width: 5),
                        Text('Watch Now',
                            style: GoogleFonts.inter(
                                color: Colors.black87,
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ])
                    : _countdownRow(countdown, t),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96), duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _liveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text('LIVE', style: GoogleFonts.inter(
          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _teamInitial(String name, ThemeService t) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: GoogleFonts.inter(
          color: Colors.black54,
          fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );

  Widget _matchTeam(String logoUrl, String name, ThemeService t) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.05),
            ),
            child: ClipOval(
              child: logoUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: logoUrl, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => _teamInitial(name, t))
                  : _teamInitial(name, t),
            ),
          ),
          const SizedBox(height: 5),
          Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _countdownRow(Duration? remaining, ThemeService t) {
    if (remaining == null) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.play_circle_rounded, color: Colors.black87, size: 14),
        const SizedBox(width: 5),
        Text('Watch Now', style: GoogleFonts.inter(
            color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700)),
      ]);
    }
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    final label = h > 0
        ? '${h}h ${m.toString().padLeft(2,'0')}m ${s.toString().padLeft(2,'0')}s'
        : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.timer_outlined, color: Colors.orange, size: 13),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(
          color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildIptvChannelCard(IptvChannel ch, ThemeService t) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IptvPlayerScreen(
            channel: ch,
            allChannels: IptvChannels.all,
          ),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Live badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Text('LIVE', style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const Icon(Icons.play_circle_rounded,
                      color: Colors.black87, size: 18),
                ],
              ),
              const Spacer(),
              // Logo
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: ch.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ch.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv_rounded,
                              color: Colors.black45, size: 28),
                        )
                      : const Icon(Icons.live_tv_rounded,
                          color: Colors.black45, size: 28),
                ),
              ),
              const Spacer(),
              // Channel name
              Text(
                ch.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text('IPTV · DASH',
                  style: GoogleFonts.inter(
                      color: Colors.black45, fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96), duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
