import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationEntity {
  final String id;
  final String targetUserId;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;

  NotificationEntity({
    required this.id,
    required this.targetUserId,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetUserId': targetUserId,
      'title': title,
      'body': body,
      'date': Timestamp.fromDate(date),
      'isRead': isRead,
    };
  }

  factory NotificationEntity.fromMap(Map<String, dynamic> map, String id) {
    return NotificationEntity(
      id: id,
      targetUserId: map['targetUserId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
