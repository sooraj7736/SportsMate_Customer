import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tournament_entity.dart';
import '../../data/basketball_live_score_repository.dart';

class ViewBasketballLiveScoreScreen extends ConsumerWidget {
  final TournamentEntity tournament;

  const ViewBasketballLiveScoreScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveScoreAsync = ref.watch(basketballLiveScoreStreamProvider(tournament.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Basketball Live Score')),
      body: liveScoreAsync.when(
        data: (liveScore) {
          if (liveScore == null) {
            return const Center(
              child: Text('No live score has been posted yet.'),
            );
          }

          final hostBonus = liveScore.hostTeamFouls >= 5;
          final guestBonus = liveScore.guestTeamFouls >= 5;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 6,
                color: const Color(0xFF0F0F0F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.orange.shade800.withOpacity(0.3), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_basketball, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              liveScore.matchStatus,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              liveScore.currentQuarter == 5 ? 'Overtime' : 'Quarter ${liveScore.currentQuarter}',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: BasketballSpectatorTimer(
                          timerStartedAt: liveScore.timerStartedAt,
                          timerAccumulatedSeconds: liveScore.timerAccumulatedSeconds,
                          isTimerRunning: liveScore.isTimerRunning,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  liveScore.hostTeamName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  liveScore.hostTeamScore.toString(),
                                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Fouls: ${liveScore.hostTeamFouls}',
                                      style: TextStyle(
                                        color: hostBonus ? Colors.redAccent : Colors.white60,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (hostBonus) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('BONUS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'VS',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orangeAccent, fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  liveScore.guestTeamName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  liveScore.guestTeamScore.toString(),
                                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Fouls: ${liveScore.guestTeamFouls}',
                                      style: TextStyle(
                                        color: guestBonus ? Colors.redAccent : Colors.white60,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (guestBonus) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('BONUS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (liveScore.note != null && liveScore.note!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade900.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade800.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match Note',
                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange.shade400, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                liveScore.note!,
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (liveScore.foulEvents.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Match Commentary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: liveScore.foulEvents.reversed.map((event) => _IncidentCard(event: event)).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Last updated by ${liveScore.updatedByName}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load score: $err')),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final String event;

  const _IncidentCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final parts = event.split(' • ');
    int offset = 0;
    String timePrefix = '';
    if (parts.isNotEmpty && (parts[0].startsWith('Q') || parts[0].startsWith('OT'))) {
      timePrefix = parts[0];
      offset = 1;
    }

    final playType = parts.length > offset ? parts[offset] : 'Play';
    final teamName = parts.length > offset + 1 ? parts[offset + 1] : '';
    final playerName = parts.length > offset + 2 ? parts[offset + 2] : '';
    final extraNote = parts.length > offset + 3 ? parts.sublist(offset + 3).join(' • ') : '';

    final playLower = playType.toLowerCase();
    final isThree = playLower.contains('3 pointer');
    final isTwo = playLower.contains('2 points') || playLower.contains('field goal');
    final isOne = playLower.contains('free throw') || playLower.contains('1 point');
    final isFoul = playLower.contains('foul');

    final backgroundColor = isThree
        ? const Color(0xFF1E0E00).withOpacity(0.6)
        : isFoul
            ? const Color(0xFF1E0000).withOpacity(0.4)
            : Colors.grey.shade900.withOpacity(0.5);

    final accentColor = isThree
        ? Colors.orange.shade400
        : isFoul
            ? Colors.redAccent
            : Colors.white70;

    final icon = isThree || isTwo || isOne
        ? Icons.sports_basketball
        : isFoul
            ? Icons.warning_amber
            : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      playType,
                      style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 13),
                    ),
                    if (timePrefix.isNotEmpty)
                      Text(
                        timePrefix,
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$playerName ($teamName)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (extraNote.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    extraNote,
                    style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
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

class BasketballSpectatorTimer extends StatefulWidget {
  final DateTime? timerStartedAt;
  final int timerAccumulatedSeconds;
  final bool isTimerRunning;

  const BasketballSpectatorTimer({
    super.key,
    required this.timerStartedAt,
    required this.timerAccumulatedSeconds,
    required this.isTimerRunning,
  });

  @override
  State<BasketballSpectatorTimer> createState() => _BasketballSpectatorTimerState();
}

class _BasketballSpectatorTimerState extends State<BasketballSpectatorTimer> {
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
  void didUpdateWidget(covariant BasketballSpectatorTimer oldWidget) {
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
      _elapsedSeconds = (widget.timerAccumulatedSeconds + diff).clamp(0, 3600);
    } else {
      _elapsedSeconds = widget.timerAccumulatedSeconds.clamp(0, 3600);
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
          color: widget.isTimerRunning ? Colors.orangeAccent : Colors.redAccent.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isTimerRunning ? Colors.orangeAccent : Colors.redAccent).withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.isTimerRunning ? Colors.orangeAccent : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
