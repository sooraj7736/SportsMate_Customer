import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../domain/AddFeed_entity.dart';

final addFeedRepositoryProvider = Provider((ref) {
  return AddFeedRepository(
    ref.watch(firestoreProvider),
  );
});

class AddFeedRepository {
  final FirebaseFirestore _firestore;

  AddFeedRepository(this._firestore);

  CollectionReference get _feeds => _firestore.collection('Feeds');

  Future<void> addFeed(FeedEntity feed) async {
    await _feeds.add(feed.toMap());
  }
}
