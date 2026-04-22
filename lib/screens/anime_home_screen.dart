import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/anime.dart';
import '../services/anilist_service.dart';
import '../services/theme_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/anime_card.dart';
import '../widgets/section_header.dart';
import 'anime_detail_screen.dart';
import '../widgets/history_row.dart';

class AnimeHomeScreen extends StatefulWidget {
  const AnimeHomeScreen({super.key});

  @override
  State<AnimeHomeScreen> createState() => _AnimeHomeScreenState();
}

class _AnimeHomeScreenState extends State<AnimeHomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _api = AnilistService.instance;
  final _scrollController = ScrollController();
  List<Anime> _trending = [];
  List<Anime> _popular = [];
  List<Anime> _topRated = [];
  bool _loading = true;
  bool _hasError = false;
  int _heroIndex = 0;
  bool _isScrolled = false;
  bool _chunk2Loaded = false;
  bool _isLoadingChunk2 = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _chunk2Loaded = false;
      _isLoadingChunk2 = false;
      _popular = [];
      _topRated = [];
    });

    try {
      final trending = await _api.getTrendingAnime();

      if (!mounted) return;
      setState(() {
        if (trending.isNotEmpty) _trending = trending;
        _loading = false;
        // Only set error if we have zero data to show
        _hasError = trending.isEmpty && _trending.isEmpty;
      });

      if (!_hasError) _loadChunk2();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          // Only hard-error if we have no cached data
          _hasError = _trending.isEmpty;
        });
        // If we do have cached data, show a quiet snackbar
        if (!_hasError) {
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
        _api.getPopularAnime(),
        _api.getTopRatedAnime(),
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

  void _navigateToDetail(Anime anime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimeDetailScreen(id: anime.id, initialAnime: anime),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
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
                  'Failed to load Anime\nPlease check your connection',
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
                const SizedBox(height: 8),
                const AdBannerContainer(),
                const HistoryRow(mediaTypeFilter: 'anime'),
                const SizedBox(height: 8),
                _buildAnimeSection(
                    'Trending Anime', Icons.trending_up, _trending),
                _buildAnimeSection('Popular Anime', Icons.local_fire_department,
                    _popular, !_chunk2Loaded),
                const AdBannerContainer(),
                const SizedBox(height: 8),
                _buildAnimeSection('Top Rated Anime', Icons.star_rounded,
                    _topRated, !_chunk2Loaded),
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
            surfaceTintColor:
                t.isDark ? const Color(0xFF0A0A0F) : Colors.white,
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
                  'Harmber Anime',
                  style: GoogleFonts.inter(
                    color: _isScrolled && !t.isDark
                        ? Colors.black87
                        : Colors.white,
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
                  t.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: _isScrolled && !t.isDark
                      ? Colors.black87
                      : Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor:
                      (_isScrolled && !t.isDark
                              ? Colors.black87
                              : Colors.white)
                          .withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildAnimeSection(String title, IconData icon, List<Anime> animeList,
      [bool isLoading = false]) {
    final t = ThemeService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, icon: icon),
        SizedBox(
          height: 270,
          child: isLoading || animeList.isEmpty
              ? _buildHorizontalShimmer(t)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: animeList.length,
                  itemBuilder: (_, i) =>
                      AnimeCard(anime: animeList[i], index: i),
                ),
        ),
      ],
    );
  }

  Widget _buildHeroCarousel(ThemeService t) {
    final heroes = _trending.take(6).toList();
    if (heroes.isEmpty) return const SizedBox(height: 560);

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: heroes.length,
          options: CarouselOptions(
            height: 560,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (i, _) => setState(() => _heroIndex = i),
          ),
          itemBuilder: (_, i, __) => _buildHeroItem(heroes[i], t, i),
        ),
        // Page indicators — bottom right
        Positioned(
          bottom: 24,
          right: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              heroes.length,
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

  Widget _buildHeroItem(Anime anime, ThemeService t, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetail(anime),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (anime.bannerImage != null || anime.coverImage != null)
            CachedNetworkImage(
              imageUrl: anime.bannerImage ?? anime.coverImage ?? '',
              fit: BoxFit.cover,
              alignment: Alignment.center,
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

          Positioned(
            left: 20,
            right: 20,
            bottom: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (anime.averageScore != null)
                      _heroBadge(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD700),
                        text: anime.averageScore!.toStringAsFixed(1),
                      ),
                    if (anime.year != null)
                      _heroBadge(
                        icon: Icons.calendar_today_rounded,
                        text: anime.year.toString(),
                      ),
                    if (anime.format != null)
                      _heroBadge(
                        icon: Icons.movie_filter_rounded,
                        text: anime.format!,
                        solid: true,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _heroTitle(anime),
                const SizedBox(height: 20),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _navigateToDetail(anime),
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
                      onPressed: () => _navigateToDetail(anime),
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

  Widget _heroTitle(Anime anime) {
    return Text(
      anime.title,
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
            3,
            (_) => Column(
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
                _buildHorizontalShimmer(t, false),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalShimmer(ThemeService t, [bool useShimmer = true]) {
    final list = ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    if (!useShimmer) return SizedBox(height: 270, child: list);
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.surface,
      child: SizedBox(height: 270, child: list),
    );
  }
}
