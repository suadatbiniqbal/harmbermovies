import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'movie_card.dart';
import 'section_header.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Movie> movies;
  final VoidCallback? onSeeAll;
  final bool isLoading;

  const SectionRow({
    super.key,
    required this.title,
    this.icon,
    required this.movies,
    this.onSeeAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty && !isLoading) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
          SizedBox(
            height: 270,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    addAutomaticKeepAlives: false,
                    itemBuilder: (_, __) => Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: movies.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemBuilder: (_, i) =>
                        MovieCard(movie: movies[i], index: i),
                  ),
          ),
        ],
      ),
    );
  }
}
