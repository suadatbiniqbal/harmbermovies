class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? logoPath;
  final double voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final List<Genre> genres;
  final String? runtime;
  final String? tagline;
  final String? status;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final bool isTV;
  final List<String> images;
  final String? mediaType;
  final int? budget;
  final int? revenue;
  final String? homepage;
  final List<ProductionCompany> productionCompanies;
  final List<SpokenLanguage> spokenLanguages;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.logoPath,
    required this.voteAverage,
    this.releaseDate,
    this.genreIds = const [],
    this.genres = const [],
    this.runtime,
    this.tagline,
    this.status,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.isTV = false,
    this.images = const [],
    this.mediaType,
    this.budget,
    this.revenue,
    this.homepage,
    this.productionCompanies = const [],
    this.spokenLanguages = const [],
  });

  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }

  String get logoUrl {
    if (logoPath == null || logoPath!.isEmpty) return '';
    if (logoPath!.startsWith('http')) return logoPath!;
    return 'https://image.tmdb.org/t/p/w500$logoPath';
  }

  String get year => releaseDate != null && releaseDate!.length >= 4
      ? releaseDate!.substring(0, 4)
      : 'N/A';

  String get rating => voteAverage.toStringAsFixed(1);

  factory Movie.fromJson(Map<String, dynamic> json) {
    final bool tv = json['first_air_date'] != null ||
        json['number_of_seasons'] != null ||
        json['media_type'] == 'tv' ||
        (json['name'] != null && json['title'] == null);
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      overview: json['overview'],
      posterPath: json['poster_path'] ?? json['profile_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      genres:
          (json['genres'] as List?)?.map((g) => Genre.fromJson(g)).toList() ??
              [],
      runtime: json['runtime'] != null
          ? '${json['runtime']} min'
          : json['episode_run_time'] != null &&
                  (json['episode_run_time'] as List).isNotEmpty
              ? '${json['episode_run_time'][0]} min/ep'
              : null,
      tagline: json['tagline'],
      status: json['status'],
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['numberOfEpisodes'] ?? json['number_of_episodes'],
      isTV: tv,
      logoPath: json['logoPath'] ?? json['logo_path'],
      mediaType: json['media_type'],
      budget: json['budget'],
      revenue: json['revenue'],
      homepage: json['homepage'],
      productionCompanies: (json['production_companies'] as List?)
              ?.map((c) => ProductionCompany.fromJson(c))
              .toList() ??
          [],
      spokenLanguages: (json['spoken_languages'] as List?)
              ?.map((l) => SpokenLanguage.fromJson(l))
              .toList() ??
          [],
    );
  }

  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? logoPath,
    double? voteAverage,
    String? releaseDate,
    List<int>? genreIds,
    List<Genre>? genres,
    String? runtime,
    String? tagline,
    String? status,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    bool? isTV,
    List<String>? images,
    String? mediaType,
    int? budget,
    int? revenue,
    String? homepage,
    List<ProductionCompany>? productionCompanies,
    List<SpokenLanguage>? spokenLanguages,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      logoPath: logoPath ?? this.logoPath,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
      tagline: tagline ?? this.tagline,
      status: status ?? this.status,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      isTV: isTV ?? this.isTV,
      images: images ?? this.images,
      mediaType: mediaType ?? this.mediaType,
      budget: budget ?? this.budget,
      revenue: revenue ?? this.revenue,
      homepage: homepage ?? this.homepage,
      productionCompanies: productionCompanies ?? this.productionCompanies,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': isTV ? null : title,
        'name': isTV ? title : null,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'vote_average': voteAverage,
        'release_date': isTV ? null : releaseDate,
        'first_air_date': isTV ? releaseDate : null,
        'number_of_seasons': numberOfSeasons,
        'number_of_episodes': numberOfEpisodes,
        'media_type': isTV ? 'tv' : 'movie',
      };
}

class Genre {
  final int id;
  final String name;
  Genre({required this.id, required this.name});
  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: json['id'], name: json['name']);
}

class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  String get profileUrl =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : '';

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
        id: json['id'],
        name: json['name'] ?? '',
        character: json['character'],
        profilePath: json['profile_path'],
      );
}

class Season {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final String? airDate;

  Season({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    required this.episodeCount,
    this.airDate,
  });

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';

  factory Season.fromJson(Map<String, dynamic> json) => Season(
        id: json['id'] ?? 0,
        seasonNumber: json['season_number'] ?? 0,
        name: json['name'] ?? '',
        overview: json['overview'],
        posterPath: json['poster_path'],
        episodeCount: json['episode_count'] ?? 0,
        airDate: json['air_date'],
      );
}

class Episode {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final double voteAverage;
  final String? airDate;
  final int? runtime;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.stillPath,
    required this.voteAverage,
    this.airDate,
    this.runtime,
  });

  String get stillUrl =>
      stillPath != null ? 'https://image.tmdb.org/t/p/w500$stillPath' : '';

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'] ?? 0,
        episodeNumber: json['episode_number'] ?? 0,
        seasonNumber: json['season_number'] ?? 0,
        name: json['name'] ?? '',
        overview: json['overview'],
        stillPath: json['still_path'],
        voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
        airDate: json['air_date'],
        runtime: json['runtime'],
      );
}

class ProductionCompany {
  final int id;
  final String name;
  final String? logoPath;

  ProductionCompany({required this.id, required this.name, this.logoPath});

  String get logoUrl =>
      logoPath != null ? 'https://image.tmdb.org/t/p/w200$logoPath' : '';

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      ProductionCompany(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        logoPath: json['logo_path'],
      );
}

class SpokenLanguage {
  final String name;
  final String englishName;

  SpokenLanguage({required this.name, required this.englishName});

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) => SpokenLanguage(
        name: json['name'] ?? '',
        englishName: json['english_name'] ?? '',
      );
}
