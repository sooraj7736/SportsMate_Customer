import 'package:cloud_firestore/cloud_firestore.dart';

class CommentEntity {
  final String id;
  final String uid;
  final String username;
  final String userProfileImage;
  final String text;
  final DateTime date;
  final String? parentCommentId; // For replies

  const CommentEntity({
    required this.id,
    required this.uid,
    required this.username,
    required this.userProfileImage,
    required this.text,
    required this.date,
    this.parentCommentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'userProfileImage': userProfileImage,
      'text': text,
      'date': Timestamp.fromDate(date),
      'parentCommentId': parentCommentId,
    };
  }

  factory CommentEntity.fromMap(Map<String, dynamic> map, String docId) {
    return CommentEntity(
      id: docId,
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      userProfileImage: map['userProfileImage'] ?? '',
      text: map['text'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: map['parentCommentId'],
    );
  }
}
