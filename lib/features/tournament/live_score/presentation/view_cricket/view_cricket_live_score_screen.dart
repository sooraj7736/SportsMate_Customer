import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tournament_entity.dart';
import '../../data/cricket_live_score_repository.dart';

class ViewCricketLiveScoreScreen extends ConsumerWidget {
  final TournamentEntity tournament;

  const ViewCricketLiveScoreScreen({super.key, required this.tournament});

  double _calculateEconomy(int runsConceded, double oversBowled) {
    final completedOvers = oversBowled.floor();
    final extraBalls = ((oversBowled - completedOvers) * 10).round();
    final totalBalls = completedOvers * 6 + extraBalls;
    if (totalBalls == 0) return 0.0;
    return runsConceded / (totalBalls / 6.0);
  }

  double _calculateSR(int runs, int balls) {
    if (balls == 0) return 0.0;
    return (runs / balls) * 100;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final liveScoreAsync = ref.watch(cricketLiveScoreStreamProvider(tournament.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Live Score'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: liveScoreAsync.when(
          data: (liveScore) {
            if (liveScore == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No live score has been posted yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            final showBatsmen = liveScore.batsman1Name != null || liveScore.batsman2Name != null;
            final showBowler = liveScore.bowlerName != null;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Giant Score Dashboard ---
                Card(
                  elevation: 4,
                  color: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sports_cricket, color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                liveScore.matchStatus,
                                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    liveScore.battingTeamName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${liveScore.runs}/${liveScore.wickets}',
                                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${liveScore.overs}.${liveScore.balls} ov)',
                                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'BOWLING',
                                  style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  liveScore.bowlingTeamName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Timeline (This over)
                        if (liveScore.recentBalls.isNotEmpty) ...[
                          const Divider(height: 28, color: Colors.white24),
                          Row(
                            children: [
                              const Text(
                                'This Over: ',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  children: liveScore.recentBalls.map((ball) {
                                    final isWicket = ball == 'W';
                                    final isBoundary = ball == '4' || ball == '6';
                                    final isExtra = ball.contains('wd') || ball.contains('nb');

                                    Color bg = colorScheme.onPrimary.withValues(alpha: 0.12);
                                    Color txt = colorScheme.onPrimary;

                                    if (isWicket) {
                                      bg = colorScheme.error;
                                    } else if (isBoundary) {
                                      bg = colorScheme.secondary;
                                      txt = colorScheme.primary;
                                    } else if (isExtra) {
                                      bg = colorScheme.primary;
                                    }
                                    
                                    return Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: bg,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        ball,
                                        style: TextStyle(color: txt, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Live Batsmen Card ---
                if (showBatsmen) ...[
                  Card(
                    elevation: 0,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sports_cricket, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Batsmen', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          
                          // Header row
                          Row(
                            children: [
                                  const Expanded(
                                flex: 4,
                                child: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          // Batsman 1
                          if (liveScore.batsman1Name != null)
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      Text(
                                        liveScore.batsman1Name!,
                                        style: TextStyle(
                                          fontWeight: liveScore.batsman1OnStrike ? FontWeight.w900 : FontWeight.w600,
                                          color: liveScore.batsman1OnStrike ? colorScheme.primary : theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      if (liveScore.batsman1OnStrike)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Text('🏏', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      liveScore.batsman1Runs.toString(),
                                      style: TextStyle(fontWeight: liveScore.batsman1OnStrike ? FontWeight.bold : FontWeight.normal, color: theme.textTheme.bodyLarge?.color),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(liveScore.batsman1Balls.toString()),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(_calculateSR(liveScore.batsman1Runs, liveScore.batsman1Balls).toStringAsFixed(1)),
                                  ),
                                ),
                              ],
                            ),
                          
                          if (liveScore.batsman1Name != null && liveScore.batsman2Name != null)
                            const SizedBox(height: 12),

                          // Batsman 2
                          if (liveScore.batsman2Name != null)
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      Text(
                                        liveScore.batsman2Name!,
                                        style: TextStyle(
                                          fontWeight: !liveScore.batsman1OnStrike ? FontWeight.w900 : FontWeight.w600,
                                          color: !liveScore.batsman1OnStrike ? Colors.teal.shade900 : Colors.black87,
                                        ),
                                      ),
                                      if (!liveScore.batsman1OnStrike)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Text('🏏', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      liveScore.batsman2Runs.toString(),
                                      style: TextStyle(fontWeight: !liveScore.batsman1OnStrike ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(liveScore.batsman2Balls.toString()),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: Text(_calculateSR(liveScore.batsman2Runs, liveScore.batsman2Balls).toStringAsFixed(1)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Live Bowler Card ---
                if (showBowler) ...[
                  Card(
                    elevation: 0,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sports_cricket_outlined, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Bowler', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Header row
                          Row(
                            children: [
                              const Expanded(
                                flex: 4,
                                child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Text('Econ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  liveScore.bowlerName!,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(liveScore.bowlerOvers.toStringAsFixed(1)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(liveScore.bowlerRuns.toString()),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    liveScore.bowlerWickets.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(_calculateEconomy(liveScore.bowlerRuns, liveScore.bowlerOvers).toStringAsFixed(2)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Live Commentary / Note Card ---
                if (liveScore.note != null && liveScore.note!.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.comment, color: colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Match Commentary / Note',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            liveScore.note!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Footer metadata ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: theme.iconTheme.color),
                      const SizedBox(width: 4),
                      Text('Updated by ${liveScore.updatedByName}', style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color)),
                      const Spacer(),
                      Icon(Icons.update, size: 14, color: theme.iconTheme.color),
                      const SizedBox(width: 4),
                      Text('Auto-refreshed live', style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color)),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          error: (err, stack) => Center(child: Text('Failed to load live score: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}
