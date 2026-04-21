import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history.dart';

class HistoryService extends ChangeNotifier {
  static final HistoryService instance = HistoryService._();
  HistoryService._();

  static const _key = 'watch_history_v1';
  static const _maxItems = 20;

  List<HistoryItem> _items = [];
  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _items = raw
        .map((s) {
          try {
            return HistoryItem.fromJson(json.decode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<HistoryItem>()
        .toList();

    // Sort by timestamp descending
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _items.take(_maxItems).map((i) => json.encode(i.toJson())).toList(),
    );
    notifyListeners();
  }

  Future<void> record({
    required int id,
    required String title,
    String? posterPath,
    required String mediaType,
    int? season,
    int? episode,
    double progress = 0.0,
  }) async {
    // Remove if already exists with same ID and mediaType
    _items.removeWhere((i) => i.id == id && i.mediaType == mediaType);

    // Add to top
    _items.insert(
      0,
      HistoryItem(
        id: id,
        title: title,
        posterPath: posterPath,
        mediaType: mediaType,
        season: season,
        episode: episode,
        progress: progress,
        timestamp: DateTime.now(),
      ),
    );

    // Limit size
    if (_items.length > _maxItems) {
      _items = _items.sublist(0, _maxItems);
    }

    await _save();
  }

  Future<void> clearHistory() async {
    _items.clear();
    await _save();
  }
}
