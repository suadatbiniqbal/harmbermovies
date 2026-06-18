class SportsMatch {
  final String id;
  final String title;
  final String team1Name;
  final String team2Name;
  final String team1LogoUrl;
  final String team2LogoUrl;
  final String heroImageUrl;
  final String leagueName;
  final String leagueLogoUrl;
  final String server1Url;
  final String server2Url;
  final DateTime matchTime;       // UTC — actual kick-off time (displayed in IST)
  final DateTime? streamOpenTime; // UTC — when the player unlocks (admin-set). If null, always open.
  final String status;            // 'upcoming' | 'live' | 'finished'
  final int order;

  const SportsMatch({
    required this.id,
    required this.title,
    required this.team1Name,
    required this.team2Name,
    required this.team1LogoUrl,
    required this.team2LogoUrl,
    required this.heroImageUrl,
    required this.leagueName,
    required this.leagueLogoUrl,
    required this.server1Url,
    required this.server2Url,
    required this.matchTime,
    this.streamOpenTime,
    required this.status,
    this.order = 0,
  });

  factory SportsMatch.fromMap(String id, Map<dynamic, dynamic> map) {
    return SportsMatch(
      id: id,
      title: map['title'] as String? ?? 'Match',
      team1Name: map['team1Name'] as String? ?? 'Team 1',
      team2Name: map['team2Name'] as String? ?? 'Team 2',
      team1LogoUrl: map['team1LogoUrl'] as String? ?? '',
      team2LogoUrl: map['team2LogoUrl'] as String? ?? '',
      heroImageUrl: map['heroImageUrl'] as String? ?? '',
      leagueName: map['leagueName'] as String? ?? '',
      leagueLogoUrl: map['leagueLogoUrl'] as String? ?? '',
      server1Url: map['server1Url'] as String? ?? '',
      server2Url: map['server2Url'] as String? ?? '',
      matchTime: DateTime.tryParse(map['matchTime'] as String? ?? '') ??
          DateTime.now().toUtc(),
      streamOpenTime:
          DateTime.tryParse(map['streamOpenTime'] as String? ?? ''),
      status: map['status'] as String? ?? 'upcoming',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'team1Name': team1Name,
        'team2Name': team2Name,
        'team1LogoUrl': team1LogoUrl,
        'team2LogoUrl': team2LogoUrl,
        'heroImageUrl': heroImageUrl,
        'leagueName': leagueName,
        'leagueLogoUrl': leagueLogoUrl,
        'server1Url': server1Url,
        'server2Url': server2Url,
        'matchTime': matchTime.toUtc().toIso8601String(),
        if (streamOpenTime != null)
          'streamOpenTime': streamOpenTime!.toUtc().toIso8601String(),
        'status': status,
        'order': order,
      };

  /// Returns match time in IST (UTC+5:30)
  DateTime get matchTimeIST =>
      matchTime.toUtc().add(const Duration(hours: 5, minutes: 30));

  /// Whether the player should be accessible right now
  bool get isStreamOpen {
    if (streamOpenTime == null) return true; // no lock set → always open
    return DateTime.now().toUtc().isAfter(streamOpenTime!);
  }

  /// Remaining duration until the stream unlocks (null if already open)
  Duration? get timeUntilStreamOpen {
    if (isStreamOpen) return null;
    return streamOpenTime!.difference(DateTime.now().toUtc());
  }

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isFinished => status == 'finished';
}

