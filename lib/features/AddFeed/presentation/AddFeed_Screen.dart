import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/AddFeed/data/AddFeed_repository.dart';
import 'package:sportsmate/features/AddFeed/domain/AddFeed_entity.dart';

class AddFeedScreen extends ConsumerStatefulWidget {
  const AddFeedScreen({super.key});

  @override
  ConsumerState<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends ConsumerState<AddFeedScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPostEnabled = false;
  bool _isLoading = false;
  String _visibility = "Everyone";
  File? _image;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        _isPostEnabled = _contentController.text.trim().isNotEmpty || _image != null;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isPostEnabled = true;
      });
    }
  }

  Future<void> _handlePost() async {
    if (!_isPostEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User profile not found")),
      );
      return;
    }

    try {
      String mediaUrl = '';
      if (_image != null) {
        mediaUrl = await ref.read(addFeedRepositoryProvider).uploadFeedImage(userProfile.uid, _image!);
      }

      final newFeed = FeedEntity(
        id: '', 
        uid: userProfile.uid,
        username: userProfile.name,
        userProfileImage: userProfile.profilePic ?? 'https://i.pravatar.cc/150?u=${userProfile.uid}',
        title: '', 
        description: _contentController.text.trim(),
        mediaUrl: mediaUrl, 
        date: DateTime.now(),
        likes: [],
      );

      await ref.read(addFeedRepositoryProvider).addFeed(newFeed);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userProfileAsync.when(
        data: (user) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user?.profilePic != null
                        ? NetworkImage(user!.profilePic!)
                        : NetworkImage('https://i.pravatar.cc/150?u=${user?.uid}') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? "Athlete",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _visibility,
                            icon: Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).iconTheme.color),
                            items: ["Everyone", "Friends Only"].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: Theme.of(context).textTheme.bodySmall),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _visibility = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind?",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 18),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                ),
              ),
              if (_image != null)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _image = null;
                          _isPostEnabled = _contentController.text.trim().isNotEmpty;
                        }),
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          radius: 12,
                          child: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.primary, size: 30),
                      onPressed: _pickImage,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: (_isPostEnabled && !_isLoading) ? _handlePost : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                            )
                          : Text("Post", style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}