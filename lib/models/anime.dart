import 'movie.dart';

class Anime {
  final int id;
  final String title;
  final String? coverImage;
  final String? bannerImage;
  final String? description;
  final int? episodes;
  final double? averageScore;
  final String? status;
  final List<String> genres;
  final String? format;
  final int? year;
  final String? season;
  final List<AnimeRelation> relations;
  final List<AnimeRecommendation> recommendations;
  final List<AnimeEpisode> streamingEpisodes;
  final List<String> studios;
  final Map<String, dynamic>? nextAiringEpisode;

  Anime({
    required this.id,
    required this.title,
    this.coverImage,
    this.bannerImage,
    this.description,
    this.episodes,
    this.averageScore,
    this.status,
    this.genres = const [],
    this.format,
    this.year,
    this.season,
    this.relations = const [],
    this.recommendations = const [],
    this.streamingEpisodes = const [],
    this.studios = const [],
    this.nextAiringEpisode,
  });

  factory Anime.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Anime(id: 0, title: 'Unknown');

    return Anime(
      id: json['id'] ?? 0,
      title: json['title']?['english'] ??
          json['title']?['romaji'] ??
          json['title']?['native'] ??
          'Unknown',
      coverImage: json['coverImage']?['extraLarge'] ??
          json['coverImage']?['large'] ??
          json['coverImage']?['medium'],
      bannerImage: json['bannerImage'],
      description: json['description'],
      episodes: json['episodes'],
      averageScore: json['averageScore'] != null
          ? (json['averageScore'] as num).toDouble() / 10
          : null,
      status: json['status'],
      genres: List<String>.from(json['genres'] ?? []),
      format: json['format'],
      year: json['seasonYear'],
      season: json['season'],
      relations: (json['relations']?['edges'] as List?)
              ?.map((e) => AnimeRelation.fromJson(e))
              .toList() ??
          [],
      recommendations: (json['recommendations']?['nodes'] as List?)
              ?.map((n) {
                if (n is Map<String, dynamic> &&
                    n.containsKey('mediaRecommendation')) {
                  return AnimeRecommendation.fromJson(n['mediaRecommendation']);
                }
                return AnimeRecommendation.fromJson(n);
              })
              .where((r) => r.id != 0)
              .toList() ??
          [],
      streamingEpisodes: (json['streamingEpisodes'] as List?)
              ?.map((e) => AnimeEpisode.fromJson(e))
              .toList() ??
          [],
      studios: (json['studios']?['nodes'] as List?)
              ?.map((s) => s != null && s is Map ? s['name'] as String? : null)
              .whereType<String>()
              .toList() ??
          [],
      nextAiringEpisode: json['nextAiringEpisode'],
    );
  }

  Movie toMovie() {
    return Movie(
      id: id,
      title: title,
      overview: description,
      posterPath: coverImage,
      backdropPath: bannerImage,
      voteAverage: averageScore ?? 0.0,
      releaseDate: year?.toString(),
      isTV: true,
      mediaType: 'anime', // Custom identifier to determine routing downstream
    );
  }
}

class AnimeEpisode {
  final int id;
  final String title;
  final String? thumbnail;
  final String? url;
  final int number;

  AnimeEpisode({
    required this.id,
    required this.title,
    this.thumbnail,
    this.url,
    required this.number,
  });

  factory AnimeEpisode.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AnimeEpisode(id: 0, title: 'Unknown', number: 0);

    String? epTitle = json['title'];
    if (epTitle == null && json['number'] != null) {
      epTitle = 'Episode ${json['number']}';
    }

    return AnimeEpisode(
      id: json['id'] ?? 0,
      title: epTitle ?? 'Unknown Episode',
      thumbnail: json['thumbnail'],
      url: json['url'],
      number: json['number'] ?? 0,
    );
  }
}

class AnimeRelation {
  final int id;
  final String title;
  final String? coverImage;
  final String relationType;
  final String? format;
  final String? status;

  AnimeRelation({
    required this.id,
    required this.title,
    this.coverImage,
    required this.relationType,
    this.format,
    this.status,
  });

  factory AnimeRelation.fromJson(Map<String, dynamic>? json) {
    if (json == null || json['node'] == null) {
      return AnimeRelation(id: 0, title: 'Unknown', relationType: '');
    }
    final media = json['node'];
    return AnimeRelation(
      id: media['id'] ?? 0,
      title:
          media['title']?['english'] ?? media['title']?['romaji'] ?? 'Unknown',
      coverImage: media['coverImage']?['large'],
      relationType: json['relationType'] ?? '',
      format: media['format'],
      status: media['status'],
    );
  }
}

class AnimeRecommendation {
  final int id;
  final String title;
  final String? coverImage;
  final double? averageScore;

  AnimeRecommendation({
    required this.id,
    required this.title,
    this.coverImage,
    this.averageScore,
  });

  factory AnimeRecommendation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AnimeRecommendation(id: 0, title: 'Unknown');
    return AnimeRecommendation(
      id: json['id'] ?? 0,
      title: json['title']?['english'] ?? json['title']?['romaji'] ?? 'Unknown',
      coverImage: json['coverImage']?['large'],
      averageScore: json['averageScore'] != null
          ? (json['averageScore'] as num).toDouble() / 10
          : null,
    );
  }
}
