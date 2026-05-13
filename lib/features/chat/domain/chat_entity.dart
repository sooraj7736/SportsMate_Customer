import 'package:cloud_firestore/cloud_firestore.dart';

class MessageEntity {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime date;
  final bool isRead;
  final String? sharedPostId;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.date,
    this.isRead = false,
    this.sharedPostId,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'date': Timestamp.fromDate(date),
      'isRead': isRead,
      'sharedPostId': sharedPostId,
    };
  }

  factory MessageEntity.fromMap(Map<String, dynamic> map, String docId) {
    return MessageEntity(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      sharedPostId: map['sharedPostId'],
    );
  }
}

class ChatEntity {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageDate;
  final String lastMessageSenderId;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;

  const ChatEntity({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageDate,
    required this.lastMessageSenderId,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageDate': Timestamp.fromDate(lastMessageDate),
      'lastMessageSenderId': lastMessageSenderId,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
    };
  }

  factory ChatEntity.fromMap(Map<String, dynamic> map, String docId) {
    return ChatEntity(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageDate: (map['lastMessageDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupImage: map['groupImage'],
    );
  }
}
