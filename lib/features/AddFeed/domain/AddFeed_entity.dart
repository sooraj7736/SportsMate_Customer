import 'package:cloud_firestore/cloud_firestore.dart';

class FeedEntity {
  final String id;
  final String uid;
  final String username;
  final String userProfileImage;
  final String title;
  final String description;
  final String mediaUrl;
  final DateTime date;
  final List<String> likes;

  const FeedEntity({
    required this.id,
    required this.uid,
    required this.username,
    required this.userProfileImage,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.date,
    this.likes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'userProfileImage': userProfileImage,
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'date': Timestamp.fromDate(date),
      'likes': likes,
    };
  }

  factory FeedEntity.fromMap(Map<String, dynamic> map, String docId) {
    return FeedEntity(
      id: docId,
      uid: map['uid'] ?? '',
      username: map['username'] ?? map['name'] ?? '',
      userProfileImage: map['userProfileImage'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      mediaUrl: map['mediaUrl'] ?? map['imagePath'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}
