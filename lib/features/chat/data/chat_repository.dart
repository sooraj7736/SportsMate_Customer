import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/chat/domain/chat_entity.dart';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(FirebaseFirestore.instance),
);

class ChatRepository {
  final FirebaseFirestore _firestore;
  ChatRepository(this._firestore);

  Stream<List<ChatEntity>> watchChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatEntity.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageEntity.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> sendMessage(String senderId, String chatId, String text, {String? sharedPostId}) async {
    final chatDoc = _firestore.collection('chats').doc(chatId);
    final finalMessage = sharedPostId != null ? "Shared a post: $text" : text;
    
    final message = MessageEntity(
      id: '',
      senderId: senderId,
      receiverId: chatId,
      text: finalMessage,
      date: DateTime.now(),
      sharedPostId: sharedPostId,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(chatDoc, {
        'lastMessage': finalMessage,
        'lastMessageDate': Timestamp.fromDate(message.date),
        'lastMessageSenderId': senderId,
      }, SetOptions(merge: true));

      final newMessageDoc = chatDoc.collection('messages').doc();
      transaction.set(newMessageDoc, message.toMap());
    });
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  Future<String> createGroupChat(String creatorId, List<String> participantIds, String name, {String? image}) async {
    final doc = _firestore.collection('chats').doc();
    final participants = [creatorId, ...participantIds];
    
    final chat = ChatEntity(
      id: doc.id,
      participants: participants,
      lastMessage: "Group created",
      lastMessageDate: DateTime.now(),
      lastMessageSenderId: creatorId,
      isGroup: true,
      groupName: name,
      groupImage: image,
    );

    await doc.set(chat.toMap());
    return doc.id;
  }

  Future<String> getOrCreateChatId(String uid1, String uid2) async {
    final participants = [uid1, uid2];
    participants.sort();
    final chatId = participants.join('_');
    
    await _firestore.collection('chats').doc(chatId).set({
      'participants': participants,
      'isGroup': false,
      'lastMessage': '',
      'lastMessageDate': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
    }, SetOptions(merge: true));
    
    return chatId;
  }
}
