import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import '../data/friends_repository.dart';
import 'user_profile_screen.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingRequestsAsync = ref.watch(incomingRequestsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Friend Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: incomingRequestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No pending friend requests",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              final senderId = request['senderId'] ?? '';
              final senderName = request['senderName'] ?? 'Athlete';
              final senderUsername = request['senderUsername'] ?? 'athlete';
              final senderProfilePic = request['senderProfilePic'] ?? '';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    // Clickable profile picture
                    GestureDetector(
                      onTap: () {
                        if (senderId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: senderId),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: senderProfilePic.isNotEmpty ? NetworkImage(senderProfilePic) : null,
                        child: senderProfilePic.isEmpty ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Clickable name details
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (senderId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: senderId),
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "@$senderUsername",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action Buttons (Accept / Decline)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filled(
                          icon: const Icon(Icons.check, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          onPressed: () async {
                            await ref.read(friendsRepositoryProvider).acceptFriendRequest(
                                  senderId: senderId,
                                  receiverId: request['receiverId'],
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Accepted friend request from $senderName")),
                              );
                            }
                          },
                          constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                          ),
                          onPressed: () async {
                            await ref.read(friendsRepositoryProvider).declineFriendRequest(
                                  senderId: senderId,
                                  receiverId: request['receiverId'],
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Declined friend request")),
                              );
                            }
                          },
                          constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
