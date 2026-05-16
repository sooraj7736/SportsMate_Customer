import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'games_feed_controller.dart';
import 'add_game_screen.dart';

class GamesFeedScreen extends ConsumerWidget {
  const GamesFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesStream = ref.watch(allGamesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Available Matches", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 28, color: Color(0xFF1DB954)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddGameScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: gamesStream.when(
        data: (gamesList) {
          if (gamesList.isEmpty) {
            return const Center(child: Text("No upcoming matches hosted yet. Be the first!"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: gamesList.length,
            itemBuilder: (context, index) {
              final game = gamesList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14.0),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(game.sportType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: game.gameAccess == 'Public' ? Colors.blue[50] : Colors.amber[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(game.gameAccess, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: game.gameAccess == 'Public' ? Colors.blue : Colors.amber[800])),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text("📍 Location: ${game.locationName}", style: const TextStyle(color: Colors.black87)),
                      Text("🗓️ Date: ${DateFormat('yMMMd').format(game.date)}", style: const TextStyle(color: Colors.grey)),
                      Text("👤 Host: ${game.hostName}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${game.numberOfPlayers}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1DB954))),
                      const Text("Slots", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error fetching games: $err")),
      ),
    );
  }
}