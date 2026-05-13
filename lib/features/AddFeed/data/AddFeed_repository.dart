import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../domain/AddFeed_entity.dart';
import 'package:firebase_storage/firebase_storage.dart';

final addFeedRepositoryProvider = Provider((ref) {
  return AddFeedRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

class AddFeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _firebaseStorage;
  AddFeedRepository(this._firestore,this._firebaseStorage);

  
  CollectionReference get _feeds => _firestore.collection('Feeds');

  Future<void> addFeed(FeedEntity feed) async {
    await _feeds.add(feed.toMap());
  }
  

  

  

  Future<String> uploadFeedImage(String uid, File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _firebaseStorage.ref().child('feedImages').child('$uid\_$timestamp');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
