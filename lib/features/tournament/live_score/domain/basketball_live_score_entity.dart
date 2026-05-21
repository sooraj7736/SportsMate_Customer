import 'package:cloud_firestore/cloud_firestore.dart';

class BasketballLiveScoreEntity {
  final String tournamentId;
  final String hostTeamName;
  final String guestTeamName;
  final int hostTeamScore;
  final int guestTeamScore;
  final int hostTeamFouls;
  final int guestTeamFouls;
  final int currentQuarter; // 1, 2, 3, 4, or 5+ for Overtime
  final String matchStatus; // 'Not Started', 'Active', 'Quarter Break', 'Finished'
  final List<String> foulEvents; // Incident history e.g., ["Q1 08:45 • Home • 3 Pointer by Player X"]
  final String updatedByUid;
  final String updatedByName;
  final DateTime updatedAt;
  final DateTime? timerStartedAt;
  final int timerAccumulatedSeconds;
  final bool isTimerRunning;
  final String? note;

  const BasketballLiveScoreEntity({
    required this.tournamentId,
    required this.hostTeamName,
    required this.guestTeamName,
    required this.hostTeamScore,
    required this.guestTeamScore,
    required this.hostTeamFouls,
    required this.guestTeamFouls,
    required this.currentQuarter,
    required this.matchStatus,
    required this.updatedByUid,
    required this.updatedByName,
    required this.updatedAt,
    this.foulEvents = const [],
    this.timerStartedAt,
    this.timerAccumulatedSeconds = 0,
    this.isTimerRunning = false,
    this.note,
  });

  factory BasketballLiveScoreEntity.fromMap(Map<String, dynamic> map, String tournamentId) {
    return BasketballLiveScoreEntity(
      tournamentId: tournamentId,
      hostTeamName: map['hostTeamName'] ?? '',
      guestTeamName: map['guestTeamName'] ?? '',
      hostTeamScore: map['hostTeamScore']?.toInt() ?? 0,
      guestTeamScore: map['guestTeamScore']?.toInt() ?? 0,
      hostTeamFouls: map['hostTeamFouls']?.toInt() ?? 0,
      guestTeamFouls: map['guestTeamFouls']?.toInt() ?? 0,
      currentQuarter: map['currentQuarter']?.toInt() ?? 1,
      matchStatus: map['matchStatus'] ?? 'Not Started',
      foulEvents: (map['foulEvents'] as List<dynamic>?)?.map((event) => event.toString()).toList() ?? const [],
      updatedByUid: map['updatedByUid'] ?? '',
      updatedByName: map['updatedByName'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timerStartedAt: (map['timerStartedAt'] as Timestamp?)?.toDate(),
      timerAccumulatedSeconds: map['timerAccumulatedSeconds']?.toInt() ?? 0,
      isTimerRunning: map['isTimerRunning'] ?? false,
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'hostTeamName': hostTeamName,
      'guestTeamName': guestTeamName,
      'hostTeamScore': hostTeamScore,
      'guestTeamScore': guestTeamScore,
      'hostTeamFouls': hostTeamFouls,
      'guestTeamFouls': guestTeamFouls,
      'currentQuarter': currentQuarter,
      'matchStatus': matchStatus,
      'foulEvents': foulEvents,
      'updatedByUid': updatedByUid,
      'updatedByName': updatedByName,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'timerStartedAt': timerStartedAt != null ? Timestamp.fromDate(timerStartedAt!) : null,
      'timerAccumulatedSeconds': timerAccumulatedSeconds,
      'isTimerRunning': isTimerRunning,
      'note': note,
    };
  }
}
