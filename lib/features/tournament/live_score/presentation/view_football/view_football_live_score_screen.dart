import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tournament_entity.dart';
import '../../data/football_live_score_repository.dart';

class ViewFootballLiveScoreScreen extends ConsumerWidget {
  final TournamentEntity tournament;

  const ViewFootballLiveScoreScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      if (liveScore.minute != null) ...[
                        const SizedBox(height: 16),
                        Text('Minute: ${liveScore.minute}'),
                      ],
                      if (liveScore.note != null && liveScore.note!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match Note',
                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blue.shade800, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                liveScore.note!,
                                style: const TextStyle(fontSize: 14),
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
    final parts = event.split(' • ');
    final incidentType = parts.isNotEmpty ? parts[0] : 'Incident';
    final teamName = parts.length > 1 ? parts[1] : '';
    final playerName = parts.length > 2 ? parts[2] : '';
    final extraNote = parts.length > 3 ? parts.sublist(3).join(' • ') : '';

    final lowerType = incidentType.toLowerCase();
    final isRed = lowerType.contains('red');
    final isYellow = lowerType.contains('yellow');
    final isPenalty = lowerType.contains('penalty');

    final backgroundColor = isRed
        ? Colors.red.shade50
        : isYellow
            ? Colors.amber.shade50
            : isPenalty
                ? Colors.green.shade50
                : Colors.blue.shade50;
    final accentColor = isRed
        ? Colors.red.shade700
        : isYellow
            ? Colors.amber.shade800
            : isPenalty
                ? Colors.green.shade700
                : Colors.blue.shade700;
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
        border: Border.all(color: accentColor.withOpacity(0.18)),
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
            child: Icon(icon, color: Colors.white),
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
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        incidentType,
                        style: TextStyle(fontWeight: FontWeight.w700, color: accentColor, fontSize: 12),
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                if (extraNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          extraNote,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
    // Parse incidents by team
    final cardsByTeam = <String, Map<String, int>>{};
    
    for (final event in events) {
      final parts = event.split(' • ');
      if (parts.length >= 2) {
        final incidentType = parts[0].toLowerCase();
        final teamName = parts[1];
        
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foul/Incident Summary',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange.shade800, fontSize: 12),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    if (stats['yellow']! > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🟨 ${stats['yellow']}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade900, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (stats['red']! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🟥 ${stats['red']}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red.shade900, fontSize: 12),
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