import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/core/providers/common_providers.dart';
import '../domain/game_entity.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(ref.watch(firestoreProvider));
});

class GamesRepository {
  final FirebaseFirestore _firestore;
  GamesRepository(this._firestore);

  // Pushes form data into a Firestore Collection named "Games"
  Future<void> createGame(GameEntity game) async {
    await _firestore.collection('Games').add(game.toMap());
  }

  // Listens to ALL games added by different users sorted by date
  Stream<List<GameEntity>> watchAllGames() {
    return _firestore
        .collection('Games')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameEntity.fromMap(doc.data(), doc.id))
            .toList());
  }
}