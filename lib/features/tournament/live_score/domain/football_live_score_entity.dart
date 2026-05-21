import 'package:cloud_firestore/cloud_firestore.dart';

class FootballLiveScoreEntity {
  final String tournamentId;
  final String hostTeamName;
  final String guestTeamName;
  final int hostTeamScore;
  final int guestTeamScore;
  final String matchStatus;
  final int? minute;
  final String? note;
  final List<String> foulEvents;
  final String updatedByUid;
  final String updatedByName;
  final DateTime updatedAt;
  final DateTime? timerStartedAt;
  final int timerAccumulatedSeconds;
  final bool isTimerRunning;

  const FootballLiveScoreEntity({
    required this.tournamentId,
    required this.hostTeamName,
    required this.guestTeamName,
    required this.hostTeamScore,
    required this.guestTeamScore,
    required this.matchStatus,
    required this.updatedByUid,
    required this.updatedByName,
    required this.updatedAt,
    this.minute,
    this.note,
    this.foulEvents = const [],
    this.timerStartedAt,
    this.timerAccumulatedSeconds = 0,
    this.isTimerRunning = false,
  });

  factory FootballLiveScoreEntity.fromMap(Map<String, dynamic> map, String tournamentId) {
    return FootballLiveScoreEntity(
      tournamentId: tournamentId,
      hostTeamName: map['hostTeamName'] ?? '',
      guestTeamName: map['guestTeamName'] ?? '',
      hostTeamScore: map['hostTeamScore']?.toInt() ?? 0,
      guestTeamScore: map['guestTeamScore']?.toInt() ?? 0,
      matchStatus: map['matchStatus'] ?? 'Not Started',
      minute: map['minute']?.toInt(),
      note: map['note'],
      foulEvents: (map['foulEvents'] as List<dynamic>?)?.map((event) => event.toString()).toList() ?? const [],
      updatedByUid: map['updatedByUid'] ?? '',
      updatedByName: map['updatedByName'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timerStartedAt: (map['timerStartedAt'] as Timestamp?)?.toDate(),
      timerAccumulatedSeconds: map['timerAccumulatedSeconds']?.toInt() ?? ((map['minute']?.toInt() ?? 0) * 60),
      isTimerRunning: map['isTimerRunning'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'hostTeamName': hostTeamName,
      'guestTeamName': guestTeamName,
      'hostTeamScore': hostTeamScore,
      'guestTeamScore': guestTeamScore,
      'matchStatus': matchStatus,
      'minute': minute,
      'note': note,
      'foulEvents': foulEvents,
      'updatedByUid': updatedByUid,
      'updatedByName': updatedByName,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'timerStartedAt': timerStartedAt != null ? Timestamp.fromDate(timerStartedAt!) : null,
      'timerAccumulatedSeconds': timerAccumulatedSeconds,
      'isTimerRunning': isTimerRunning,
    };
  }
}