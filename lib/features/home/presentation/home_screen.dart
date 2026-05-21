import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import 'package:sportsmate/core/providers/common_providers.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/home/data/feedrepository.dart';
import 'package:sportsmate/features/AddFeed/domain/AddFeed_entity.dart';
import 'package:sportsmate/features/AddFeed/presentation/AddFeed_Screen.dart';
import 'package:sportsmate/features/home/domain/comment_entity.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/chat/presentation/chat_list_screen.dart';
import 'package:sportsmate/features/chat/data/chat_repository.dart';
import 'home_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportsmate/features/home/domain/ad_entity.dart';
import 'package:sportsmate/features/tournament/presentation/tournament_list_screen.dart';
import 'package:sportsmate/features/games/presentation/games_feed_screen.dart';
import 'package:sportsmate/features/notifications/presentation/notifications_screen.dart';
import 'package:sportsmate/features/friends/presentation/friends_screen.dart';
import 'package:sportsmate/features/friends/presentation/user_profile_screen.dart';

class HomeFeedView extends ConsumerStatefulWidget {
  const HomeFeedView({super.key});

  @override
  ConsumerState<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends ConsumerState<HomeFeedView> {
  @override
  Widget build(BuildContext context) {
    final feedListAsync = ref.watch(feedListStreamProvider);
    final adsAsync = ref.watch(adListStreamProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        title: Text(
          "NearPlay",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Theme toggle: tap to switch dark ↔ light
          Consumer(builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: Theme.of(context).iconTheme.color),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            );
          }),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
        ],
      ),
      body: feedListAsync.when(
        data: (feeds) {
          return adsAsync.when(
            data: (ads) {
              final mixedItems = _getMixedItems(feeds, ads);
              
              if (mixedItems.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.refresh(feedListStreamProvider.future);
                    await ref.refresh(adListStreamProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildComposerCard(context),
                      const SizedBox(height: 40),
                      _buildEmptyState(),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(feedListStreamProvider.future);
                  await ref.refresh(adListStreamProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: mixedItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildComposerCard(context);
                    }
                    final item = mixedItems[index - 1];
                    if (item is FeedEntity) {
                      return FeedItem(feed: item);
                    } else if (item is AdEntity) {
                      return AdItem(ad: item);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error loading ads: $err")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading feeds: $err")),
      ),
    );
  }

  List<dynamic> _getMixedItems(List<FeedEntity> feeds, List<AdEntity> ads) {
    List<dynamic> mixed = [];
    if (feeds.isEmpty && ads.isEmpty) return [];
    
    // If no feeds, just show ads
    if (feeds.isEmpty) return ads;

    int adIndex = 0;
    for (int i = 0; i < feeds.length; i++) {
      mixed.add(feeds[i]);
      // Insert an ad every 2 feeds for better visibility during testing
      if ((i + 1) % 2 == 0 && ads.isNotEmpty) {
        mixed.add(ads[adIndex % ads.length]);
        adIndex++;
      }
    }
    
    // If we have fewer than 2 feeds but have ads, add one at the end
    if (feeds.length < 2 && ads.isNotEmpty) {
      mixed.add(ads[0]);
    }
    
    return mixed;
  }

  Widget _buildComposerCard(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.value;
    final avatarUrl = userProfile?.profilePic;
    final displayName = userProfile?.username ?? "Friend";

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
        border: Border.all(color: cs.outline, width: 0.8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFeedScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0x1A0F5132),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(Icons.person, color: Theme.of(context).primaryColor)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        "What's on your mind, $displayName?",
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: cs.outline, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildComposerAction(
                    icon: Icons.photo_library_outlined,
                    color: const Color(0xFF2E7D32),
                    label: "Photo",
                  ),
                  _buildComposerAction(
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFF1565C0),
                    label: "Camera",
                  ),
                  _buildComposerAction(
                    icon: Icons.sports_soccer_outlined,
                    color: const Color(0xFFE65100),
                    label: "Game",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposerAction({required IconData icon, required Color color, required String label}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 60, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No feeds yet. Be the first to post!',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class AdItem extends StatelessWidget {
  final AdEntity ad;
  const AdItem({super.key, required this.ad});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(ad.link);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.campaign, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sponsored',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          if (ad.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: _launchUrl,
              child: ClipRRect(
                child: Image.network(
                  ad.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.description,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  // ElevatedButton uses AppTheme.elevatedButtonTheme automatically
                  child: ElevatedButton(
                    onPressed: _launchUrl,
                    child: const Text('Learn More', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeedItem extends ConsumerStatefulWidget {
  final FeedEntity feed;
  const FeedItem({super.key, required this.feed});

  @override
  ConsumerState<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends ConsumerState<FeedItem> {
  bool _localIsLiked = false;
  int _localLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _localIsLiked = false; // Will be set in build based on profile
  }

  void _showComments(BuildContext context) {
    final commentController = TextEditingController();
    CommentEntity? replyingTo;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<List<CommentEntity>>(
                    stream: ref.read(feedRepositoryProvider).watchComments(widget.feed.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final allComments = snapshot.data ?? [];
                      if (allComments.isEmpty) {
                        return const Center(child: Text("No comments yet."));
                      }
                      
                      final topLevelComments = allComments.where((c) => c.parentCommentId == null).toList();
                      
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: topLevelComments.length,
                        itemBuilder: (context, index) {
                          final comment = topLevelComments[index];
                          final replies = allComments.where((c) => c.parentCommentId == comment.id).toList();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(comment.userProfileImage),
                                ),
                                title: Text(comment.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment.text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(comment.date),
                                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.reply, size: 16),
                                  onPressed: () {
                                    setSheetState(() {
                                      replyingTo = comment;
                                      commentController.text = "@${comment.username} ";
                                    });
                                  },
                                ),
                              ),
                              ...replies.map((reply) => Padding(
                                padding: const EdgeInsets.only(left: 48.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(reply.userProfileImage),
                                  ),
                                  title: Text(reply.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reply.text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(reply.date),
                                        style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                if (replyingTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Text("Replying to @${replyingTo!.username}",
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setSheetState(() {
                            replyingTo = null;
                            commentController.clear();
                          }),
                          child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(ref.read(userProfileProvider).value?.profilePic ?? ''),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          autofocus: replyingTo != null,
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          final user = ref.read(userProfileProvider).value;
                          if (user == null) return;

                          final newComment = CommentEntity(
                            id: '',
                            uid: user.uid,
                            username: user.name,
                            userProfileImage: user.profilePic ?? 'https://i.pravatar.cc/150?u=${user.uid}',
                            text: commentController.text.trim(),
                            date: DateTime.now(),
                            parentCommentId: replyingTo?.id,
                          );

                          await ref.read(feedRepositoryProvider).addComment(widget.feed.id, newComment);
                          commentController.clear();
                          setSheetState(() {
                            replyingTo = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    String searchQuery = "";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Share Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: "Check out this post on NearPlay: ${widget.feed.id}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Link copied to clipboard!")),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.link),
                        label: const Text("Copy Link"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) => setSheetState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Athlete>>(
                    future: ref.read(profileRepositoryProvider).getAllAthletes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final allAthletes = snapshot.data ?? [];
                      final filtered = allAthletes.where((a) => a.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                      
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final athlete = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(athlete.profilePic ?? 'https://i.pravatar.cc/150?u=${athlete.uid}'),
                            ),
                            title: Text(athlete.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            subtitle: Text("@${athlete.username}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final user = ref.read(userProfileProvider).value;
                                if (user == null) return;
                                
                                final chatId = await ref.read(chatRepositoryProvider).getOrCreateChatId(user.uid, athlete.uid);
                                await ref.read(chatRepositoryProvider).sendMessage(
                                  user.uid,
                                  chatId,
                                  "Check out this post: ${widget.feed.description}",
                                  sharedPostId: widget.feed.id,
                                );
                                
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Shared to ${athlete.name}")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text("Send"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isLiked = userProfile != null && widget.feed.likes.contains(userProfile.uid);
    
    _localIsLiked = isLiked;
    _localLikeCount = widget.feed.likes.length;

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: widget.feed.uid),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: widget.feed.userProfileImage.startsWith('http')
                              ? NetworkImage(widget.feed.userProfileImage)
                              : null,
                          child: !widget.feed.userProfileImage.startsWith('http')
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.feed.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d • h:mm a').format(widget.feed.date),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (widget.feed.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Text(
                widget.feed.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: cs.onSurface,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (widget.feed.mediaUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: widget.feed.mediaUrl.startsWith('/') || widget.feed.mediaUrl.contains('Users') || widget.feed.mediaUrl.contains('data')
                  ? Image.file(
                      File(widget.feed.mediaUrl),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                      ),
                    )
                  : Image.network(
                      widget.feed.mediaUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
            ),
          const SizedBox(height: 8),
          // Interactions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (userProfile != null) {
                      setState(() {
                        _localIsLiked = !_localIsLiked;
                        _localLikeCount += _localIsLiked ? 1 : -1;
                      });
                      ref.read(feedRepositoryProvider).toggleLike(widget.feed.id, userProfile.uid);
                    }
                  },
                  child: _InteractionIcon(
                    icon: _localIsLiked ? Icons.favorite : Icons.favorite_border,
                    count: _localLikeCount.toString(),
                    color: _localIsLiked ? AppColors.semanticError : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: _InteractionIcon(
                    icon: Icons.chat_bubble_outline,
                    count: '...',
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showShareSheet(context),
                  child: _InteractionIcon(
                    icon: Icons.share_outlined,
                    count: '',
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(Icons.bookmark_border, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InteractionIcon extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;

  const _InteractionIcon({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        if (count.isNotEmpty && count != '0')
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(
              count,
              style: TextStyle(
                color: secondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeFeedView(),
      const GamesFeedScreen(),
      const TournamentListScreen(),
      const FriendsScreen(),
      UserProfileScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Colors come from AppTheme.bottomNavigationBarTheme
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Tournaments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
