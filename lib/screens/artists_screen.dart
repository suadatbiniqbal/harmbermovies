import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/theme_service.dart';
import '../widgets/ad_banner.dart';
import 'movie_detail_screen.dart';
import 'tv_detail_screen.dart';

class ArtistScreen extends StatefulWidget {
  final int id;
  const ArtistScreen({super.key, required this.id});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final _api = TmdbService.instance;
  Map<String, dynamic> _person = {};
  List<Movie> _credits = [];
  List<String> _images = [];
  bool _loading = true;
  bool _expandBio = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _api.getPersonDetails(widget.id),
      _api.getPersonCredits(widget.id),
      _api.getPersonImages(widget.id),
    ]);
    if (!mounted) return;
    setState(() {
      _person = results[0] as Map<String, dynamic>;
      _credits = results[1] as List<Movie>;
      _images = results[2] as List<String>;
      _loading = false;
    });
  }

  int? _calculateAge(String? birthday) {
    if (birthday == null || birthday.isEmpty) return null;
    try {
      final bd = DateTime.parse(birthday);
      final now = DateTime.now();
      int age = now.year - bd.year;
      if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeService.instance;
    if (_loading) {
      return Scaffold(
          backgroundColor: t.bg,
          body: const Center(child: CircularProgressIndicator()));
    }

    final name = _person['name'] ?? 'Unknown';
    final profilePath = _person['profile_path'];
    final profileUrl = profilePath != null
        ? '${TmdbService.instance.imageCdnBase}/w500$profilePath'
        : '';
    final birthday = _person['birthday'] as String?;
    final deathday = _person['deathday'] as String?;
    final placeOfBirth = _person['place_of_birth'] as String?;
    final biography = _person['biography'] as String?;
    final knownFor = _person['known_for_department'] as String?;
    final age = _calculateAge(birthday);

    return Scaffold(
      backgroundColor: t.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: t.bg,
            foregroundColor: t.text,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black45, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (profileUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: profileUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: t.surface2,
                      child: Icon(Icons.person, color: t.textMuted, size: 80),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          t.bg.withValues(alpha: 0.5),
                          t.bg,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (age != null)
                        _infoCard(Icons.cake_rounded, 'Age', '$age years', t),
                      if (birthday != null)
                        _infoCard(
                            Icons.calendar_today_rounded, 'Born', birthday, t),
                      if (deathday != null)
                        _infoCard(Icons.event_rounded, 'Died', deathday, t),
                      if (placeOfBirth != null)
                        _infoCard(Icons.location_on_rounded, 'Birthplace',
                            placeOfBirth, t),
                      if (knownFor != null)
                        _infoCard(Icons.work_rounded, 'Known For', knownFor, t),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const AdBannerContainer(),
                  const SizedBox(height: 16),

                  // Biography
                  if (biography != null && biography.isNotEmpty) ...[
                    Text('Biography',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expandBio = !_expandBio),
                      child: Text(
                        biography,
                        maxLines: _expandBio ? null : 6,
                        overflow: _expandBio ? null : TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: t.textMuted, fontSize: 14, height: 1.6),
                      ),
                    ),
                    if (biography.length > 300)
                      TextButton(
                        onPressed: () =>
                            setState(() => _expandBio = !_expandBio),
                        child: Text(
                          _expandBio ? 'Show Less' : 'Read More',
                          style: GoogleFonts.inter(
                              color: t.accent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // Images
                  if (_images.isNotEmpty) ...[
                    Text('Photos',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (_, i) => Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                                imageUrl: _images[i], fit: BoxFit.cover),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (50 * i).ms, duration: 300.ms),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Filmography
                  if (_credits.isNotEmpty) ...[
                    Text('Filmography',
                        style: GoogleFonts.inter(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${_credits.length} credits',
                        style: GoogleFonts.inter(
                            color: t.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _credits.length.clamp(0, 30),
                        itemBuilder: (_, i) {
                          final m = _credits[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => m.isTV
                                    ? TVDetailScreen(id: m.id)
                                    : MovieDetailScreen(id: m.id),
                              ),
                            ),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: m.posterUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: m.posterUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity)
                                          : Container(color: t.surface2),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
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
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (40 * i).ms, duration: 300.ms);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, ThemeService t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: t.accent, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: t.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
