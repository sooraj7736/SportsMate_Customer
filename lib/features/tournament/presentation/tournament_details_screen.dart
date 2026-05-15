import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/tournament/domain/tournament_entity.dart';
import 'package:sportsmate/features/tournament/data/tournament_repository.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:intl/intl.dart';

class TournamentDetailsScreen extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const TournamentDetailsScreen({super.key, required this.tournament});

  @override
  ConsumerState<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends ConsumerState<TournamentDetailsScreen> {
  bool _isGeneratingFixtures = false;

  void _generateFixtures() async {
    final t = widget.tournament;
    if (t.registeredTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Need at least 2 teams to set fixtures.")));
      return;
    }

    setState(() {
      _isGeneratingFixtures = true;
    });

    try {
      final List<Map<String, dynamic>> shuffledTeams = List.from(t.registeredTeams)..shuffle();
      final List<Map<String, dynamic>> newFixtures = [];

      for (int i = 0; i < shuffledTeams.length; i += 2) {
        if (i + 1 < shuffledTeams.length) {
          newFixtures.add({
            'team1': shuffledTeams[i]['teamName'] ?? 'Unknown Team',
            'team2': shuffledTeams[i + 1]['teamName'] ?? 'Unknown Team',
            'matchNumber': (i ~/ 2) + 1,
            'status': 'Upcoming',
          });
        } else {
          // Odd number of teams, last gets a bye
          newFixtures.add({
            'team1': shuffledTeams[i]['teamName'] ?? 'Unknown Team',
            'team2': 'BYE',
            'matchNumber': (i ~/ 2) + 1,
            'status': 'Upcoming',
          });
        }
      }

      await ref.read(tournamentRepositoryProvider).updateTournamentFixtures(t.id, newFixtures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fixtures generated successfully!")));
        Navigator.pop(context); // Go back or reload data. Better to pop or wait for stream to update.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating fixtures: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingFixtures = false;
        });
      }
    }
  }

  void _showJoinDialog() {
    final teamNameController = TextEditingController();
    final playersController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Join Tournament"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teamNameController,
                  decoration: const InputDecoration(labelText: "Team Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: playersController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: "Player Names (Comma separated)", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (teamNameController.text.trim().isEmpty) return;

                final userProfile = ref.read(userProfileProvider).value;
                if (userProfile == null) return;

                final players = playersController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                final teamData = {
                  'teamName': teamNameController.text.trim(),
                  'captainUid': userProfile.uid,
                  'captainName': userProfile.name,
                  'players': players,
                };

                try {
                  await ref.read(tournamentRepositoryProvider).joinTournament(widget.tournament.id, teamData);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully joined tournament!")));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error joining: $e")));
                  }
                }
              },
              child: const Text("Join"),
            ),
          ],
        );
      },
    );
  }

  void _editFixtures() {
    List<Map<String, dynamic>> editedFixtures = List.from(widget.tournament.fixtures.map((e) => Map<String, dynamic>.from(e)));
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Fixtures"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: editedFixtures.map((fixture) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Match ${fixture['matchNumber']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: fixture['team1'],
                                    items: widget.tournament.registeredTeams.map((t) => t['teamName'].toString()).followedBy(['BYE']).map((t) {
                                      return DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis));
                                    }).toList(),
                                    onChanged: (val) {
                                      setDialogState(() => fixture['team1'] = val);
                                    },
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("VS")),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: fixture['team2'],
                                    items: widget.tournament.registeredTeams.map((t) => t['teamName'].toString()).followedBy(['BYE']).map((t) {
                                      return DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis));
                                    }).toList(),
                                    onChanged: (val) {
                                      setDialogState(() => fixture['team2'] = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(tournamentRepositoryProvider).updateTournamentFixtures(widget.tournament.id, editedFixtures);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fixtures updated successfully!")));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final userProfile = ref.watch(userProfileProvider).value;
    final isHost = userProfile?.uid == t.hostUid;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.tournamentName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.posterUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(t.posterUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(t.tournamentName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Hosted by ${t.hostName}", style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            const Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sports),
              title: Text("Sport: ${t.sport}"),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text("${DateFormat('MMM dd').format(t.startDate)} - ${DateFormat('MMM dd, yyyy').format(t.endDate)}"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(t.location),
            ),
            if (t.registrationFee > 0)
              ListTile(
                leading: const Icon(Icons.money),
                title: Text("Entry Fee: ₹${t.registrationFee}"),
              ),
            if (t.prizePool.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text("Prize Pool: ${t.prizePool}"),
              ),
            const SizedBox(height: 16),

            // Teams Section
            const Text("Registered Teams", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (t.registeredTeams.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No teams registered yet."),
              )
            else
              ...t.registeredTeams.map((team) {
                final players = (team['players'] as List<dynamic>?) ?? [];
                return ExpansionTile(
                  title: Text(team['teamName'] ?? 'Unknown Team', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Captain: ${team['captainName'] ?? 'Unknown'}"),
                  children: players.isEmpty
                      ? [const ListTile(title: Text("No players listed."))]
                      : players.map((p) => ListTile(leading: const Icon(Icons.person, size: 20), title: Text(p.toString()))).toList(),
                );
              }),

            const SizedBox(height: 24),

            // Fixtures Section
            if (t.isFixtureGenerated && t.fixtures.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Fixtures Bracket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (isHost)
                    TextButton.icon(
                      onPressed: _editFixtures,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit"),
                    )
                ],
              ),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: t.fixtures.map((fixture) {
                          return Row(
                            children: [
                              Container(
                                width: 220,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                                      child: Text(fixture['team1'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ),
                                    const Divider(height: 1, thickness: 1.5, color: Colors.blue),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))),
                                      child: Text(fixture['team2'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ),
                                  ],
                                ),
                              ),
                              // Connecting line simulation
                              Container(
                                width: 30,
                                height: 2,
                                margin: const EdgeInsets.only(bottom: 24),
                                color: Colors.blue.shade300,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      // TBD Next Round vertical connecting line
                      Container(
                        width: 2,
                        height: t.fixtures.length > 1 ? (t.fixtures.length * 100.0) - 80 : 2,
                        color: Colors.blue.shade300,
                        margin: const EdgeInsets.only(bottom: 24),
                      ),
                      Container(
                        width: 30,
                        height: 2,
                        color: Colors.blue.shade300,
                        margin: const EdgeInsets.only(bottom: 24),
                      ),
                      Container(
                        width: 200,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text("Winner / Next Round", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isHost
              ? (t.isFixtureGenerated
                  ? const ElevatedButton(onPressed: null, child: Text("Fixtures Already Generated"))
                  : ElevatedButton(
                      onPressed: _isGeneratingFixtures ? null : _generateFixtures,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isGeneratingFixtures ? const CircularProgressIndicator(color: Colors.white) : const Text("Set Fixtures"),
                    ))
              : (t.isFixtureGenerated
                  ? const ElevatedButton(onPressed: null, child: Text("Registration Closed"))
                  : ElevatedButton(
                      onPressed: _showJoinDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("Join Tournament"),
                    )),
        ),
      ),
    );
  }
}
