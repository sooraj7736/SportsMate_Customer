import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentEntity {
  final String id;
  final String hostUid;
  final String hostName;
  final String sport;
  final String tournamentName;
  final String description;
  final String posterUrl;
  final int maxTeams;
  final List<Map<String, dynamic>> registeredTeams;
  final List<Map<String, dynamic>> fixtures;
  final bool isFixtureGenerated;
  final String ageRestriction;
  final double registrationFee;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? turfId;
  final String? customAddress;
  final double? lat;
  final double? lng;
  final bool isVerifiedTurf;
  final String prizePool;
  final String rules;
  final String contactPhone;
  final bool isBoosted;
  final String status;
  final int minPlayersPerTeam;

  TournamentEntity({
    required this.id,
    required this.hostUid,
    required this.hostName,
    required this.sport,
    required this.tournamentName,
    required this.description,
    required this.posterUrl,
    required this.maxTeams,
    required this.registeredTeams,
    this.fixtures = const [],
    this.isFixtureGenerated = false,
    required this.ageRestriction,
    required this.registrationFee,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.turfId,
    this.customAddress,
    this.lat,
    this.lng,
    this.isVerifiedTurf = false,
    this.prizePool = '',
    this.rules = '',
    this.contactPhone = '',
    this.isBoosted = false,
    this.status = 'Open',
    this.minPlayersPerTeam = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'hostUid': hostUid,
      'hostName': hostName,
      'sport': sport,
      'tournamentName': tournamentName,
      'description': description,
      'posterUrl': posterUrl,
      'maxTeams': maxTeams,
      'registeredTeams': registeredTeams,
      'fixtures': fixtures,
      'isFixtureGenerated': isFixtureGenerated,
      'ageRestriction': ageRestriction,
      'registrationFee': registrationFee,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'turfId': turfId,
      'customAddress': customAddress,
      'lat': lat,
      'lng': lng,
      'isVerifiedTurf': isVerifiedTurf,
      'prizePool': prizePool,
      'rules': rules,
      'contactPhone': contactPhone,
      'isBoosted': isBoosted,
      'status': status,
      'minPlayersPerTeam': minPlayersPerTeam,
    };
  }

  factory TournamentEntity.fromMap(Map<String, dynamic> map, String documentId) {
    return TournamentEntity(
      id: documentId,
      hostUid: map['hostUid'] ?? '',
      hostName: map['hostName'] ?? '',
      sport: map['sport'] ?? '',
      tournamentName: map['tournamentName'] ?? '',
      description: map['description'] ?? '',
      posterUrl: map['posterUrl'] ?? '',
      maxTeams: map['maxTeams']?.toInt() ?? 0,
      registeredTeams: List<Map<String, dynamic>>.from(map['registeredTeams'] ?? []),
      fixtures: List<Map<String, dynamic>>.from(map['fixtures'] ?? []),
      isFixtureGenerated: map['isFixtureGenerated'] ?? false,
      ageRestriction: map['ageRestriction'] ?? '',
      registrationFee: map['registrationFee']?.toDouble() ?? 0.0,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] ?? '',
      turfId: map['turfId'],
      customAddress: map['customAddress'],
      lat: map['lat']?.toDouble(),
      lng: map['lng']?.toDouble(),
      isVerifiedTurf: map['isVerifiedTurf'] ?? false,
      prizePool: map['prizePool'] ?? '',
      rules: map['rules'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      isBoosted: map['isBoosted'] ?? false,
      status: map['status'] ?? 'Open',
      minPlayersPerTeam: map['minPlayersPerTeam']?.toInt() ?? 5,
    );
  }
}
