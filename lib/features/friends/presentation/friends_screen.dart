import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/chat/presentation/chat_room_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/friends_repository.dart';
import 'friend_requests_screen.dart';
import 'user_profile_screen.dart';
import 'package:sportsmate/features/games/data/games_repository.dart';
import 'package:sportsmate/features/games/presentation/game_invitations_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Athlete> _allAthletes = [];
  bool _isSearchingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadAllAthletes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAthletes() async {
    try {
      final athletes = await ref.read(profileRepositoryProvider).getAllAthletes();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (mounted) {
        setState(() {
          _allAthletes = athletes.where((a) => a.uid != currentUid).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = ref.watch(userProfileProvider).value;
    final friendsAsync = ref.watch(friendsStreamProvider);
    final incomingRequests = ref.watch(incomingRequestsStreamProvider).value ?? [];
    final gameInvites = ref.watch(incomingGameInvitationsStreamProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Friends",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          // Game Invitations Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline_rounded, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GameInvitationsScreen()),
                  );
                },
              ),
              if (gameInvites.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${gameInvites.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          // Friend Requests Link Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FriendRequestsScreen()),
                  );
                },
              ),
              if (incomingRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${incomingRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                  _isSearchingUsers = _searchQuery.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: "Search users by name or username...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = "";
                            _isSearchingUsers = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade100
                    : Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isSearchingUsers
                ? _buildSearchResults(loggedInUser)
                : _buildFriendsList(friendsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(Athlete? loggedInUser) {
    if (loggedInUser == null) return const SizedBox.shrink();

    // Filter out the logged-in user themselves
    final filteredUsers = _allAthletes.where((athlete) {
      if (athlete.uid == loggedInUser.uid) return false;
      final query = _searchQuery.toLowerCase();
      return athlete.name.toLowerCase().contains(query) ||
          athlete.username.toLowerCase().contains(query);
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "No users found matching '$_searchQuery'",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final athlete = filteredUsers[index];
        final friendshipStatus = ref.watch(friendshipStatusProvider(athlete.uid));

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // User Avatar
              GestureDetector(
                onTap: () => _navigateToProfile(athlete.uid),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: athlete.profilePic != null && athlete.profilePic!.isNotEmpty
                      ? NetworkImage(athlete.profilePic!)
                      : null,
                  child: athlete.profilePic == null || athlete.profilePic!.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // User Name & Username
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(athlete.uid),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "@${athlete.username}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Button
              _buildSearchResultAction(friendshipStatus, loggedInUser, athlete),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResultAction(FriendshipStatus status, Athlete me, Athlete them) {
    switch (status) {
      case FriendshipStatus.friends:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatRoomScreen(otherUser: them)),
                );
              },
            )
          ],
        );
      case FriendshipStatus.pendingSent:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            disabledBackgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            "Requested",
            style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      case FriendshipStatus.pendingReceived:
        return ElevatedButton(
          onPressed: () async {
            await ref.read(friendsRepositoryProvider).acceptFriendRequest(
                  senderId: them.uid,
                  receiverId: me.uid,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("You are now friends with ${them.name}!")),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.achievementGold,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            "Accept",
            style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      case FriendshipStatus.none:
        return ElevatedButton(
          onPressed: () async {
            await ref.read(friendsRepositoryProvider).sendFriendRequest(
                  sender: me,
                  receiver: them,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Friend request sent to ${them.name}")),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            "Add Friend",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  Widget _buildFriendsList(AsyncValue<List<Athlete>> friendsAsync) {
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 70, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No friends added yet",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  "Use the search bar above to find other players",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: friends.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final friend = friends[index];

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Friend Profile Picture
                  GestureDetector(
                    onTap: () => _navigateToProfile(friend.uid),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: friend.profilePic != null && friend.profilePic!.isNotEmpty
                          ? NetworkImage(friend.profilePic!)
                          : null,
                      child: friend.profilePic == null || friend.profilePic!.isEmpty
                          ? const Icon(Icons.person, size: 28, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Friend Details
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToProfile(friend.uid),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "@${friend.username}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (friend.favoriteSports.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: friend.favoriteSports.take(3).map((sport) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      sport,
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Message Button
                  IconButton.filledTonal(
                    icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatRoomScreen(otherUser: friend)),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }

  void _navigateToProfile(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: uid),
      ),
    );
  }
}
