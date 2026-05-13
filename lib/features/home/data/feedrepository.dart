import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../../AddFeed/domain/AddFeed_entity.dart';
import '../domain/comment_entity.dart';
import '../domain/ad_entity.dart';

final feedRepositoryProvider = Provider((ref) {
  return FeedRepository(ref.watch(firestoreProvider));
});

class FeedRepository {
  final FirebaseFirestore _firestore;
  FeedRepository(this._firestore);
  CollectionReference get _feeds => _firestore.collection('Feeds');

  Stream<List<FeedEntity>> watchFeeds() {
    return _feeds.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                FeedEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Stream<List<AdEntity>> watchAds() {
    return _firestore
        .collection('AD')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AdEntity.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> toggleLike(String feedId, String userId) async {
    final doc = await _feeds.doc(feedId).get();
    if (doc.exists) {
      final likes = List<String>.from(
        (doc.data() as Map<String, dynamic>)['likes'] ?? [],
      );
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      await _feeds.doc(feedId).update({'likes': likes});
    }
  }

  // Comments
  Future<void> addComment(String feedId, CommentEntity comment) async {
    await _feeds.doc(feedId).collection('comments').add(comment.toMap());
  }

  Stream<List<CommentEntity>> watchComments(String feedId) {
    return _feeds
        .doc(feedId)
        .collection('comments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommentEntity.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<FeedEntity?> getFeedById(String feedId) async {
    final doc = await _feeds.doc(feedId).get();
    if (doc.exists) {
      return FeedEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
}
