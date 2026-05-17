import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/athlete_entity.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(firestoreProvider));
});

class FriendsRepository {
  final FirebaseFirestore _firestore;
  FriendsRepository(this._firestore);

  // Send a friend request
  Future<void> sendFriendRequest({
    required Athlete sender,
    required Athlete receiver,
  }) async {
    final docId = '${sender.uid}_${receiver.uid}';
    await _firestore.collection('friend_requests').doc(docId).set({
      'senderId': sender.uid,
      'senderName': sender.name,
      'senderUsername': sender.username,
      'senderProfilePic': sender.profilePic ?? '',
      'receiverId': receiver.uid,
      'receiverName': receiver.name,
      'receiverUsername': receiver.username,
      'receiverProfilePic': receiver.profilePic ?? '',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Accept a friend request
  Future<void> acceptFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final requestId = '${senderId}_${receiverId}';
    
    final userIds = [senderId, receiverId];
    userIds.sort();
    final friendshipId = userIds.join('_');

    final batch = _firestore.batch();
    
    // 1. Create a friendship document
    final friendshipRef = _firestore.collection('friendships').doc(friendshipId);
    batch.set(friendshipRef, {
      'userIds': userIds,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Delete the friend request
    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    batch.delete(requestRef);

    await batch.commit();
  }

  // Decline/Cancel a friend request
  Future<void> declineFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final requestId = '${senderId}_${receiverId}';
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  // Unfriend someone
  Future<void> unfriend({
    required String uid1,
    required String uid2,
  }) async {
    final userIds = [uid1, uid2];
    userIds.sort();
    final friendshipId = userIds.join('_');
    await _firestore.collection('friendships').doc(friendshipId).delete();
  }

  // Stream of incoming friend requests
  Stream<List<Map<String, dynamic>>> watchIncomingRequests(String receiverId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Stream of outgoing friend requests
  Stream<List<Map<String, dynamic>>> watchSentRequests(String senderId) {
    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Stream of friendships
  Stream<List<Map<String, dynamic>>> watchFriendships(String uid) {
    return _firestore
        .collection('friendships')
        .where('userIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

// Stream of incoming friend requests
final incomingRequestsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  
  final friendsRepo = ref.watch(friendsRepositoryProvider);
  return friendsRepo.watchIncomingRequests(user.uid);
});

// Stream of outgoing friend requests
final sentRequestsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  
  final friendsRepo = ref.watch(friendsRepositoryProvider);
  return friendsRepo.watchSentRequests(user.uid);
});

// Stream of actual Athlete profiles of friends, ordered by friendship date (latest first)
final friendsStreamProvider = StreamProvider<List<Athlete>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  
  final friendsRepo = ref.watch(friendsRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);

  return friendsRepo.watchFriendships(user.uid).asyncMap((friendshipDocs) async {
    // Sort friendships by timestamp descending (latest first)
    friendshipDocs.sort((a, b) {
      final t1 = a['timestamp'] as Timestamp?;
      final t2 = b['timestamp'] as Timestamp?;
      if (t1 == null && t2 == null) return 0;
      if (t1 == null) return -1;
      if (t2 == null) return 1;
      return t2.compareTo(t1);
    });

    final friends = <Athlete>[];
    for (var doc in friendshipDocs) {
      final userIds = List<String>.from(doc['userIds']);
      final friendUid = userIds.firstWhere((id) => id != user.uid);
      final profile = await profileRepo.getAthleteProfile(friendUid);
      if (profile != null) {
        friends.add(profile);
      }
    }
    return friends;
  });
});

enum FriendshipStatus { none, pendingSent, pendingReceived, friends }

// Family provider to dynamically check friendship status between the logged-in user and another user
final friendshipStatusProvider = Provider.family<FriendshipStatus, String>((ref, otherUid) {
  final friendshipsAsync = ref.watch(friendsStreamProvider);
  final incomingAsync = ref.watch(incomingRequestsStreamProvider);
  final sentAsync = ref.watch(sentRequestsStreamProvider);

  final friendships = friendshipsAsync.value ?? [];
  final incoming = incomingAsync.value ?? [];
  final sent = sentAsync.value ?? [];

  final isFriend = friendships.any((f) => f.uid == otherUid);
  if (isFriend) return FriendshipStatus.friends;

  final isIncomingPending = incoming.any((r) => r['senderId'] == otherUid);
  if (isIncomingPending) return FriendshipStatus.pendingReceived;

  final isSentPending = sent.any((r) => r['receiverId'] == otherUid);
  if (isSentPending) return FriendshipStatus.pendingSent;

  return FriendshipStatus.none;
});
