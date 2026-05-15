import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../domain/tournament_entity.dart';

final tournamentRepositoryProvider = Provider((ref) {
  return TournamentRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

class TournamentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _firebaseStorage;
  
  TournamentRepository(this._firestore, this._firebaseStorage);

  CollectionReference get _tournaments => _firestore.collection('Tournaments');
  CollectionReference get _turfs => _firestore.collection('Turfs'); // Change to Turfs

  Future<List<Map<String, dynamic>>> getAvailableTurfs() async {
    final snapshot = await _turfs.get(); // Removing status clause to make sure turfs are returned
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  Future<void> addTournament(TournamentEntity tournament) async {
    await _tournaments.add(tournament.toMap());
  }

  Future<void> updateTournamentFixtures(String tournamentId, List<Map<String, dynamic>> fixtures) async {
    await _tournaments.doc(tournamentId).update({
      'fixtures': fixtures,
      'isFixtureGenerated': true,
      'status': 'In Progress',
    });
  }

  Future<void> joinTournament(String tournamentId, Map<String, dynamic> teamData) async {
    await _tournaments.doc(tournamentId).update({
      'registeredTeams': FieldValue.arrayUnion([teamData])
    });
  }

  Future<String> uploadPosterImage(String uid, File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _firebaseStorage.ref().child('tournamentPosters').child('${uid}_$timestamp');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Stream<List<TournamentEntity>> watchTournaments() {
    return _tournaments.orderBy('startDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TournamentEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}

final tournamentListStreamProvider = StreamProvider.autoDispose<List<TournamentEntity>>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.watchTournaments();
});
