import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/chat/data/chat_repository.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'chat_room_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedUserIds = [];
  String _searchQuery = "";

  void _toggleUser(String uid) {
    setState(() {
      if (_selectedUserIds.contains(uid)) {
        _selectedUserIds.remove(uid);
      } else {
        _selectedUserIds.add(uid);
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter group name and select members")),
      );
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    await ref.read(chatRepositoryProvider).createGroupChat(
      user.uid,
      _selectedUserIds,
      name,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            groupChat: null, // We'll let the room fetch it or pass the ID
          ),
        ),
      );
      // Actually better to pass the newly created group chat entity or its details
      // But let's just go back to the chat list for now as it's easier to refresh
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Group", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Group Name",
                prefixIcon: const Icon(Icons.group_work),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Add Members",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedUserIds.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedUserIds.length,
                itemBuilder: (context, index) {
                  final uid = _selectedUserIds[index];
                  return FutureBuilder<Athlete?>(
                    future: ref.read(profileRepositoryProvider).getAthleteProfile(uid),
                    builder: (context, snapshot) {
                      final athlete = snapshot.data;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: athlete?.profilePic != null ? NetworkImage(athlete!.profilePic!) : null,
                                  child: athlete?.profilePic == null ? const Icon(Icons.person) : null,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _toggleUser(uid),
                                    child: const CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.grey,
                                      child: Icon(Icons.close, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                athlete?.name.split(' ').first ?? "",
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Athlete>>(
              future: ref.read(profileRepositoryProvider).getAllAthletes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final filtered = snapshot.data!
                    .where((a) => a.uid != userProfile.uid && 
                        (a.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                         a.username.toLowerCase().contains(_searchQuery.toLowerCase())))
                    .toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final athlete = filtered[index];
                    final isSelected = _selectedUserIds.contains(athlete.uid);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: athlete.profilePic != null ? NetworkImage(athlete.profilePic!) : null,
                        child: athlete.profilePic == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(athlete.name),
                      subtitle: Text("@${athlete.username}"),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      onTap: () => _toggleUser(athlete.uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
