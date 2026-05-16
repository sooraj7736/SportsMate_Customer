import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/games_repository.dart';
import '../domain/game_entity.dart';

// Automatically feeds real-time updates from Firestore straight into your UI list view
final allGamesStreamProvider = StreamProvider<List<GameEntity>>((ref) {
  return ref.watch(gamesRepositoryProvider).watchAllGames();
});