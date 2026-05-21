import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportsmate/core/providers/common_providers.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/sports/data/sports_catalog.dart';
import '../domain/athlete_entity.dart';
import '../data/profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Athlete athlete;
  const EditProfileScreen({super.key, required this.athlete});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late String _selectedSkillLevel;
  late List<String> _selectedSports;
  File? _imageFile;
  bool _isLoading = false;
  String? _usernameError;
  bool _isCheckingUsername = false;

  final List<String> _skillLevels = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.athlete.name);
    _usernameController = TextEditingController(text: widget.athlete.username);
    _selectedSkillLevel = widget.athlete.skillLevel.isNotEmpty && _skillLevels.contains(widget.athlete.skillLevel)
        ? widget.athlete.skillLevel
        : _skillLevels.first;
    _selectedSports = List<String>.from(widget.athlete.favoriteSports);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to pick image")),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final newUsername = _usernameController.text.trim();

      // Check if username changed and check uniqueness
      if (newUsername != widget.athlete.username) {
        setState(() => _isCheckingUsername = true);
        final isUnique = await repo.isUsernameUnique(newUsername);
        setState(() => _isCheckingUsername = false);

        if (!isUnique) {
          setState(() {
            _usernameError = "Username is already taken.";
            _isLoading = false;
          });
          return;
        }
      }

      String? profilePicUrl = widget.athlete.profilePic;
      if (_imageFile != null) {
        profilePicUrl = await repo.uploadProfileImage(widget.athlete.uid, _imageFile!);
      }

      final updatedAthlete = Athlete(
        uid: widget.athlete.uid,
        username: newUsername,
        name: _nameController.text.trim(),
        email: widget.athlete.email,
        favoriteSports: _selectedSports,
        skillLevel: _selectedSkillLevel,
        profilePic: profilePicUrl,
      );

      await repo.saveAthleteProfile(updatedAthlete);
      
      // Invalidate both userProfileProvider and any loaded profiles to refresh the UI globally
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primaryColor = cs.primary;
    final sportsAsync = ref.watch(sportsCatalogProvider);
    final availableSports = sportsAsync.asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Image Editor
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.outline, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowMedium,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (widget.athlete.profilePic != null && widget.athlete.profilePic!.isNotEmpty
                                      ? NetworkImage(widget.athlete.profilePic!)
                                      : null) as ImageProvider?,
                              child: _imageFile == null &&
                                      (widget.athlete.profilePic == null || widget.athlete.profilePic!.isEmpty)
                                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cs.outline, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Display Name Field
                    Text(
                    'Display Name',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => val == null || val.trim().isEmpty ? "Display Name is required" : null,
                      decoration: InputDecoration(
                        hintText: "Enter your full name",
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username Field
                    Text(
                    'Username',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _usernameController,
                      onChanged: (value) {
                        if (_usernameError != null) {
                          setState(() => _usernameError = null);
                        }
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Username is required";
                        final validCharacters = RegExp(r'^[a-zA-Z0-9_]+$');
                        if (!validCharacters.hasMatch(val)) {
                          return "Only letters, numbers, and underscores allowed.";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "username",
                        prefixIcon: const Icon(Icons.alternate_email),
                        suffixIcon: _isCheckingUsername
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        errorText: _usernameError,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skill Level Dropdown
                    Text(
                    'Skill Level',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSkillLevel,
                      items: _skillLevels.map((level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSkillLevel = val);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.trending_up),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Favorite Sports Chips
                    Text(
                    'Favorite Sports',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    if (sportsAsync.isLoading && availableSports.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (availableSports.isEmpty)
                      Text(
                        'No sports are configured in Firestore yet.',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSports.map((sport) {
                          final isSelected = _selectedSports.contains(sport.name);
                          return FilterChip(
                            label: Text(sport.name),
                            avatar: sport.icon.isNotEmpty ? Text(sport.icon) : null,
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (!_selectedSports.contains(sport.name)) {
                                    _selectedSports.add(sport.name);
                                  }
                                } else {
                                  _selectedSports.remove(sport.name);
                                }
                              });
                            },
                            selectedColor: primaryColor.withOpacity(0.15),
                            checkmarkColor: primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? primaryColor : theme.textTheme.bodyLarge?.color,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: cs.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? primaryColor : Colors.transparent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    // ── Theme Toggle ────────────────────────────────────────
                    Consumer(builder: (context, ref, _) {
                      final themeMode = ref.watch(themeModeProvider);
                      final isDark = themeMode == ThemeMode.dark ||
                          (themeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness == Brightness.dark);
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outline),
                        ),
                        child: SwitchListTile(
                          title: Text('Dark Mode',
                              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                          subtitle: Text(isDark ? 'Currently using dark theme' : 'Currently using light theme',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                          secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                              color: isDark ? primaryColor : cs.onSurfaceVariant),
                          value: isDark,
                          activeColor: primaryColor,
                          onChanged: (val) {
                            ref.read(themeModeProvider.notifier).setThemeMode(
                                val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
