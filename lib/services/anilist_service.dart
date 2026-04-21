import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime.dart';

class AnilistService {
  static final AnilistService instance = AnilistService._();
  AnilistService._();

  /// Multiple AniList endpoints — Jio/Airtel block graphql.anilist.co via DNS/DPI.
  /// We try each in order, starting with the last known-working one.
  static const List<String> _endpoints = [
    'https://graphql.anilist.co',       // Official
    'https://anilist.co/graphql',       // Web path (sometimes unblocked)
    'https://api.anilist.co',           // Alternate official hostname
  ];

  final Map<String, _CacheEntry> _cache = {};
  SharedPreferences? _prefs;
  int _workingEndpointIndex = 0;

  Future<void> _initCache() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _workingEndpointIndex = (_prefs!.getInt('anilist_endpoint_idx') ?? 0)
        .clamp(0, _endpoints.length - 1);

    final stored = _prefs!.getString('anilist_v3_cache');
    if (stored != null) {
      try {
        final map = json.decode(stored) as Map<String, dynamic>;
        map.forEach((k, v) {
          _cache[k] =
              _CacheEntry(v['data'], timestamp: DateTime.parse(v['timestamp']));
        });
      } catch (_) {}
    }
  }

  void _saveCache() {
    if (_prefs == null) return;
    if (_cache.length > 100) {
      final sorted = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      for (var i = 0; i < sorted.length - 100; i++) {
        _cache.remove(sorted[i].key);
      }
    }
    final map = _cache.map((k, v) => MapEntry(k, {
          'data': v.data,
          'timestamp': v.timestamp.toIso8601String(),
        }));
    _prefs!.setString('anilist_v3_cache', json.encode(map));
  }

  /// Posts a GraphQL query with multi-endpoint proxy fallback.
  /// Shorter timeout (8s) per endpoint for faster failover.
  Future<dynamic> _postQuery(String query,
      {Map<String, dynamic>? variables}) async {
    await _initCache();

    // Build priority list starting with last-known working endpoint
    final indices = List<int>.generate(_endpoints.length, (i) => i);
    if (_workingEndpointIndex != 0) {
      indices.remove(_workingEndpointIndex);
      indices.insert(0, _workingEndpointIndex);
    }

    for (final idx in indices) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final res = await http
              .post(
                Uri.parse(_endpoints[idx]),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: json.encode({
                  'query': query,
                  'variables': variables ?? {},
                }),
              )
              .timeout(const Duration(seconds: 8));

          if (res.statusCode == 200) {
            // Remember this working endpoint
            if (idx != _workingEndpointIndex) {
              _workingEndpointIndex = idx;
              _prefs?.setInt('anilist_endpoint_idx', idx);
            }
            final decoded = json.decode(res.body);
            return decoded['data'];
          }

          if (res.statusCode == 429) {
            await Future.delayed(
                Duration(milliseconds: 800 * (attempt + 1) * (idx + 1)));
          }
        } catch (_) {
          if (attempt == 0) {
            await Future.delayed(Duration(milliseconds: 400 * (idx + 1)));
          }
        }
      }
    }
    return null;
  }

  final String _baseAnimeQuery = '''
    id
    title {
      romaji
      english
      native
    }
    coverImage {
      extraLarge
      large
      medium
    }
    bannerImage
    description(asHtml: false)
    episodes
    averageScore
    status
    genres
    format
    season
    seasonYear
  ''';

  Future<List<Anime>> getTrendingAnime() async {
    await _initCache();
    const cacheKey = 'trending';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Anime.fromJson(j))
          .toList();
    }

    final query = '''
      query {
        Page(page: 1, perPage: 20) {
          media(sort: TRENDING_DESC, type: ANIME, isAdult: false) {
            $_baseAnimeQuery
          }
        }
      }
    ''';
    final data = await _postQuery(query);
    if (data == null) {
      if (_cache.containsKey(cacheKey)) {
        return (_cache[cacheKey]!.data as List)
            .map((j) => Anime.fromJson(j))
            .toList();
      }
      return [];
    }

    final results = data['Page']['media'] as List;
    _cache[cacheKey] = _CacheEntry(results);
    _saveCache();
    return results.map((j) => Anime.fromJson(j)).toList();
  }

  Future<List<Anime>> getPopularAnime() async {
    await _initCache();
    const cacheKey = 'popular';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Anime.fromJson(j))
          .toList();
    }

    final query = '''
      query {
        Page(page: 1, perPage: 20) {
          media(sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
            $_baseAnimeQuery
          }
        }
      }
    ''';
    final data = await _postQuery(query);
    if (data == null) {
      if (_cache.containsKey(cacheKey)) {
        return (_cache[cacheKey]!.data as List)
            .map((j) => Anime.fromJson(j))
            .toList();
      }
      return [];
    }

    final results = data['Page']['media'] as List;
    _cache[cacheKey] = _CacheEntry(results);
    _saveCache();
    return results.map((j) => Anime.fromJson(j)).toList();
  }

  Future<List<Anime>> getTopRatedAnime() async {
    await _initCache();
    const cacheKey = 'top_rated';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Anime.fromJson(j))
          .toList();
    }

    final query = '''
      query {
        Page(page: 1, perPage: 20) {
          media(sort: SCORE_DESC, type: ANIME, isAdult: false) {
            $_baseAnimeQuery
          }
        }
      }
    ''';
    final data = await _postQuery(query);
    if (data == null) {
      if (_cache.containsKey(cacheKey)) {
        return (_cache[cacheKey]!.data as List)
            .map((j) => Anime.fromJson(j))
            .toList();
      }
      return [];
    }

    final results = data['Page']['media'] as List;
    _cache[cacheKey] = _CacheEntry(results);
    _saveCache();
    return results.map((j) => Anime.fromJson(j)).toList();
  }

  Future<Anime?> getAnimeDetails(int id) async {
    await _initCache();
    final cacheKey = 'details_$id';

    Anime? cached;
    if (_cache.containsKey(cacheKey)) {
      cached = Anime.fromJson(_cache[cacheKey]!.data);
      if (_cache[cacheKey]!.isValid) return cached;
    }

    final query = '''
      query (\$id: Int) {
        Media(id: \$id, type: ANIME) {
          id
          title {
            romaji
            english
            native
          }
          coverImage {
            extraLarge
            large
            medium
          }
          bannerImage
          description(asHtml: false)
          episodes
          averageScore
          status
          genres
          format
          season
          seasonYear
          streamingEpisodes {
            title
            thumbnail
            url
          }
          relations {
            edges {
              relationType
              node {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
                format
                status
              }
            }
          }
          recommendations(page: 1, perPage: 10) {
            nodes {
              mediaRecommendation {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
                averageScore
              }
            }
          }
          studios(isMain: true) {
            nodes {
              name
            }
          }
          nextAiringEpisode {
            airingAt
            timeUntilAiring
            episode
          }
        }
      }
    ''';
    final data = await _postQuery(query, variables: {'id': id});

    if (data == null || data['Media'] == null) {
      return cached;
    }

    final animeData = data['Media'];
    _cache[cacheKey] = _CacheEntry(animeData);
    _saveCache();
    return Anime.fromJson(animeData);
  }

  Future<List<Anime>> searchAnime(String search) async {
    await _initCache();
    final cacheKey = 'search_$search';
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isSearchValid) {
      return (_cache[cacheKey]!.data as List)
          .map((j) => Anime.fromJson(j))
          .toList();
    }
    final query = '''
      query (\$search: String) {
        Page(page: 1, perPage: 25) {
          media(search: \$search, type: ANIME, isAdult: false) {
            $_baseAnimeQuery
          }
        }
      }
    ''';
    final data = await _postQuery(query, variables: {'search': search});
    if (data == null) return [];
    final results = data['Page']['media'] as List;
    _cache[cacheKey] = _CacheEntry(results);
    _saveCache();
    return results.map((j) => Anime.fromJson(j)).toList();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  // 24 hours for detail/list cache
  bool get isValid => DateTime.now().difference(timestamp).inHours < 24;

  // 30 minutes for search cache
  bool get isSearchValid => DateTime.now().difference(timestamp).inMinutes < 30;
}
