import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/common_providers.dart';
import '../domain/cricket_live_score_entity.dart';

final cricketLiveScoreRepositoryProvider = Provider((ref) {
  return CricketLiveScoreRepository(ref.watch(firestoreProvider));
});

final cricketLiveScoreStreamProvider = StreamProvider.autoDispose.family<CricketLiveScoreEntity?, String>((ref, tournamentId) {
  return ref.watch(cricketLiveScoreRepositoryProvider).watchLiveScore(tournamentId);
});

class CricketLiveScoreRepository {
  final FirebaseFirestore _firestore;

  CricketLiveScoreRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _doc(String tournamentId) {
    return _firestore
        .collection('Tournaments')
        .doc(tournamentId)
        .collection('live_scores')
        .doc('cricket');
  }

  Future<void> saveLiveScore(CricketLiveScoreEntity score) async {
    await _doc(score.tournamentId).set(score.toMap(), SetOptions(merge: true));
  }

  Stream<CricketLiveScoreEntity?> watchLiveScore(String tournamentId) {
    return _doc(tournamentId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return CricketLiveScoreEntity.fromMap(data, tournamentId);
    });
  }
}
