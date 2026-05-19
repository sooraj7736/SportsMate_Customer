import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/common_providers.dart';

class SportOption {
  final String id;
  final String name;
  final String icon;
  final bool active;

  const SportOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.active,
  });

  factory SportOption.fromMap(Map<String, dynamic> map, String id) {
    final name = (map['name'] as String?)?.trim() ?? '';
    return SportOption(
      id: id,
      name: name.isNotEmpty ? name : id,
      icon: map['icon'] ?? '',
      active: map['active'] ?? true,
    );
  }
}

final sportsCatalogProvider = StreamProvider.autoDispose<List<SportOption>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('sports').where('active', isEqualTo: true).snapshots().map((snapshot) {
    final sports = snapshot.docs
        .map((doc) => SportOption.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()));
    return sports;
  });
});

List<String> normalizeSportSelections(List<String> selectedSports, List<SportOption> allowedSports) {
  final trimmedSelections = selectedSports.map((sport) => sport.trim()).where((sport) => sport.isNotEmpty).toList();

  if (allowedSports.isEmpty) {
    return trimmedSelections.toSet().toList();
  }

  final allowedByKey = <String, String>{};
  for (final sport in allowedSports) {
    allowedByKey[_sportKey(sport.id)] = sport.name;
    allowedByKey[_sportKey(sport.name)] = sport.name;
  }

  final normalized = <String>[];
  for (final sport in trimmedSelections) {
    final match = allowedByKey[_sportKey(sport)];
    if (match != null && !normalized.contains(match)) {
      normalized.add(match);
    }
  }

  return normalized;
}

String _sportKey(String value) => value.trim().toLowerCase();