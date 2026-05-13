import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/chat/data/chat_repository.dart';
import 'package:sportsmate/features/chat/domain/chat_entity.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/home/data/feedrepository.dart';
import 'package:sportsmate/features/AddFeed/domain/AddFeed_entity.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final Athlete? otherUser;
  final ChatEntity? groupChat;
  const ChatRoomScreen({super.key, this.otherUser, this.groupChat});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    if (widget.groupChat != null) {
      setState(() => _chatId = widget.groupChat!.id);
    } else if (widget.otherUser != null) {
      final id = await ref.read(chatRepositoryProvider).getOrCreateChatId(user.uid, widget.otherUser!.uid);
      setState(() => _chatId = id);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    ref.read(chatRepositoryProvider).sendMessage(
          user.uid,
          _chatId!,
          text,
        );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    final title = widget.groupChat?.groupName ?? widget.otherUser?.name ?? "Chat";
    final imageUrl = widget.groupChat?.groupImage ?? widget.otherUser?.profilePic;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null ? Icon(widget.groupChat != null ? Icons.group : Icons.person, size: 20) : null,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _chatId == null 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageEntity>>(
                    stream: ref.watch(chatRepositoryProvider).watchMessages(_chatId!),
                    builder: (context, msgSnapshot) {
                      if (msgSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = msgSnapshot.data ?? [];
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == user.uid;
                          
                          return _MessageBubble(message: message, isMe: isMe, chatId: _chatId!);
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final MessageEntity message;
  final bool isMe;
  final String chatId;

  const _MessageBubble({required this.message, required this.isMe, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mark as read if received and not already read
    if (!isMe && !message.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatRepositoryProvider).markMessageAsRead(chatId, message.id);
      });
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.sharedPostId != null)
            _buildSharedFeedPreview(context, ref, message.sharedPostId!),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe 
                  ? const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00C6FF)])
                  : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.date),
                      style: TextStyle(
                        color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.check,
                        size: 14,
                        color: message.isRead ? Colors.lightBlueAccent : Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedFeedPreview(BuildContext context, WidgetRef ref, String feedId) {
    return FutureBuilder<FeedEntity?>(
      future: ref.read(feedRepositoryProvider).getFeedById(feedId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final feed = snapshot.data!;
        
        return Container(
          width: 200,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (feed.mediaUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: feed.mediaUrl.startsWith('http') 
                    ? Image.network(
                        feed.mediaUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                      )
                    : Image.file(
                        File(feed.mediaUrl),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                      ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundImage: NetworkImage(feed.userProfileImage),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            feed.username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feed.description,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 120,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
