import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../domain/athlete_entity.dart';

// Assuming storageProvider exists in common_providers, otherwise use FirebaseStorage.instance
final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  ProfileRepository({required FirebaseFirestore firestore, required FirebaseStorage storage}) 
      : _firestore = firestore, _storage = storage;

  CollectionReference get _users => _firestore.collection('users');

  // Upload image to Firebase Storage and return URL
  Future<String> uploadProfileImage(String uid, File file) async {
    final ref = _storage.ref().child('profilePics').child(uid);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> saveAthleteProfile(Athlete athlete) async {
    return _users.doc(athlete.uid).set(athlete.toMap(), SetOptions(merge: true));
  }

  Future<Athlete?> getAthleteProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) {
      return Athlete.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<Athlete>> getAllAthletes() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((doc) => Athlete.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<bool> isUsernameUnique(String username) async {
    final querySnapshot = await _users.where('username', isEqualTo: username).limit(1).get();
    return querySnapshot.docs.isEmpty;
  }

  Future<List<String>> getUsernameSuggestions(String baseUsername) async {
    List<String> suggestions = [];
    final suffixes = ['_pro', '_athlete', '123', '99', '_sports'];
    for (var suffix in suffixes) {
      String suggested = baseUsername + suffix;
      bool unique = await isUsernameUnique(suggested);
      if (unique) suggestions.add(suggested);
    }
    return suggestions;
  }
}