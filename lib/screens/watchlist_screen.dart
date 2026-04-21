import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';
import '../services/theme_service.dart';
import '../services/watchlist_service.dart';
import '../services/tmdb_service.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';
import 'anime_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Build a full image URL from a stored posterPath.
  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${TmdbService.instance.imageCdnBase}/w500$path';
  }

  List<Movie> _filterItems(List<Movie> items, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return items.where((m) => m.mediaType != 'anime' && !m.isTV).toList();
      case 2:
        return items.where((m) => m.isTV && m.mediaType != 'anime').toList();
      case 3:
        return items.where((m) => m.mediaType == 'anime').toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: WatchlistService.instance,
          builder: (context, _) {
            final allItems = WatchlistService.instance.items;
            final filtered = _filterItems(allItems, _tabController.index);

            return Scaffold(
              backgroundColor: t.bg,
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Watchlist',
                                style: GoogleFonts.inter(
                                  color: t.text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              if (allItems.isNotEmpty)
                                Text(
                                  '${allItems.length} title${allItems.length == 1 ? '' : 's'} saved',
                                  style: GoogleFonts.inter(
                                    color: t.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          if (allItems.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    t.accent,
                                    t.accent.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: t.accent.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${allItems.length}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tab Bar ──────────────────────────────────────
                    _buildTabBar(t),

                    const AdBannerContainer(),
                    const SizedBox(height: 8),

                    // ── Content ──────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState(t)
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 130,
                                childAspectRatio: 0.52,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                              cacheExtent: 400,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _WatchlistCard(
                                    movie: filtered[i],
                                    index: i,
                                    resolveUrl: _resolveImageUrl,
                                    onRemove: (id) =>
                                        _showRemoveSheet(id, t),
                                  ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar(ThemeService t) {
    final tabs = ['All', 'Movies', 'TV', 'Anime'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final selected = _tabController.index == i;
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? t.accent
                    : t.surface2,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Text(
                tabs[i],
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : t.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeService t) {
    final isFiltered = _tabController.index != 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered
                  ? Icons.filter_list_rounded
                  : Icons.bookmark_border_rounded,
              color: t.accent,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'Nothing here yet' : 'Nothing saved yet',
            style: GoogleFonts.inter(
                color: t.text, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'No items in this category'
                : 'Bookmark movies, shows, and anime\nto find them here later',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: t.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveSheet(int id, ThemeService t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: t.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bookmark_remove_rounded,
                  color: Colors.red.shade400, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Remove from Watchlist?',
                style: GoogleFonts.inter(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('This title will be removed from your saved list',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.text,
                      side: BorderSide(color: t.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final items = WatchlistService.instance.items;
                      final found = items.where((m) => m.id == id);
                      if (found.isNotEmpty) {
                        WatchlistService.instance.toggle(found.first);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Remove',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Private card widget ────────────────────────────────────────────────────

class _WatchlistCard extends StatelessWidget {
  final Movie movie;
  final int index;
  final String Function(String) resolveUrl;
  final void Function(int) onRemove;

  const _WatchlistCard({
    required this.movie,
    required this.index,
    required this.resolveUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    final resolvedUrl = resolveUrl(movie.posterUrl.isNotEmpty
        ? movie.posterUrl
        : movie.posterPath ?? '');

    return GestureDetector(
      onTap: () {
        if (movie.mediaType == 'anime') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AnimeDetailScreen(id: movie.id, initialMovie: movie)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => movie.isTV
                  ? TVDetailScreen(id: movie.id)
                  : MovieDetailScreen(id: movie.id),
            ),
          );
        }
      },
      onLongPress: () => onRemove(movie.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: resolvedUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolvedUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _shimmerBox(t),
                            errorWidget: (_, __, ___) => _fallback(t),
                          )
                        : _fallback(t),
                  ),

                  // Bookmark remove button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => onRemove(movie.id),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bookmark_rounded,
                            color: t.accent, size: 13),
                      ),
                    ),
                  ),

                  // Media type badge
                  if (movie.isTV || movie.mediaType == 'anime')
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: movie.mediaType == 'anime'
                                ? const [Color(0xFF8B5CF6), Color(0xFF6366F1)]
                                : const [
                                    Color(0xFF0EA5E9),
                                    Color(0xFF1D4ED8),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                            movie.mediaType == 'anime' ? 'ANIME' : 'TV',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                color: t.text, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(
            movie.year,
            style: GoogleFonts.inter(color: t.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(ThemeService t) {
    return Shimmer.fromColors(
      baseColor: t.surface2,
      highlightColor: t.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(color: Colors.white),
      ),
    );
  }

  Widget _fallback(ThemeService t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: t.surface2,
        child:
            Icon(Icons.movie_outlined, color: t.textMuted, size: 32),
      ),
    );
  }
}
