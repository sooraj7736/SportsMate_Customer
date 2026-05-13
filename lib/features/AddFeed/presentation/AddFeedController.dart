import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/AddFeed_repository.dart';
import '../domain/AddFeed_entity.dart';

import 'package:firebase_auth/firebase_auth.dart';

class AddFeedState {
  final bool isLoading;
  final File? profileFile;
  final String visibility;

  AddFeedState({
    this.isLoading = false,
    this.profileFile,
    this.visibility = "Everyone",
  });

  AddFeedState copyWith({
    bool? isLoading,
    File? profileFile,
    String? visibility,
  }) {
    return AddFeedState(
      isLoading: isLoading ?? this.isLoading,
      profileFile: profileFile ?? this.profileFile,
      visibility: visibility ?? this.visibility,
    );
  }
}

final addFeedControllerProvider = NotifierProvider<AddFeedController, AddFeedState>(() {
  return AddFeedController();
});

class AddFeedController extends Notifier<AddFeedState> {
  late AddFeedRepository _repository;

  @override
  AddFeedState build() {
    _repository = ref.read(addFeedRepositoryProvider);
    return AddFeedState();
  }

  void removeImage() {
    state = state.copyWith(profileFile: null);
  }

  void setVisibility(String visibility) {
    state = state.copyWith(visibility: visibility);
  }

  Future<bool> postFeed(String content) async {
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      String mediaUrl = '';
      if (state.profileFile != null) {
        mediaUrl = await _repository.uploadFeedImage(
          userProfile.uid,
          state.profileFile!,
        );
      }

      final newFeed = FeedEntity(
        id: '',
        uid: userProfile.uid,
        username: userProfile.name,
        userProfileImage: userProfile.profilePic ?? 'https://i.pravatar.cc/150?u=${userProfile.uid}',
        title: '',
        description: content.trim(),
        mediaUrl: mediaUrl,
        date: DateTime.now(),
        likes: [],
      );

      await _repository.addFeed(newFeed);
      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
