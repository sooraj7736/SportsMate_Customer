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
    if (!_isPostEnabled) return;

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User profile not found")),
      );
      return;
    }

    // Logic for uploading image would go here if we had a storage service
    // For now, we'll just save the feed with a local path or empty mediaUrl
    final newFeed = FeedEntity(
      id: '', 
      uid: userProfile.uid,
      username: userProfile.name,
      userProfileImage: userProfile.profilePic ?? 'https://i.pravatar.cc/150?u=${userProfile.uid}',
      title: '', 
      description: _contentController.text.trim(),
      mediaUrl: _image?.path ?? '', 
      date: DateTime.now(),
      likes: [],
    );

    try {
      await ref.read(addFeedRepositoryProvider).addFeed(newFeed);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _visibility,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: ["Everyone", "Friends Only"].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 12)),
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
                  style: const TextStyle(fontSize: 18),
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
                        child: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 12,
                          child: Icon(Icons.close, color: Colors.white, size: 16),
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
                      icon: const Icon(Icons.image_outlined, color: Colors.blue, size: 30),
                      onPressed: _pickImage,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isPostEnabled ? _handlePost : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Post", style: TextStyle(fontWeight: FontWeight.bold)),
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