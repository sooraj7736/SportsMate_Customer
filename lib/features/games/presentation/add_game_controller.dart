import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddGameState {
  final String sportType;
  final String locationName;
  final DateTime selectedDate;
  final String gameAccess;       // 'Public' or 'Private'
  final bool matchSkillFromProfile;
  final bool isPaid;
  final int numberOfPlayers;
  final bool isCostShared;
  final bool bringEquipment;

  AddGameState({
    this.sportType = 'Football',
    this.locationName = '',
    required this.selectedDate,
    this.gameAccess = 'Public',
    this.matchSkillFromProfile = false,
    this.isPaid = false,
    this.numberOfPlayers = 10,
    this.isCostShared = false,
    this.bringEquipment = false,
  });

  AddGameState copyWith({
    String? sportType,
    String? locationName,
    DateTime? selectedDate,
    String? gameAccess,
    bool? matchSkillFromProfile,
    bool? isPaid,
    int? numberOfPlayers,
    bool? isCostShared,
    bool? bringEquipment,
  }) {
    return AddGameState(
      sportType: sportType ?? this.sportType,
      locationName: locationName ?? this.locationName,
      selectedDate: selectedDate ?? this.selectedDate,
      gameAccess: gameAccess ?? this.gameAccess,
      matchSkillFromProfile: matchSkillFromProfile ?? this.matchSkillFromProfile,
      isPaid: isPaid ?? this.isPaid,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      isCostShared: isCostShared ?? this.isCostShared,
      bringEquipment: bringEquipment ?? this.bringEquipment,
    );
  }
}

class AddGameNotifier extends Notifier<AddGameState> {
  @override
  AddGameState build() {
    return AddGameState(selectedDate: DateTime.now());
  }

  void updateSport(String sport) => state = state.copyWith(sportType: sport);
  void updateLocation(String location) => state = state.copyWith(locationName: location);
  void updateDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void updateAccess(String access) => state = state.copyWith(gameAccess: access);
  void toggleSkillMatch() => state = state.copyWith(matchSkillFromProfile: !state.matchSkillFromProfile);
  void togglePaid() => state = state.copyWith(isPaid: !state.isPaid);
  void updatePlayers(int players) => state = state.copyWith(numberOfPlayers: players);
  void toggleCostShared() => state = state.copyWith(isCostShared: !state.isCostShared);
  void toggleEquipment() => state = state.copyWith(bringEquipment: !state.bringEquipment);
}

final addGameControllerProvider = NotifierProvider<AddGameNotifier, AddGameState>(() {
  return AddGameNotifier();
});