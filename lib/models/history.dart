class HistoryItem {
  final int id;
  final String title;
  final String? posterPath;
  final String mediaType; // 'movie', 'tv', 'anime'
  final int? season;
  final int? episode;
  final double progress; // 0.0 to 1.0
  final DateTime timestamp;

  HistoryItem({
    required this.id,
    required this.title,
    this.posterPath,
    required this.mediaType,
    this.season,
    this.episode,
    this.progress = 0.0,
    required this.timestamp,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      mediaType: json['media_type'],
      season: json['season'],
      episode: json['episode'],
      progress: (json['progress'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster_path': posterPath,
        'media_type': mediaType,
        'season': season,
        'episode': episode,
        'progress': progress,
        'timestamp': timestamp.toIso8601String(),
      };
}
