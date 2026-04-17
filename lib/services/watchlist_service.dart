import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class WatchlistService extends ChangeNotifier {
  static final WatchlistService instance = WatchlistService._();
  WatchlistService._();

  static const _key = 'watchlist_v2';
  List<Movie> _items = [];
  List<Movie> get items => List.unmodifiable(_items);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _items = raw
        .map((s) {
          try {
            return Movie.fromJson(json.decode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<Movie>()
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _items.map((m) => json.encode(m.toJson())).toList(),
    );
    notifyListeners();
  }

  bool isInWatchlist(int id) => _items.any((m) => m.id == id);

  Future<void> toggle(Movie movie) async {
    if (isInWatchlist(movie.id)) {
      _items.removeWhere((m) => m.id == movie.id);
    } else {
      _items.insert(0, movie);
    }
    await _save();
  }
}
