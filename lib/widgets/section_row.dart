import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'movie_card.dart';
import 'section_header.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Movie> movies;
  final VoidCallback? onSeeAll;

  const SectionRow({
    super.key,
    required this.title,
    this.icon,
    required this.movies,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (_, i) => MovieCard(movie: movies[i], index: i),
          ),
        ),
      ],
    );
  }
}
