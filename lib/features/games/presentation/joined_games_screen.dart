import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/game_entity.dart';
import 'games_feed_controller.dart';

class JoinedGamesScreen extends ConsumerWidget {
  const JoinedGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final joinedGamesAsync = ref.watch(joinedGamesProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    return joinedGamesAsync.when(
        data: (games) {
          if (games.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  'You haven\'t joined any games yet.\nExplore and join a game!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _JoinedGameCard(
                game: game,
                currentUserId: currentUserId ?? '',
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading games: $err', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        ),
      );
  }
}

class _JoinedGameCard extends StatelessWidget {
  final GameEntity game;
  final String currentUserId;

  const _JoinedGameCard({
    required this.game,
    required this.currentUserId,
  });

  static const Color _primaryGreen = Color(0xFF1DB954);

  static String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  static void _showParticipantsModal(BuildContext context, GameEntity game) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ParticipantsBottomSheet(game: game),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    final guestCount = game.joinedPlayers
        .where((p) => p.uid == currentUserId && p.isGuest)
        .length;

    final participantSummary = guestCount > 0 ? 'You + $guestCount guest${guestCount != 1 ? 's' : ''}' : 'You';

    final gameDateTime = DateTime(
      game.date.year,
      game.date.month,
      game.date.day,
    );

    return Card(
      elevation: 0,
      color: cardTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${game.hostName}\'s ${game.sportType} Game',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: cardTheme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        game.locationName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: cardTheme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Attending',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: cardTheme.iconTheme.color),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(gameDateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: cardTheme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 16, color: cardTheme.iconTheme.color),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(game.startTime)} - ${_formatTime(game.endTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cardTheme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showParticipantsModal(context, game),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardTheme.colorScheme.secondaryContainer.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryGreen.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: _primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(participantSummary, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cardTheme.textTheme.bodyMedium?.color))),
                    const Icon(Icons.chevron_right, size: 16, color: _primaryGreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsBottomSheet extends StatelessWidget {
  final GameEntity game;

  const _ParticipantsBottomSheet({required this.game});

  static const Color _primaryGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: game.joinedPlayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final participant = game.joinedPlayers[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            participant.isGuest ? Icons.person_outline : Icons.person,
                            size: 18,
                            color: _primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              participant.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (participant.isGuest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Guest',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
