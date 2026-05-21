import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/common_providers.dart';
import '../domain/basketball_live_score_entity.dart';

final basketballLiveScoreRepositoryProvider = Provider((ref) {
  return BasketballLiveScoreRepository(ref.watch(firestoreProvider));
});

final basketballLiveScoreStreamProvider = StreamProvider.autoDispose.family<BasketballLiveScoreEntity?, String>((ref, tournamentId) {
  return ref.watch(basketballLiveScoreRepositoryProvider).watchLiveScore(tournamentId);
});

class BasketballLiveScoreRepository {
  final FirebaseFirestore _firestore;

  BasketballLiveScoreRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _doc(String tournamentId) {
    return _firestore
        .collection('Tournaments')
        .doc(tournamentId)
        .collection('live_scores')
        .doc('basketball');
  }

  Future<void> saveLiveScore(BasketballLiveScoreEntity score) async {
    await _doc(score.tournamentId).set(score.toMap(), SetOptions(merge: true));
  }

  Stream<BasketballLiveScoreEntity?> watchLiveScore(String tournamentId) {
    return _doc(tournamentId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return BasketballLiveScoreEntity.fromMap(data, tournamentId);
    });
  }
}
