import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tournament_entity.dart';
import '../../data/football_live_score_repository.dart';

class ViewFootballLiveScoreScreen extends ConsumerWidget {
  final TournamentEntity tournament;

  const ViewFootballLiveScoreScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final liveScoreAsync = ref.watch(footballLiveScoreStreamProvider(tournament.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Football Live Score')),
      body: liveScoreAsync.when(
        data: (liveScore) {
          if (liveScore == null) {
            return const Center(
              child: Text('No live score has been posted yet.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              liveScore.matchStatus,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FootballSpectatorTimer(
                          timerStartedAt: liveScore.timerStartedAt,
                          timerAccumulatedSeconds: liveScore.timerAccumulatedSeconds,
                          isTimerRunning: liveScore.isTimerRunning,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(liveScore.hostTeamName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(liveScore.hostTeamScore.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text('vs', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(liveScore.guestTeamName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(liveScore.guestTeamScore.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (liveScore.note != null && liveScore.note!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match Note',
                                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.primary, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                liveScore.note!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (liveScore.foulEvents.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _IncidentSummary(events: liveScore.foulEvents),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Incidents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 10),
                            Column(
                              children: liveScore.foulEvents.map((event) => _IncidentCard(event: event)).toList(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Updated by ${liveScore.updatedByName}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load live score: $err')),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final String event;

  const _IncidentCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parts = event.split(' • ');
    int offset = 0;
    String minutePrefix = '';
    if (parts.isNotEmpty && parts[0].endsWith("'")) {
      minutePrefix = parts[0];
      offset = 1;
    }

    final incidentType = parts.length > offset ? parts[offset] : 'Incident';
    final teamName = parts.length > offset + 1 ? parts[offset + 1] : '';
    final playerName = parts.length > offset + 2 ? parts[offset + 2] : '';
    final extraNote = parts.length > offset + 3 ? parts.sublist(offset + 3).join(' • ') : '';

    final lowerType = incidentType.toLowerCase();
    final isRed = lowerType.contains('red');
    final isYellow = lowerType.contains('yellow');
    final isPenalty = lowerType.contains('penalty');

    final backgroundColor = isRed
      ? colorScheme.errorContainer
      : isYellow
        ? colorScheme.secondaryContainer
        : isPenalty
          ? colorScheme.tertiaryContainer
          : colorScheme.primaryContainer;
    final accentColor = isRed
      ? colorScheme.error
      : isYellow
        ? colorScheme.secondary
        : isPenalty
          ? colorScheme.tertiary
          : colorScheme.primary;
    final foregroundColor = isRed
      ? colorScheme.onErrorContainer
      : isYellow
        ? colorScheme.onSecondaryContainer
        : isPenalty
          ? colorScheme.onTertiaryContainer
          : colorScheme.onPrimaryContainer;
    final icon = isRed
        ? Icons.stop_circle_outlined
        : isYellow
            ? Icons.rectangle_outlined
            : isPenalty
                ? Icons.sports_soccer
                : Icons.rule;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        minutePrefix.isNotEmpty ? "$minutePrefix • $incidentType" : incidentType,
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: foregroundColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 8),
                if (teamName.isNotEmpty || playerName.isNotEmpty)
                  Text(
                    [if (playerName.isNotEmpty) playerName, if (teamName.isNotEmpty) teamName]
                        .join(' • ')
                        .trim(),
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: foregroundColor),
                  ),
                if (extraNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: foregroundColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          extraNote,
                          style: theme.textTheme.bodySmall?.copyWith(color: foregroundColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentSummary extends StatelessWidget {
  final List<String> events;

  const _IncidentSummary({required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summaryForeground = colorScheme.onSecondaryContainer;
    // Parse incidents by team
    final cardsByTeam = <String, Map<String, int>>{};
    
    for (final event in events) {
      final parts = event.split(' • ');
      int offset = 0;
      if (parts.isNotEmpty && parts[0].endsWith("'")) {
        offset = 1;
      }
      if (parts.length >= offset + 2) {
        final incidentType = parts[offset].toLowerCase();
        final teamName = parts[offset + 1];
        
        if (!cardsByTeam.containsKey(teamName)) {
          cardsByTeam[teamName] = {'yellow': 0, 'red': 0, 'total': 0};
        }
        
        if (incidentType.contains('yellow')) {
          cardsByTeam[teamName]!['yellow'] = cardsByTeam[teamName]!['yellow']! + 1;
        } else if (incidentType.contains('red')) {
          cardsByTeam[teamName]!['red'] = cardsByTeam[teamName]!['red']! + 1;
        }
        cardsByTeam[teamName]!['total'] = cardsByTeam[teamName]!['total']! + 1;
      }
    }

    if (cardsByTeam.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foul/Incident Summary',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: summaryForeground, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: cardsByTeam.entries.map((entry) {
              final teamName = entry.key;
              final stats = entry.value;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13, color: summaryForeground),
                    ),
                    const SizedBox(width: 10),
                    if (stats['yellow']! > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🟨 ${stats['yellow']}',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: summaryForeground, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (stats['red']! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🟥 ${stats['red']}',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class FootballSpectatorTimer extends StatefulWidget {
  final DateTime? timerStartedAt;
  final int timerAccumulatedSeconds;
  final bool isTimerRunning;

  const FootballSpectatorTimer({
    super.key,
    required this.timerStartedAt,
    required this.timerAccumulatedSeconds,
    required this.isTimerRunning,
  });

  @override
  State<FootballSpectatorTimer> createState() => _FootballSpectatorTimerState();
}

class _FootballSpectatorTimerState extends State<FootballSpectatorTimer> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    if (widget.isTimerRunning) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant FootballSpectatorTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timerStartedAt != oldWidget.timerStartedAt ||
        widget.timerAccumulatedSeconds != oldWidget.timerAccumulatedSeconds ||
        widget.isTimerRunning != oldWidget.isTimerRunning) {
      _updateTime();
      if (widget.isTimerRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _updateTime() {
    if (widget.isTimerRunning && widget.timerStartedAt != null) {
      final diff = DateTime.now().difference(widget.timerStartedAt!).inSeconds;
      _elapsedSeconds = (widget.timerAccumulatedSeconds + diff).clamp(0, 7200);
    } else {
      _elapsedSeconds = widget.timerAccumulatedSeconds.clamp(0, 7200);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isTimerRunning ? Colors.greenAccent.shade400 : Colors.redAccent.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isTimerRunning ? Colors.greenAccent : Colors.redAccent).withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isTimerRunning ? Colors.greenAccent : Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: widget.isTimerRunning ? Colors.greenAccent : Colors.redAccent,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.isTimerRunning ? 'LIVE' : 'PAUSED',
            style: TextStyle(
              color: widget.isTimerRunning ? Colors.greenAccent : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}