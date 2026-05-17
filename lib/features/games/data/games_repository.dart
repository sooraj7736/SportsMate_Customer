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

  Stream<List<GameEntity>> watchGamesHostedByMe(String userId) {
    return _firestore
        .collection('Games')
        .where('hostId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return <GameEntity>[];
          }

          final games = snapshot.docs
              .map((doc) => GameEntity.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort by date on client side
          games.sort((a, b) => a.date.compareTo(b.date));
          return games;
        });
  }

  Stream<List<GameEntity>> watchGamesIHaveJoined(String userId) {
    return _firestore.collection('Games').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <GameEntity>[];
      }

      final games = snapshot.docs
          .map((doc) => GameEntity.fromMap(doc.data(), doc.id))
          .where((game) => game.joinedPlayers.any((player) => player.uid == userId))
          .toList();

      if (games.isEmpty) {
        return <GameEntity>[];
      }

      games.sort((a, b) => a.date.compareTo(b.date));
      return games;
    });
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

  // Send game invitation
  Future<void> sendGameInvitation({
    required String gameId,
    required String hostId,
    required String hostName,
    required String invitedUserId,
    required String sportType,
    required DateTime date,
    required String locationName,
  }) async {
    final docId = '${gameId}_${invitedUserId}';
    await _firestore.collection('game_invitations').doc(docId).set({
      'id': docId,
      'gameId': gameId,
      'sportType': sportType,
      'date': Timestamp.fromDate(date),
      'locationName': locationName,
      'hostId': hostId,
      'hostName': hostName,
      'invitedUserId': invitedUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Accept game invitation
  Future<void> acceptGameInvitation({
    required String invitationId,
    required String gameId,
    required Map<String, dynamic> participantPayload,
  }) async {
    final batch = _firestore.batch();
    
    // 1. Add participant to the game document
    final gameRef = _firestore.collection('Games').doc(gameId);
    batch.update(gameRef, {
      'joinedPlayers': FieldValue.arrayUnion([participantPayload]),
    });

    // 2. Delete the invitation document
    final inviteRef = _firestore.collection('game_invitations').doc(invitationId);
    batch.delete(inviteRef);

    await batch.commit();
  }

  // Decline game invitation
  Future<void> declineGameInvitation({
    required String invitationId,
  }) async {
    await _firestore.collection('game_invitations').doc(invitationId).delete();
  }

  // Stream of incoming game invitations
  Stream<List<Map<String, dynamic>>> watchIncomingGameInvitations(String invitedUserId) {
    return _firestore
        .collection('game_invitations')
        .where('invitedUserId', isEqualTo: invitedUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Stream of sent invitations for a specific game (returns a list of UIDs)
  Stream<List<String>> watchSentInvitationsForGame(String gameId) {
    return _firestore
        .collection('game_invitations')
        .where('gameId', isEqualTo: gameId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()['invitedUserId'] as String).toList());
  }
}

final incomingGameInvitationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  
  final gamesRepo = ref.watch(gamesRepositoryProvider);
  return gamesRepo.watchIncomingGameInvitations(user.uid);
});

final sentInvitationsForGameStreamProvider = StreamProvider.family<List<String>, String>((ref, gameId) {
  final gamesRepo = ref.watch(gamesRepositoryProvider);
  return gamesRepo.watchSentInvitationsForGame(gameId);
});