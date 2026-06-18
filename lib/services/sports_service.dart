import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sports_match.dart';

class SportsService {
  SportsService._();
  static final instance = SportsService._();

  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('sports/matches');

  StreamSubscription<DatabaseEvent>? _sub;
  final _controller = StreamController<List<SportsMatch>>.broadcast();

  Stream<List<SportsMatch>> get matchesStream => _controller.stream;

  void startListening() {
    _sub?.cancel();
    _sub = _ref.onValue.listen((event) {
      try {
        final data = event.snapshot.value;
        if (data == null) {
          _controller.add([]);
          return;
        }
        final map = Map<dynamic, dynamic>.from(data as Map);
        final matches = map.entries
            .map((e) =>
                SportsMatch.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        _controller.add(matches);
      } catch (_) {
        _controller.add([]);
      }
    }, onError: (_) => _controller.add([]));
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  Future<List<SportsMatch>> fetchOnce() async {
    try {
      final snap = await _ref.get();
      if (!snap.exists || snap.value == null) return [];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final matches = map.entries
          .map((e) =>
              SportsMatch.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return matches;
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
