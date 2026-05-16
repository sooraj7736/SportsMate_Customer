import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddGameState {
  final String sportType;
  final String locationName;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
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
    this.startTime = const TimeOfDay(hour: 18, minute: 0),
    this.endTime = const TimeOfDay(hour: 19, minute: 0),
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
    TimeOfDay? startTime,
    TimeOfDay? endTime,
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
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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
  void updateStartTime(TimeOfDay start) {
    final startMins = _toMinutes(start);
    final endMins = _toMinutes(state.endTime);
    final adjustedEnd = endMins <= startMins ? _addMinutes(start, 60) : state.endTime;
    state = state.copyWith(startTime: start, endTime: adjustedEnd);
  }

  void updateEndTime(TimeOfDay end) => state = state.copyWith(endTime: end);

  void updateAccess(String access) => state = state.copyWith(gameAccess: access);
  void toggleSkillMatch() => state = state.copyWith(matchSkillFromProfile: !state.matchSkillFromProfile);
  void togglePaid() => state = state.copyWith(isPaid: !state.isPaid);
  void updatePlayers(int players) => state = state.copyWith(numberOfPlayers: players);
  void toggleCostShared() => state = state.copyWith(isCostShared: !state.isCostShared);
  void toggleEquipment() => state = state.copyWith(bringEquipment: !state.bringEquipment);

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final total = (time.hour * 60 + time.minute + minutes).clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }
}

final addGameControllerProvider = NotifierProvider<AddGameNotifier, AddGameState>(() {
  return AddGameNotifier();
});