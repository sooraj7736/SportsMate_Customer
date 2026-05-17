import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown.dart';
import '../../../core/widgets/location_picker.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final sportsController = TextEditingController();
  final addressNameController = TextEditingController();
  final addressTextController = TextEditingController();
  
  String selectedSkill = "Beginner";
  final List<String> skillLevels = ["Beginner", "Intermediate", "Pro"];
  File? _image;
  Timer? _debounce;
  
  double? _selectedLat;
  double? _selectedLng;

  @override
  void dispose() {
    _debounce?.cancel();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    sportsController.dispose();
    addressNameController.dispose();
    addressTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(authControllerProvider.notifier).checkUsername(value);
    });
  }

  void _handleSignUp() async {
    final registerState = ref.read(authControllerProvider);
    
    if (!registerState.isUsernameUnique || usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a valid unique username.')),
      );
      return;
    }

    final sportsList = sportsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sportsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one interested game.')),
      );
      return;
    }

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location on the map.')),
      );
      return;
    }

    if (addressNameController.text.trim().isEmpty || addressTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address name and details.')),
      );
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        username: usernameController.text.trim(),
        selectedSports: sportsList,
        skillLevel: selectedSkill,
        addressName: addressNameController.text.trim(),
        addressText: addressTextController.text.trim(),
        lat: _selectedLat!,
        lng: _selectedLng!,
        profileFile: _image,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Athlete Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              controller: nameController,
              label: "Full Name",
              icon: Icons.person_outline,
            ),
            
            CustomTextField(
              controller: usernameController, 
              label: "Username", 
              icon: Icons.alternate_email,
              onChanged: _onUsernameChanged,
              errorText: registerState.usernameError,
              suffixIcon: registerState.isCheckingUsername 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (usernameController.text.isNotEmpty && registerState.isUsernameUnique)
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            
            if (registerState.suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Wrap(
                  spacing: 8.0,
                  children: registerState.suggestions.map((s) => ActionChip(
                    label: Text(s),
                    onPressed: () {
                      usernameController.text = s;
                      ref.read(authControllerProvider.notifier).checkUsername(s);
                    },
                  )).toList(),
                ),
              ),

            CustomTextField(
              controller: emailController,
              label: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            
            CustomTextField(
              controller: passwordController,
              label: "Password",
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            
            CustomTextField(
              controller: sportsController, 
              label: "Interested Games (comma separated)", 
              icon: Icons.sports_tennis,
            ),
            
            const SizedBox(height: 10),
            CustomTextField(
              controller: addressNameController, 
              label: "Address Label (e.g. Home, Work)", 
              icon: Icons.label_outline,
            ),
            
            CustomTextField(
              controller: addressTextController, 
              label: "Address Details", 
              icon: Icons.location_city_outlined,
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPicker(
                      onLocationSelected: (lat, lng) {
                        setState(() {
                          _selectedLat = lat;
                          _selectedLng = lng;
                        });
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: Text(_selectedLat != null ? "Location Selected on Map" : "Pick Location on Map"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedLat != null ? Colors.green : Colors.grey[200],
                foregroundColor: _selectedLat != null ? Colors.white : Colors.black87,
                elevation: 0,
              ),
            ),

            const SizedBox(height: 10),
            CustomDropdown<String>(
              label: "Select Skill Level",
              value: selectedSkill,
              items: skillLevels,
              onChanged: (val) => setState(() => selectedSkill = val!),
            ),

            const SizedBox(height: 30),

            registerState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Join the Community", style: TextStyle(fontSize: 16)),
                ),
            
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("Already a user? Please login", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}