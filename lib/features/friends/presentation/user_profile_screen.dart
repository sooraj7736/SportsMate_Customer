import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import 'package:sportsmate/core/providers/common_providers.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/games/data/games_repository.dart';
import 'package:sportsmate/features/games/domain/game_entity.dart';
import 'package:sportsmate/features/games/presentation/games_feed_screen.dart'; // for showJoinGameBottomSheet
import 'package:sportsmate/features/home/data/feedrepository.dart';
import 'package:sportsmate/features/AddFeed/domain/AddFeed_entity.dart';
import 'package:sportsmate/features/home/presentation/home_screen.dart'; // for FeedItem
import 'package:sportsmate/features/chat/presentation/chat_room_screen.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/profile/presentation/edit_profile_screen.dart';
import 'package:sportsmate/features/profile/presentation/address_selection_screen.dart';
import '../data/friends_repository.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Athlete? _viewedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await ref.read(profileRepositoryProvider).getAthleteProfile(widget.userId);
      if (mounted) {
        setState(() {
          _viewedUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = ref.watch(userProfileProvider).value;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (_viewedUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: Text("User profile not found")),
      );
    }

    final isMe = loggedInUser?.uid == _viewedUser!.uid;
    final friendshipStatus = ref.watch(friendshipStatusProvider(_viewedUser!.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              actions: isMe
                  ? [
                      IconButton(
                        icon: Icon(
                          ref.watch(themeModeProvider) == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
                          ref.read(themeModeProvider.notifier).setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("Logout"),
                              content: const Text("Are you sure you want to logout?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    ref.read(authControllerProvider.notifier).signOut();
                                  },
                                  child: const Text("Logout", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Header gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // User details overlay
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: isMe
                                ? () async {
                                    try {
                                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                                      if (pickedFile != null) {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        final file = File(pickedFile.path);
                                        final repo = ref.read(profileRepositoryProvider);
                                        final newPicUrl = await repo.uploadProfileImage(_viewedUser!.uid, file);
                                        
                                        final updatedAthlete = Athlete(
                                          uid: _viewedUser!.uid,
                                          username: _viewedUser!.username,
                                          name: _viewedUser!.name,
                                          email: _viewedUser!.email,
                                          favoriteSports: _viewedUser!.favoriteSports,
                                          skillLevel: _viewedUser!.skillLevel,
                                          profilePic: newPicUrl,
                                        );
                                        await repo.saveAthleteProfile(updatedAthlete);
                                        
                                        ref.invalidate(userProfileProvider);
                                        await _loadUserProfile();
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Profile photo updated successfully!")),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Failed to update profile photo: $e")),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  }
                                : null,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 45,
                                    backgroundImage: _viewedUser!.profilePic != null && _viewedUser!.profilePic!.isNotEmpty
                                        ? NetworkImage(_viewedUser!.profilePic!)
                                        : null,
                                    child: _viewedUser!.profilePic == null || _viewedUser!.profilePic!.isEmpty
                                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                        : null,
                                  ),
                                ),
                                if (isMe)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _viewedUser!.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "@${_viewedUser!.username}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_viewedUser!.skillLevel.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.achievementGold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _viewedUser!.skillLevel,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About/Sports chips
                    if (_viewedUser!.favoriteSports.isNotEmpty) ...[
                      const Text(
                        "Favorite Sports",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _viewedUser!.favoriteSports.map((sport) {
                          return Chip(
                            label: Text(sport),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.08),
                            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action Buttons Row (Edit Profile if Me, otherwise Add Friend / Message)
                    if (loggedInUser != null) ...[
                      Row(
                        children: [
                          if (isMe) ...[
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(athlete: _viewedUser!),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserProfile();
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text("Edit Profile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddressSelectionScreen()),
                                  );
                                },
                                icon: const Icon(Icons.location_on, size: 16, color: Colors.blueAccent),
                                label: const Text("Addresses", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blueAccent,
                                  side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ]
                          else ...[
                            Expanded(
                              child: _buildFriendshipButton(context, friendshipStatus, loggedInUser, _viewedUser!),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomScreen(otherUser: _viewedUser),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text("Message Him"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tab bar for Feeds and Games
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade100 : Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.sports_soccer),
                            text: "Games Hosted",
                          ),
                          Tab(
                            icon: Icon(Icons.feed),
                            text: "Feeds Posted",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGamesHostedTab(),
            _buildFeedsPostedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendshipButton(
    BuildContext context,
    FriendshipStatus status,
    Athlete me,
    Athlete them,
  ) {
    switch (status) {
      case FriendshipStatus.friends:
        return OutlinedButton.icon(
          onPressed: () => _showUnfriendDialog(context, me.uid, them),
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text("Friends"),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      case FriendshipStatus.pendingSent:
        return ElevatedButton.icon(
          onPressed: () {
            ref.read(friendsRepositoryProvider).declineFriendRequest(
                  senderId: me.uid,
                  receiverId: them.uid,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Friend request cancelled")),
            );
          },
          icon: const Icon(Icons.hourglass_empty),
          label: const Text("Requested"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        );
      case FriendshipStatus.pendingReceived:
        return ElevatedButton.icon(
          onPressed: () async {
            await ref.read(friendsRepositoryProvider).acceptFriendRequest(
                  senderId: them.uid,
                  receiverId: me.uid,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("You are now friends with ${them.name}!")),
              );
            }
          },
          icon: const Icon(Icons.person_add),
          label: const Text("Accept Request"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.achievementGold,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
        );
      case FriendshipStatus.none:
        return ElevatedButton.icon(
          onPressed: () async {
            await ref.read(friendsRepositoryProvider).sendFriendRequest(
                  sender: me,
                  receiver: them,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Friend request sent to ${them.name}")),
              );
            }
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text("Add Friend"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
        );
    }
  }

  void _showUnfriendDialog(BuildContext context, String myUid, Athlete friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Unfriend ${friend.name}?"),
        content: Text("Are you sure you want to remove ${friend.name} from your friend list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(friendsRepositoryProvider).unfriend(
                    uid1: myUid,
                    uid2: friend.uid,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Removed ${friend.name} from friends")),
                );
              }
            },
            child: const Text("Unfriend", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesHostedTab() {
    return StreamBuilder<List<GameEntity>>(
      stream: ref.watch(gamesRepositoryProvider).watchGamesHostedByMe(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final games = snapshot.data ?? [];
        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No games hosted yet",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            final isPublic = game.gameAccess == 'Public';
            final filledSpots = game.joinedPlayers.length;
            final maxPlayers = game.maxPlayers;
            final progressValue = maxPlayers <= 0 ? 0.0 : (filledSpots / maxPlayers).clamp(0.0, 1.0);
            final isMatchFull = filledSpots >= maxPlayers;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.sports_soccer, size: 18, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${game.sportType} game at ${game.locationName}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: isPublic ? Colors.blue.shade50 : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            game.gameAccess,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPublic ? Colors.blue.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildProfileInfoChip(
                          icon: Icons.calendar_month_outlined,
                          label: DateFormat('EEE, MMM d').format(game.date),
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        if (game.startTime.isNotEmpty && game.endTime.isNotEmpty)
                          _buildProfileInfoChip(
                            icon: Icons.access_time,
                            label: '${game.startTime} - ${game.endTime}',
                            color: Colors.blue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$filledSpots / $maxPlayers Spots Filled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    (game.hostId == FirebaseAuth.instance.currentUser?.uid)
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => showInviteFriendsBottomSheet(context, game, ref),
                                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                                  label: const Text('Add Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => showGameInviteUsersBottomSheet(context, game, ref),
                                  icon: const Icon(Icons.forward_to_inbox, size: 16),
                                  label: const Text('Invite User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigoAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isMatchFull
                                  ? null
                                  : () => showJoinGameBottomSheet(context, game, ref),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(isMatchFull ? 'Match Full' : 'Join Game', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedsPostedTab() {
    return StreamBuilder<List<FeedEntity>>(
      stream: ref.watch(feedRepositoryProvider).watchFeeds().map(
            (feeds) => feeds.where((f) => f.uid == widget.userId).toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final feeds = snapshot.data ?? [];
        if (feeds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No feeds posted yet",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: feeds.length,
          itemBuilder: (context, index) {
            final feed = feeds[index];
            final hasImage = feed.mediaUrl.isNotEmpty;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedDetailScreen(feed: feed),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade900,
                  child: hasImage
                      ? Image.network(
                          feed.mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildTextFeedPlaceholder(feed);
                          },
                        )
                      : _buildTextFeedPlaceholder(feed),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextFeedPlaceholder(FeedEntity feed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          feed.description.isNotEmpty ? feed.description : feed.title,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedDetailScreen extends StatelessWidget {
  final FeedEntity feed;
  const FeedDetailScreen({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Post",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: FeedItem(feed: feed),
      ),
    );
  }
}
