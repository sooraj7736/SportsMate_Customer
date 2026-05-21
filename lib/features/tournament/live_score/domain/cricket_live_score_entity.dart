import 'package:cloud_firestore/cloud_firestore.dart';

class CricketLiveScoreEntity {
  final String tournamentId;
  final String battingTeamName;
  final String bowlingTeamName;
  final int runs;
  final int wickets;
  final int overs;      // Number of completed overs
  final int balls;      // Number of balls in the current over (0 to 5)
  final String matchStatus; // 'Live', 'Innings Break', 'Finished', etc.
  
  // Batsmen
  final String? batsman1Name;
  final int batsman1Runs;
  final int batsman1Balls;
  final String? batsman2Name;
  final int batsman2Runs;
  final int batsman2Balls;
  final bool batsman1OnStrike;

  // Bowler
  final String? bowlerName;
  final double bowlerOvers;
  final int bowlerMaidens;
  final int bowlerRuns;
  final int bowlerWickets;

  // Extra features
  final List<String> recentBalls; // E.g. ["1", "wd", "4", "W", "0", "6"]
  final List<String> incidents; // Dynamic match incidents / announcements
  final String? note;
  final String updatedByUid;
  final String updatedByName;
  final DateTime updatedAt;

  const CricketLiveScoreEntity({
    required this.tournamentId,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
    required this.matchStatus,
    required this.updatedByUid,
    required this.updatedByName,
    required this.updatedAt,
    this.batsman1Name,
    this.batsman1Runs = 0,
    this.batsman1Balls = 0,
    this.batsman2Name,
    this.batsman2Runs = 0,
    this.batsman2Balls = 0,
    this.batsman1OnStrike = true,
    this.bowlerName,
    this.bowlerOvers = 0.0,
    this.bowlerMaidens = 0,
    this.bowlerRuns = 0,
    this.bowlerWickets = 0,
    this.recentBalls = const [],
    this.incidents = const [],
    this.note,
  });

  factory CricketLiveScoreEntity.fromMap(Map<String, dynamic> map, String tournamentId) {
    return CricketLiveScoreEntity(
      tournamentId: tournamentId,
      battingTeamName: map['battingTeamName'] ?? '',
      bowlingTeamName: map['bowlingTeamName'] ?? '',
      runs: map['runs']?.toInt() ?? 0,
      wickets: map['wickets']?.toInt() ?? 0,
      overs: map['overs']?.toInt() ?? 0,
      balls: map['balls']?.toInt() ?? 0,
      matchStatus: map['matchStatus'] ?? 'Not Started',
      batsman1Name: map['batsman1Name'],
      batsman1Runs: map['batsman1Runs']?.toInt() ?? 0,
      batsman1Balls: map['batsman1Balls']?.toInt() ?? 0,
      batsman2Name: map['batsman2Name'],
      batsman2Runs: map['batsman2Runs']?.toInt() ?? 0,
      batsman2Balls: map['batsman2Balls']?.toInt() ?? 0,
      batsman1OnStrike: map['batsman1OnStrike'] ?? true,
      bowlerName: map['bowlerName'],
      bowlerOvers: map['bowlerOvers']?.toDouble() ?? 0.0,
      bowlerMaidens: map['bowlerMaidens']?.toInt() ?? 0,
      bowlerRuns: map['bowlerRuns']?.toInt() ?? 0,
      bowlerWickets: map['bowlerWickets']?.toInt() ?? 0,
      recentBalls: (map['recentBalls'] as List<dynamic>?)?.map((b) => b.toString()).toList() ?? const [],
      incidents: (map['incidents'] as List<dynamic>?)?.map((i) => i.toString()).toList() ?? const [],
      note: map['note'],
      updatedByUid: map['updatedByUid'] ?? '',
      updatedByName: map['updatedByName'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'battingTeamName': battingTeamName,
      'bowlingTeamName': bowlingTeamName,
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
      'balls': balls,
      'matchStatus': matchStatus,
      'batsman1Name': batsman1Name,
      'batsman1Runs': batsman1Runs,
      'batsman1Balls': batsman1Balls,
      'batsman2Name': batsman2Name,
      'batsman2Runs': batsman2Runs,
      'batsman2Balls': batsman2Balls,
      'batsman1OnStrike': batsman1OnStrike,
      'bowlerName': bowlerName,
      'bowlerOvers': bowlerOvers,
      'bowlerMaidens': bowlerMaidens,
      'bowlerRuns': bowlerRuns,
      'bowlerWickets': bowlerWickets,
      'recentBalls': recentBalls,
      'incidents': incidents,
      'note': note,
      'updatedByUid': updatedByUid,
      'updatedByName': updatedByName,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
