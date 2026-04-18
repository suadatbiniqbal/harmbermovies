import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class TmdbService {
  static final TmdbService instance = TmdbService._();
  TmdbService._();

  static const _apiKey = '8265bd1679663a7ea12ac168da84d2e8';
  static const _base = 'https://api.themoviedb.org/3';

  final Map<String, _CacheEntry> _cache = {};
  final _client = http.Client();
  SharedPreferences? _prefs;

  Future<void> _initCache() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs!.getString('tmdb_cache');
    if (stored != null) {
      try {
        final map = json.decode(stored) as Map<String, dynamic>;
        map.forEach((k, v) {
          _cache[k] = _CacheEntry(v['data'], timestamp: DateTime.parse(v['timestamp']));
        });
      } catch (_) {}
    }
  }

  void _saveCache() {
    if (_prefs == null) return;
    final map = _cache.map((k, v) => MapEntry(k, {
      'data': v.data,
      'timestamp': v.timestamp.toIso8601String(),
    }));
    _prefs!.setString('tmdb_cache', json.encode(map));
  }

  Future<List<Movie>> _fetchList(String path,
      {Map<String, String>? params, int retries = 3}) async {
    await _initCache();
    final cacheKey = 'list_$path${params?.toString() ?? ""}';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return (_cache[cacheKey]!.data as List)
          .where((j) => j['media_type'] != 'person')
          .map((j) => Movie.fromJson(j))
          .toList();
    }

    for (int i = 0; i < retries; i++) {
      try {
        final uri = Uri.parse('$_base$path').replace(queryParameters: {
          'api_key': _apiKey,
          ...?params,
        });
        final res = await _client.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final results = data['results'] as List? ?? [];
          _cache[cacheKey] = _CacheEntry(results);
          _saveCache();
          return results
              .where((j) => j['media_type'] != 'person')
              .map((j) => Movie.fromJson(j))
              .toList();
        } else if (res.statusCode == 429) {
          // Rate limited, wait and retry
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (_) {
        if (i < retries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> _fetchJson(String path,
      {Map<String, String>? params, int retries = 3}) async {
    await _initCache();
    final cacheKey = 'json_$path${params?.toString() ?? ""}';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return Map<String, dynamic>.from(_cache[cacheKey]!.data);
    }

    for (int i = 0; i < retries; i++) {
      try {
        final uri = Uri.parse('$_base$path').replace(queryParameters: {
          'api_key': _apiKey,
          ...?params,
        });
        final res = await _client.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          _cache[cacheKey] = _CacheEntry(data);
          _saveCache();
          return data;
        } else if (res.statusCode == 429) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (_) {
        if (i < retries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
    }
    return {};
  }

  // ── Movies ──
  Future<List<Movie>> getTrending() => _fetchList('/trending/all/week');
  Future<List<Movie>> getPopularMovies() => _fetchList('/movie/popular');
  Future<List<Movie>> getTopRatedMovies() => _fetchList('/movie/top_rated');
  Future<List<Movie>> getNowPlaying() => _fetchList('/movie/now_playing');
  Future<List<Movie>> getUpcoming() => _fetchList('/movie/upcoming');

  // ── TV ──
  Future<List<Movie>> getTrendingTV() => _fetchList('/trending/tv/week');
  Future<List<Movie>> getPopularTV() => _fetchList('/tv/popular');
  Future<List<Movie>> getTopRatedTV() => _fetchList('/tv/top_rated');
  Future<List<Movie>> getAiringToday() => _fetchList('/tv/airing_today');
  Future<List<Movie>> getOnTheAirTV() => _fetchList('/tv/on_the_air');

  // ── Details ──
  Future<Movie> getMovieDetails(int id) async {
    final data = await _fetchJson('/movie/$id');
    if (data.isEmpty) return Movie(id: id, title: 'Error', voteAverage: 0);
    return Movie.fromJson(data);
  }

  Future<Movie> getTVDetails(int id) async {
    final data = await _fetchJson('/tv/$id');
    if (data.isEmpty) return Movie(id: id, title: 'Error', voteAverage: 0);
    return Movie.fromJson(data);
  }

  // ── Credits ──
  Future<List<CastMember>> getMovieCredits(int id) async {
    final data = await _fetchJson('/movie/$id/credits');
    return (data['cast'] as List? ?? [])
        .map((j) => CastMember.fromJson(j))
        .toList();
  }

  Future<List<CastMember>> getTVCredits(int id) async {
    final data = await _fetchJson('/tv/$id/credits');
    return (data['cast'] as List? ?? [])
        .map((j) => CastMember.fromJson(j))
        .toList();
  }

  // ── Images ──
  Future<List<String>> getMovieImages(int id) async {
    final data = await _fetchJson('/movie/$id/images');
    final backdrops = data['backdrops'] as List? ?? [];
    return backdrops
        .map<String>((i) => 'https://image.tmdb.org/t/p/w780${i['file_path']}')
        .take(20)
        .toList();
  }

  Future<List<String>> getTVImages(int id) async {
    final data = await _fetchJson('/tv/$id/images');
    final backdrops = data['backdrops'] as List? ?? [];
    return backdrops
        .map<String>((i) => 'https://image.tmdb.org/t/p/w780${i['file_path']}')
        .take(20)
        .toList();
  }

  Future<String?> getLogoPath(int id, {bool isTV = false}) async {
    final type = isTV ? 'tv' : 'movie';
    final data = await _fetchJson('/$type/$id/images',
        params: {'include_image_language': 'en,null'});
    final logos = data['logos'] as List? ?? [];
    if (logos.isEmpty) return null;
    return logos.first['file_path'];
  }

  // ── Similar ──
  Future<List<Movie>> getSimilarMovies(int id) =>
      _fetchList('/movie/$id/similar');
  Future<List<Movie>> getSimilarTV(int id) => _fetchList('/tv/$id/similar');

  // ── Search ──
  Future<List<Movie>> searchMulti(String query) async {
    final cacheKey = 'search_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return (_cache[cacheKey]!.data as List).map((j) => Movie.fromJson(j)).toList();
    }

    for (int i = 0; i < 3; i++) {
      try {
        final uri = Uri.parse('$_base/search/multi').replace(queryParameters: {
          'api_key': _apiKey,
          'query': query,
        });
        final res = await _client.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final rawResults = data['results'] as List? ?? [];
          _cache[cacheKey] = _CacheEntry(rawResults);
          return rawResults.map((j) => Movie.fromJson(j)).toList();
        } else if (res.statusCode == 429) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (_) {
        if (i < 2) await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return [];
  }

  // ── Genres ──
  Future<List<Genre>> getMovieGenres() async {
    final data = await _fetchJson('/genre/movie/list');
    return (data['genres'] as List? ?? [])
        .map((g) => Genre.fromJson(g))
        .toList();
  }

  Future<List<Genre>> getTVGenres() async {
    final data = await _fetchJson('/genre/tv/list');
    return (data['genres'] as List? ?? [])
        .map((g) => Genre.fromJson(g))
        .toList();
  }

  Future<List<Movie>> getMoviesByGenre(int genreId) =>
      _fetchList('/discover/movie',
          params: {'with_genres': '$genreId', 'sort_by': 'popularity.desc'});

  // ── Person ──
  Future<Map<String, dynamic>> getPersonDetails(int id) =>
      _fetchJson('/person/$id');

  Future<List<Movie>> getPersonCredits(int id) async {
    final data = await _fetchJson('/person/$id/combined_credits');
    final cast = data['cast'] as List? ?? [];
    return cast
        .where((j) => j['poster_path'] != null)
        .map((j) => Movie.fromJson(j))
        .toList();
  }

  Future<List<String>> getPersonImages(int id) async {
    final data = await _fetchJson('/person/$id/images');
    final profiles = data['profiles'] as List? ?? [];
    return profiles
        .map<String>((i) => 'https://image.tmdb.org/t/p/w500${i['file_path']}')
        .toList();
  }

  // ── TV Seasons ──
  Future<List<Season>> getTVSeasons(int tvId) async {
    final data = await _fetchJson('/tv/$tvId');
    return (data['seasons'] as List? ?? [])
        .map((s) => Season.fromJson(s))
        .toList();
  }

  Future<List<Episode>> getSeasonEpisodes(int tvId, int seasonNumber) async {
    final data = await _fetchJson('/tv/$tvId/season/$seasonNumber');
    return (data['episodes'] as List? ?? [])
        .map((e) => Episode.fromJson(e))
        .toList();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, {DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  bool get isValid => DateTime.now().difference(timestamp).inHours < 6;
}
