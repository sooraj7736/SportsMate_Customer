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

  Future<void> joinGame(String gameId, List<Map<String, dynamic>> newParticipants) async {
    try {
      await _firestore.collection('Games').doc(gameId).update({
        'joinedPlayers': FieldValue.arrayUnion(newParticipants),
      });
    } catch (error) {
      rethrow;
    }
  }

  // Listens to ALL games added by different users sorted by date
  Stream<List<GameEntity>> watchAllGames() {
    return _firestore
        .collection('Games')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          final games = snapshot.docs
              .map((doc) => GameEntity.fromMap(doc.data(), doc.id))
              .toList();

          final now = DateTime.now();

          games.sort((a, b) {
            final aDateTime = _gameDateTime(a);
            final bDateTime = _gameDateTime(b);
            final aIsUpcoming = !aDateTime.isBefore(now);
            final bIsUpcoming = !bDateTime.isBefore(now);

            if (aIsUpcoming != bIsUpcoming) {
              return aIsUpcoming ? -1 : 1;
            }

            if (aIsUpcoming) {
              return aDateTime.compareTo(bDateTime);
            }

            return bDateTime.compareTo(aDateTime);
          });

          return games;
        });
  }

  DateTime _gameDateTime(GameEntity game) {
    final parts = game.startTime.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(game.date.year, game.date.month, game.date.day, hour, minute);
  }
}