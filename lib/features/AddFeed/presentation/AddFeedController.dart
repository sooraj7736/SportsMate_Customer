import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/AddFeed_repository.dart';
import '../domain/AddFeed_entity.dart';

class AddFeedState {
  final bool isLoading;
  final File? image;
  final String visibility;

  AddFeedState({
    this.isLoading = false,
    this.image,
    this.visibility = "Everyone",
  });

  AddFeedState copyWith({
    bool? isLoading,
    File? image,
    String? visibility,
  }) {
    return AddFeedState(
      isLoading: isLoading ?? this.isLoading,
      image: image ?? this.image,
      visibility: visibility ?? this.visibility,
    );
  }
}

final addFeedControllerProvider = StateNotifierProvider<AddFeedController, AddFeedState>((ref) {
  return AddFeedController(ref);
});

class AddFeedController extends StateNotifier<AddFeedState> {
  final Ref _ref;
  late AddFeedRepository _repository;

  AddFeedController(this._ref) : super(AddFeedState()) {
    _repository = _ref.read(addFeedRepositoryProvider);
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      state = state.copyWith(image: File(pickedFile.path));
    }
  }

  void removeImage() {
    state = state.copyWith(image: null);
  }

  void setVisibility(String visibility) {
    state = state.copyWith(visibility: visibility);
  }

  Future<bool> postFeed(String content) async {
    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final newFeed = FeedEntity(
        id: '',
        uid: userProfile.uid,
        username: userProfile.name,
        userProfileImage: userProfile.profilePic ?? 'https://i.pravatar.cc/150?u=${userProfile.uid}',
        title: '',
        description: content.trim(),
        mediaUrl: state.image?.path ?? '',
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
