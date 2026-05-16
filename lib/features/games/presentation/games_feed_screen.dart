import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'games_feed_controller.dart';
import 'add_game_screen.dart';

class GamesFeedScreen extends ConsumerWidget {
  const GamesFeedScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesStream = ref.watch(allGamesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Find Games",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Let's Go Game Around",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          gamesStream.when(
            data: (gamesList) {
              if (gamesList.isEmpty) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Text(
                      "No matches yet. Be the first to add a game!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 72, 14, 16),
                itemCount: gamesList.length,
                itemBuilder: (context, index) {
                  final game = gamesList[index];
                  final isPublic = game.gameAccess == 'Public';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.sports_soccer, size: 18, color: _primaryGreen),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${game.hostName}'s ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "${game.sportType} game",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                      TextSpan(
                                        text: " at ${game.locationName}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPublic ? Colors.blue[50] : Colors.amber[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  game.gameAccess,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isPublic ? Colors.blue[700] : Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  game.locationName,
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('EEE, MMM d').format(game.date),
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const Spacer(),
                              Text(
                                "${game.numberOfPlayers} slots",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _primaryGreen,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (game.startTime.isNotEmpty && game.endTime.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.black45),
                                const SizedBox(width: 6),
                                Text(
                                  "${_formatStoredTime(game.startTime)} - ${_formatStoredTime(game.endTime)}",
                                  style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: Colors.black45),
                              const SizedBox(width: 6),
                              Text(
                                game.hostName,
                                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                              ),
                            ],
                          ),
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
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: Colors.transparent,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddGameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0x40000000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Add Games",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatStoredTime(String value) {
    try {
      final parsed = DateFormat('HH:mm').parse(value);
      return DateFormat.jm().format(parsed);
    } catch (_) {
      return value;
    }
  }
}