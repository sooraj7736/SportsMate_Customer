import 'package:cloud_firestore/cloud_firestore.dart';

class GameEntity {
  final String id;
  final String hostId;
  final String hostName;
  final String sportType;
  final String locationName;
  final DateTime date;
  final String gameAccess;       // 'Public' or 'Private'
  final bool matchSkillFromProfile; // true/false
  final bool isPaid;             // true/false
  final int numberOfPlayers;
  final bool isCostShared;       // true/false
  final bool bringEquipment;     // true/false

  GameEntity({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.sportType,
    required this.locationName,
    required this.date,
    required this.gameAccess,
    required this.matchSkillFromProfile,
    required this.isPaid,
    required this.numberOfPlayers,
    required this.isCostShared,
    required this.bringEquipment,
  });

  factory GameEntity.fromMap(Map<String, dynamic> map, String documentId) {
    return GameEntity(
      id: documentId,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      sportType: map['sportType'] ?? '',
      locationName: map['locationName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      gameAccess: map['gameAccess'] ?? 'Public',
      matchSkillFromProfile: map['matchSkillFromProfile'] ?? false,
      isPaid: map['isPaid'] ?? false,
      numberOfPlayers: map['numberOfPlayers'] ?? 10,
      isCostShared: map['isCostShared'] ?? false,
      bringEquipment: map['bringEquipment'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'sportType': sportType,
      'locationName': locationName,
      'date': Timestamp.fromDate(date),
      'gameAccess': gameAccess,
      'matchSkillFromProfile': matchSkillFromProfile,
      'isPaid': isPaid,
      'numberOfPlayers': numberOfPlayers,
      'isCostShared': isCostShared,
      'bringEquipment': bringEquipment,
    };
  }
}