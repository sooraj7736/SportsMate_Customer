import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/chat/data/chat_repository.dart';
import 'package:sportsmate/features/chat/domain/chat_entity.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:intl/intl.dart';
import 'chat_room_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      // Scaffold bg comes from AppTheme automatically
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        // bg & text come from AppTheme.appBarTheme automatically
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note, color: cs.primary, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Please login to see messages'));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search messages or users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    // Style from AppTheme.inputDecorationTheme
                  ),
                ),
              ),
              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildChatList(user.uid, cs)
                    : _buildSearchResults(user.uid),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChatList(String currentUid, ColorScheme cs) {
    return StreamBuilder<List<ChatEntity>>(
      stream: ref.watch(chatRepositoryProvider).watchChats(currentUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Error: ${snapshot.error}'),
          ));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined, size: 80, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No messages yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (context, index) => Divider(height: 1, indent: 70, color: cs.outline),
          itemBuilder: (context, index) {
            final chat = chats[index];

            if (chat.isGroup) {
              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: chat.groupImage != null ? NetworkImage(chat.groupImage!) : null,
                  child: chat.groupImage == null ? const Icon(Icons.group) : null,
                ),
                title: Text(chat.groupName ?? 'Group Chat', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${chat.lastMessageSenderId == currentUid ? 'You: ' : ''}${chat.lastMessage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  DateFormat('h:mm a').format(chat.lastMessageDate),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatRoomScreen(groupChat: chat)),
                  );
                },
              );
            }

            final otherUserId = chat.participants.firstWhere(
              (id) => id != currentUid,
              orElse: () => currentUid,
            );

            return FutureBuilder<Athlete?>(
              future: ref.read(profileRepositoryProvider).getAthleteProfile(otherUserId),
              builder: (context, athleteSnapshot) {
                final athlete = athleteSnapshot.data;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: athlete?.profilePic != null ? NetworkImage(athlete!.profilePic!) : null,
                    child: athlete?.profilePic == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(athlete?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${chat.lastMessageSenderId == currentUid ? 'You: ' : ''}${chat.lastMessage}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat('h:mm a').format(chat.lastMessageDate),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  onTap: () {
                    if (athlete != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatRoomScreen(otherUser: athlete)),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(String currentUid) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<Athlete>>(
      future: ref.read(profileRepositoryProvider).getAllAthletes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filtered = snapshot.data!
            .where((a) => a.uid != currentUid &&
                (a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 a.username.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No users found', style: TextStyle(color: cs.onSurfaceVariant)));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final athlete = filtered[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: athlete.profilePic != null ? NetworkImage(athlete.profilePic!) : null,
                child: athlete.profilePic == null ? const Icon(Icons.person) : null,
              ),
              title: Text(athlete.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${athlete.username}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatRoomScreen(otherUser: athlete)),
                );
              },
            );
          },
        );
      },
    );
  }
}
