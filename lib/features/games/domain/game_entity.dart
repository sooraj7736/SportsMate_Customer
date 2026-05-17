import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  final String uid;
  final String name;
  final bool isGuest;

  const Participant({
    required this.uid,
    required this.name,
    required this.isGuest,
  });

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      isGuest: map['isGuest'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'isGuest': isGuest,
    };
  }
}

class GameEntity {
  final String id;
  final String hostId;
  final String hostName;
  final String sportType;
  final String locationName;
  final DateTime date;
  final String startTime;        // 24h format: HH:mm
  final String endTime;          // 24h format: HH:mm
  final String gameAccess;       // 'Public' or 'Private'
  final bool matchSkillFromProfile; // true/false
  final bool isPaid;             // true/false
  final int numberOfPlayers;
  final bool isCostShared;       // true/false
  final bool bringEquipment;     // true/false
  final List<Participant> joinedPlayers;
  final String? turfId;
  final bool isVerifiedTurf;
  final double? lat;
  final double? lng;
  final String? customAddress;

  GameEntity({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.sportType,
    required this.locationName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.gameAccess,
    required this.matchSkillFromProfile,
    required this.isPaid,
    required this.numberOfPlayers,
    required this.isCostShared,
    required this.bringEquipment,
    this.joinedPlayers = const [],
    this.turfId,
    this.isVerifiedTurf = false,
    this.lat,
    this.lng,
    this.customAddress,
  });

  int get maxPlayers => numberOfPlayers;

  factory GameEntity.fromMap(Map<String, dynamic> map, String documentId) {
    final joinedPlayersData = map['joinedPlayers'];
    final joinedPlayers = joinedPlayersData is List
        ? joinedPlayersData
        .whereType<Map>()
        .map((item) => Participant.fromMap(Map<String, dynamic>.from(item)))
            .toList()
        : const <Participant>[];

    return GameEntity(
      id: documentId,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      sportType: map['sportType'] ?? '',
      locationName: map['locationName'] ?? '',
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      gameAccess: map['gameAccess'] ?? 'Public',
      matchSkillFromProfile: map['matchSkillFromProfile'] ?? false,
      isPaid: map['isPaid'] ?? false,
      numberOfPlayers: map['numberOfPlayers'] ?? 10,
      isCostShared: map['isCostShared'] ?? false,
      bringEquipment: map['bringEquipment'] ?? false,
      joinedPlayers: joinedPlayers,
      turfId: map['turfId'],
      isVerifiedTurf: map['isVerifiedTurf'] ?? false,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      customAddress: map['customAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'sportType': sportType,
      'locationName': locationName,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'gameAccess': gameAccess,
      'matchSkillFromProfile': matchSkillFromProfile,
      'isPaid': isPaid,
      'numberOfPlayers': numberOfPlayers,
      'isCostShared': isCostShared,
      'bringEquipment': bringEquipment,
      'joinedPlayers': joinedPlayers.map((participant) => participant.toMap()).toList(),
      'turfId': turfId,
      'isVerifiedTurf': isVerifiedTurf,
      'lat': lat,
      'lng': lng,
      'customAddress': customAddress,
    };
  }
}