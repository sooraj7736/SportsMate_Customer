import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/common_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/athlete_entity.dart';

class RegisterState {
  final bool isLoading;
  final bool isCheckingUsername;
  final bool isUsernameUnique;
  final String? usernameError;
  final List<String> suggestions;

  RegisterState({
    this.isLoading = false,
    this.isCheckingUsername = false,
    this.isUsernameUnique = true,
    this.usernameError,
    this.suggestions = const [],
  });

  RegisterState copyWith({
    bool? isLoading,
    bool? isCheckingUsername,
    bool? isUsernameUnique,
    String? usernameError,
    List<String>? suggestions,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingUsername: isCheckingUsername ?? this.isCheckingUsername,
      isUsernameUnique: isUsernameUnique ?? this.isUsernameUnique,
      usernameError: usernameError, 
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

final userProfileProvider = FutureProvider<Athlete?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).getAthleteProfile(user.uid);
});

final authControllerProvider = NotifierProvider<AuthController, RegisterState>(() {
  return AuthController();
});

class AuthController extends Notifier<RegisterState> {
  late FirebaseAuth _auth;
  late ProfileRepository _profileRepository;

  @override
  RegisterState build() {
    _auth = ref.watch(firebaseAuthProvider);
    _profileRepository = ref.read(profileRepositoryProvider);
    return RegisterState();
  }

  Future<void> checkUsername(String username) async {
    if (username.isEmpty) {
      state = state.copyWith(
        isCheckingUsername: false,
        isUsernameUnique: true,
        usernameError: null,
        suggestions: [],
      );
      return;
    }

    final validCharacters = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validCharacters.hasMatch(username)) {
      state = state.copyWith(
        isCheckingUsername: false,
        isUsernameUnique: false,
        usernameError: 'Only letters, numbers and underscores allowed.',
        suggestions: [],
      );
      return;
    }

    state = state.copyWith(isCheckingUsername: true, usernameError: null);

    try {
      final isUnique = await _profileRepository.isUsernameUnique(username);
      List<String> suggestions = [];
      if (!isUnique) {
        suggestions = await _profileRepository.getUsernameSuggestions(username);
      }

      state = state.copyWith(
        isCheckingUsername: false,
        isUsernameUnique: isUnique,
        usernameError: isUnique ? null : 'Username is already taken.',
        suggestions: suggestions,
      );
    } catch (e) {
      state = state.copyWith(isCheckingUsername: false);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
    required List<String> selectedSports,
    required String skillLevel,
    File? profileFile,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? profilePicUrl;
      if (profileFile != null) {
        profilePicUrl = await _profileRepository.uploadProfileImage(
          credential.user!.uid,
          profileFile,
        );
      }

      await credential.user?.sendEmailVerification();

      final athlete = Athlete(
        uid: credential.user!.uid,
        username: username,
        name: name,
        email: email,
        favoriteSports: selectedSports,
        skillLevel: skillLevel,
        profilePic: profilePicUrl,
      );

      await _profileRepository.saveAthleteProfile(athlete);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}