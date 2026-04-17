import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = ThemeService.instance;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: WatchlistService.instance,
          builder: (context, _) {
            final items = WatchlistService.instance.items;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        'My Watchlist',
                        style: GoogleFonts.inter(
                          color: t.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${items.length} saved',
                            style: GoogleFonts.inter(
                              color: t.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const AdBannerContainer(),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState(t)
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final m = items[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => m.isTV
                                      ? TVDetailScreen(id: m.id)
                                      : MovieDetailScreen(id: m.id),
                                ),
                              ),
                              onLongPress: () => _showRemoveSheet(m.id, t),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: m.posterUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: m.posterUrl,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        Container(
                                                            color:
                                                                t.surface2),
                                                  )
                                                : Container(
                                                    color: t.surface2,
                                                    child: Icon(
                                                        Icons.movie_outlined,
                                                        color: t.textMuted)),
                                          ),
                                          // Bookmark badge
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: GestureDetector(
                                              onTap: () => WatchlistService
                                                  .instance
                                                  .toggle(m),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.1)),
                                                ),
                                                child: Icon(
                                                    Icons.bookmark_rounded,
                                                    color: t.accent,
                                                    size: 14),
                                              ),
                                            ),
                                          ),
                                          // TV badge
                                          if (m.isTV)
                                            Positioned(
                                              top: 6,
                                              left: 6,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      t.accent,
                                                      t.accent.withValues(
                                                          alpha: 0.8),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5),
                                                ),
                                                child: Text('TV',
                                                    style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(m.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: t.text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text(m.year,
                                      style: GoogleFonts.inter(
                                          color: t.textMuted, fontSize: 11)),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: (40 * i).ms, duration: 350.ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  end: const Offset(1.0, 1.0),
                                  delay: (40 * i).ms,
                                  duration: 350.ms,
                                  curve: Curves.easeOutCubic,
                                );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeService t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border_rounded,
                color: t.accent, size: 56),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.08, duration: 2000.ms, curve: Curves.easeInOut),
          const SizedBox(height: 24),
          Text('Nothing saved yet',
              style: GoogleFonts.inter(
                  color: t.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Bookmark movies and shows\nto find them here later',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: t.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
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
            Icon(Icons.bookmark_remove_rounded, color: t.accent, size: 40),
            const SizedBox(height: 16),
            Text('Remove from Watchlist?',
                style: GoogleFonts.inter(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('This item will be removed from your saved list',
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
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final item = WatchlistService.instance.items
                          .firstWhere((m) => m.id == id);
                      WatchlistService.instance.toggle(item);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Remove',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
