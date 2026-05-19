import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/common_providers.dart';
import '../domain/football_live_score_entity.dart';

final footballLiveScoreRepositoryProvider = Provider((ref) {
  return FootballLiveScoreRepository(ref.watch(firestoreProvider));
});

final footballLiveScoreStreamProvider = StreamProvider.autoDispose.family<FootballLiveScoreEntity?, String>((ref, tournamentId) {
  return ref.watch(footballLiveScoreRepositoryProvider).watchLiveScore(tournamentId);
});

class FootballLiveScoreRepository {
  final FirebaseFirestore _firestore;

  FootballLiveScoreRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _doc(String tournamentId) {
    return _firestore
        .collection('Tournaments')
        .doc(tournamentId)
        .collection('live_scores')
        .doc('football');
  }

  Future<void> saveLiveScore(FootballLiveScoreEntity score) async {
    await _doc(score.tournamentId).set(score.toMap(), SetOptions(merge: true));
  }

  Stream<FootballLiveScoreEntity?> watchLiveScore(String tournamentId) {
    return _doc(tournamentId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return FootballLiveScoreEntity.fromMap(data, tournamentId);
    });
  }
}