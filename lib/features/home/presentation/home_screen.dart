import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/home/data/feedrepository.dart';
import 'package:sportsmate/features/AddFeed/domain/AddFeed_entity.dart';
import 'package:sportsmate/features/AddFeed/presentation/AddFeed_Screen.dart';
import 'package:sportsmate/features/home/domain/comment_entity.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/chat/presentation/chat_list_screen.dart';
import 'package:sportsmate/features/chat/data/chat_repository.dart';
import 'package:sportsmate/core/providers/common_providers.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'home_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportsmate/features/home/domain/ad_entity.dart';
import 'package:sportsmate/features/tournament/presentation/tournament_list_screen.dart';
import 'package:sportsmate/features/games/presentation/games_feed_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
          "SportsMate",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ref.watch(userProfileProvider).value?.name ?? "Athlete",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text("Dark Mode"),
              trailing: Switch(
                value: ref.watch(themeModeProvider) == ThemeMode.dark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text("Tournaments"),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TournamentListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text("Games"),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesFeedScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFeedScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: feedListAsync.when(
        data: (feeds) {
          return adsAsync.when(
            data: (ads) {
              final mixedItems = _getMixedItems(feeds, ads);
              
              if (mixedItems.isEmpty) {
                return _buildEmptyState();
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(feedListStreamProvider.future);
                  await ref.refresh(adListStreamProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: mixedItems.length,
                  itemBuilder: (context, index) {
                    final item = mixedItems[index];
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No feeds yet. Be the first to post!",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Sponsored",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.grey),
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
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.description,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _launchUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text("Learn More", style: TextStyle(fontWeight: FontWeight.bold)),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      
                      // Separate top-level comments and replies
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
                                title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment.text, style: const TextStyle(color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(comment.date),
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                              // Display replies
                              ...replies.map((reply) => Padding(
                                padding: const EdgeInsets.only(left: 48.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(reply.userProfileImage),
                                  ),
                                  title: Text(reply.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reply.text, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(reply.date),
                                        style: const TextStyle(fontSize: 9, color: Colors.grey),
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
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Text("Replying to @${replyingTo!.username}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setSheetState(() {
                            replyingTo = null;
                            commentController.clear();
                          }),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
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
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Share Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: "Check out this post on SportsMate: ${widget.feed.id}"));
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
                      hintText: "Search friends...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                            title: Text(athlete.name),
                            subtitle: Text("@${athlete.username}"),
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
    
    // Set local state if not manually updated
    _localIsLiked = isLiked;
    _localLikeCount = widget.feed.likes.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d • h:mm a').format(widget.feed.date),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Description
          if (widget.feed.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Text(
                widget.feed.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Media
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
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
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
                    color: _localIsLiked ? Colors.red : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: const _InteractionIcon(
                    icon: Icons.chat_bubble_outline,
                    count: "...", // Fetching count asynchronously is better but for now ...
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showShareSheet(context),
                  child: const _InteractionIcon(
                    icon: Icons.share_outlined,
                    count: "",
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Icon(Icons.bookmark_border, color: Colors.grey.shade600),
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
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        if (count.isNotEmpty && count != "0")
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(
              count,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
