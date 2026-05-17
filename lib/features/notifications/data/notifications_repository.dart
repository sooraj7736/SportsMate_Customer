import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/core/providers/common_providers.dart';
import '../domain/notification_entity.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(firestoreProvider));
});

class NotificationsRepository {
  final FirebaseFirestore _firestore;

  NotificationsRepository(this._firestore);

  CollectionReference get _notifications => _firestore.collection('Notifications');

  Future<void> sendNotification(NotificationEntity notification) async {
    await _notifications.add(notification.toMap());
  }

  Stream<List<NotificationEntity>> watchMyNotifications(String userId) {
    return _notifications
        .where('targetUserId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }
}
