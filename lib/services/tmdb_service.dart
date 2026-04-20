import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class TmdbService {
  static final TmdbService instance = TmdbService._();
  TmdbService._();

  static const _apiKey = '8265bd1679663a7ea12ac168da84d2e8';

  /// Proxy fallback chain: try each in order until one works.
  /// api.tmdb.org is the official alternate hostname that Jio sometimes doesn't block.
  static const List<String> _baseUrls = [
    'https://api.themoviedb.org/3',
    'https://api.tmdb.org/3',
  ];

  final Map<String, _CacheEntry> _cache = {};
  final _client = http.Client();
  SharedPreferences? _prefs;
  int _workingBaseIndex = 0;

  // ── Cache init ──
  Future<void> _initCache() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _workingBaseIndex = (_prefs!.getInt('tmdb_proxy_idx') ?? 0)
        .clamp(0, _baseUrls.length - 1);

    final stored = _prefs!.getString('tmdb_cache_v3');
    if (stored != null) {
      try {
        final map = json.decode(stored) as Map<String, dynamic>;
        map.forEach((k, v) {
          _cache[k] = _CacheEntry(
            v['data'],
            timestamp: DateTime.parse(v['timestamp']),
          );
        });
      } catch (_) {}
    }
  }

  void _saveCache() {
    if (_prefs == null) return;
    // Prune to 120 entries max (keep freshest)
    if (_cache.length > 120) {
      final sorted = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      for (var i = 0; i < sorted.length - 120; i++) {
        _cache.remove(sorted[i].key);
      }
    }
    final map = _cache.map((k, v) => MapEntry(k, {
          'data': v.data,
          'timestamp': v.timestamp.toIso8601String(),
        }));
    _prefs!.setString('tmdb_cache_v3', json.encode(map));
  }

  // ── Core HTTP with proxy fallback ──
  Future<http.Response?> _get(String path, Map<String, String> params) async {
    await _initCache();
    final queryParams = {'api_key': _apiKey, ...params};

    // Build a priority list starting with last known working proxy
    final indices = List<int>.generate(_baseUrls.length, (i) => i);
    if (_workingBaseIndex != 0) {
      indices.remove(_workingBaseIndex);
      indices.insert(0, _workingBaseIndex);
    }

    for (final idx in indices) {
      try {
        final uri = Uri.parse('${_baseUrls[idx]}$path')
            .replace(queryParameters: queryParams);
        final res = await _client
            .get(uri)
            .timeout(const Duration(seconds: 13));

        if (res.statusCode == 200) {
          if (idx != _workingBaseIndex) {
            _workingBaseIndex = idx;
            _prefs?.setInt('tmdb_proxy_idx', idx);
          }
          return res;
        }
        if (res.statusCode == 429) {
          await Future.delayed(Duration(milliseconds: 700 * (idx + 1)));
          continue;
        }
      } catch (_) {
        // Try next proxy
      }
    }
    return null;
  }

  // ── Fetch helpers ──
  Future<List<Movie>> _fetchList(String path,
      {Map<String, String>? params}) async {
    await _initCache();
    final cacheKey = 'list_$path${params?.toString() ?? ""}';

    // Serve fresh cache immediately
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _parseMovieList(_cache[cacheKey]!.data);
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      final res = await _get(path, params ?? {});
      if (res != null) {
        final data = json.decode(res.body);
        final results = data['results'] as List? ?? [];
        _cache[cacheKey] = _CacheEntry(results);
        _saveCache();
        return _parseMovieList(results);
      }
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 600));
    }

    // Return stale cache rather than empty list (works offline)
    if (_cache.containsKey(cacheKey)) {
      return _parseMovieList(_cache[cacheKey]!.data);
    }
    return [];
  }

  Future<Map<String, dynamic>> _fetchJson(String path,
      {Map<String, String>? params}) async {
    await _initCache();
    final cacheKey = 'json_$path${params?.toString() ?? ""}';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return Map<String, dynamic>.from(_cache[cacheKey]!.data);
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      final res = await _get(path, params ?? {});
      if (res != null) {
        final data = json.decode(res.body);
        _cache[cacheKey] = _CacheEntry(data);
        _saveCache();
        return data;
      }
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 600));
    }

    // Return stale cache
    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]!.data);
    }
    return {};
  }

  List<Movie> _parseMovieList(dynamic raw) {
    return (raw as List)
        .where((j) => j['media_type'] != 'person')
        .map((j) => Movie.fromJson(j))
        .toList();
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
    await _initCache();
    final cacheKey = 'search_multi_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isSearchValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Movie.fromJson(j))
          .toList();
    }
    final res = await _get('/search/multi', {'query': query});
    if (res != null) {
      final data = json.decode(res.body);
      final raw = data['results'] as List? ?? [];
      _cache[cacheKey] = _CacheEntry(raw);
      _saveCache();
      return raw.map((j) => Movie.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<Movie>> searchMovies(String query) async {
    await _initCache();
    final cacheKey = 'search_movie_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isSearchValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Movie.fromJson(j))
          .toList();
    }
    final res = await _get('/search/movie', {'query': query});
    if (res != null) {
      final data = json.decode(res.body);
      final raw = data['results'] as List? ?? [];
      _cache[cacheKey] = _CacheEntry(raw);
      return raw.map((j) => Movie.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<Movie>> searchTV(String query) async {
    await _initCache();
    final cacheKey = 'search_tv_$query';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isSearchValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Movie.fromJson(j))
          .toList();
    }
    final res = await _get('/search/tv', {'query': query});
    if (res != null) {
      final data = json.decode(res.body);
      final raw = data['results'] as List? ?? [];
      _cache[cacheKey] = _CacheEntry(raw);
      return raw.map((j) => Movie.fromJson(j)).toList();
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

  Future<List<Movie>> getMoviesByGenre(int genreId) => _fetchList(
        '/discover/movie',
        params: {'with_genres': '$genreId', 'sort_by': 'popularity.desc'},
      );

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

  _CacheEntry(this.data, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  // 24 hours for regular content (enables offline use)
  bool get isValid => DateTime.now().difference(timestamp).inHours < 24;

  // 30 minutes for search results
  bool get isSearchValid =>
      DateTime.now().difference(timestamp).inMinutes < 30;
}
