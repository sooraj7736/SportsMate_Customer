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

      final int teamCount = shuffledTeams.length;
      
      // Find the next power of 2 greater than or equal to teamCount
      int powerOfTwo = 2;
      while (powerOfTwo < teamCount) {
        powerOfTwo *= 2;
      }

      final int totalMatchesRound1 = powerOfTwo ~/ 2;
      final int byeCount = powerOfTwo - teamCount;


      final List<String> shuffledNames = shuffledTeams.map((team) => team['teamName']?.toString() ?? 'Unknown Team').toList();

      int matchNumber = 1;
      List<Map<String, dynamic>> currentRoundMatches = [];
      int teamIndex = 0;

      // Symmetrically interleave double-team matches and BYE matches across the first round slots
      final List<bool> isByeMatch = List.filled(totalMatchesRound1, false);
      if (byeCount > 0) {
        for (int i = 0; i < byeCount; i++) {
          final int index = ((i * totalMatchesRound1) / byeCount).floor();
          isByeMatch[index] = true;
        }
      }

      for (int i = 0; i < totalMatchesRound1; i++) {
        if (isByeMatch[i]) {
          currentRoundMatches.add({
            'roundIndex': 0,
            'roundName': 'Round 1',
            'matchNumber': matchNumber++,
            'team1': shuffledNames[teamIndex++],
            'team2': 'BYE',
            'status': 'Upcoming',
            'date': '',
            'time': '',
          });
        } else {
          currentRoundMatches.add({
            'roundIndex': 0,
            'roundName': 'Round 1',
            'matchNumber': matchNumber++,
            'team1': shuffledNames[teamIndex++],
            'team2': shuffledNames[teamIndex++],
            'status': 'Upcoming',
            'date': '',
            'time': '',
          });
        }
      }

      newFixtures.addAll(currentRoundMatches);

      // Track match winners to carry actual teams forward when a bye occurs
      final Map<int, String> matchWinners = {};
      for (var m in currentRoundMatches) {
        final mNum = m['matchNumber'] as int;
        final t1 = m['team1'] as String;
        final t2 = m['team2'] as String;
        if (t2 == 'BYE') {
          matchWinners[mNum] = t1;
        } else if (t1 == 'BYE') {
          matchWinners[mNum] = t2;
        } else {
          matchWinners[mNum] = "Winner of Match $mNum";
        }
      }

      // Generate subsequent rounds
      int roundIndex = 1;
      while (currentRoundMatches.length > 1) {
        final List<Map<String, dynamic>> nextRoundMatches = [];
        final prevRoundMatches = currentRoundMatches;
        final int nextRoundMatchCount = prevRoundMatches.length ~/ 2;

        String roundName = 'Round ${roundIndex + 1}';
        if (nextRoundMatchCount == 1) {
          roundName = 'Final';
        } else if (nextRoundMatchCount == 2) {
          roundName = 'Semifinals';
        } else if (nextRoundMatchCount == 4) {
          roundName = 'Quarterfinals';
        }

        for (int i = 0; i < nextRoundMatchCount; i++) {
          final prevMatch1 = prevRoundMatches[2 * i];
          final prevMatch2 = prevRoundMatches[2 * i + 1];

          final prevMatch1Num = prevMatch1['matchNumber'] as int;
          final prevMatch2Num = prevMatch2['matchNumber'] as int;

          final team1Name = matchWinners[prevMatch1Num] ?? "Winner of Match $prevMatch1Num";
          final team2Name = matchWinners[prevMatch2Num] ?? "Winner of Match $prevMatch2Num";

          final newMatchNum = matchNumber++;

          nextRoundMatches.add({
            'roundIndex': roundIndex,
            'roundName': roundName,
            'matchNumber': newMatchNum,
            'team1': team1Name,
            'team2': team2Name,
            'status': 'Upcoming',
            'date': '',
            'time': '',
          });

          // Track the winner representation of this new match
          if (team1Name == 'BYE') {
            matchWinners[newMatchNum] = team2Name;
          } else if (team2Name == 'BYE') {
            matchWinners[newMatchNum] = team1Name;
          } else {
            matchWinners[newMatchNum] = "Winner of Match $newMatchNum";
          }
        }

        newFixtures.addAll(nextRoundMatches);
        currentRoundMatches = nextRoundMatches;
        roundIndex++;
      }

      await ref.read(tournamentRepositoryProvider).updateTournamentFixtures(t.id, newFixtures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tournament fixtures generated successfully!")));
        Navigator.pop(context);
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
                                    items: widget.tournament.registeredTeams
                                        .map((t) => t['teamName'].toString())
                                        .followedBy(['BYE', fixture['team1'].toString()])
                                        .toSet()
                                        .toList()
                                        .map((t) {
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
                                    items: widget.tournament.registeredTeams
                                        .map((t) => t['teamName'].toString())
                                        .followedBy(['BYE', fixture['team2'].toString()])
                                        .toSet()
                                        .toList()
                                        .map((t) {
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

  void _editMatchSchedule(Map<String, dynamic> targetFixture) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.tournament.startDate.isAfter(DateTime.now()) ? widget.tournament.startDate : DateTime.now(),
      firstDate: widget.tournament.startDate,
      lastDate: widget.tournament.endDate,
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 0),
    );
    if (pickedTime == null) return;
    if (!mounted) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
    final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> updatedFixtures = widget.tournament.fixtures.map((f) {
      final map = Map<String, dynamic>.from(f);
      if (map['matchNumber'] == targetFixture['matchNumber']) {
        map['date'] = formattedDate;
        map['time'] = formattedTime;
      }
      return map;
    }).toList();

    try {
      await ref.read(tournamentRepositoryProvider).updateTournamentFixtures(widget.tournament.id, updatedFixtures);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match schedule updated successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating match schedule: $e")));
      }
    }
  }

  Widget _buildConnector({
    required int rIndex,
    required int matchIdx,
    required double slotHeight,
    required bool isLastRound,
  }) {
    if (isLastRound) return const SizedBox(width: 24);

    final isUpper = matchIdx % 2 == 0;

    return SizedBox(
      width: 60,
      height: slotHeight,
      child: Stack(
        children: [
          // Horizontal line from current card to the center vertical connector
          Positioned(
            left: 0,
            top: slotHeight / 2 - 1,
            child: Container(
              width: 30,
              height: 2,
              color: Colors.blue.shade300,
            ),
          ),
          // Vertical connector line
          Positioned(
            left: 29,
            top: isUpper ? slotHeight / 2 - 1 : 0,
            child: Container(
              width: 2,
              height: slotHeight / 2 + 1,
              color: Colors.blue.shade300,
            ),
          ),
          // Horizontal line going into the next round card
          Positioned(
            left: 30,
            top: isUpper ? slotHeight - 1 : 0,
            child: Container(
              width: 30,
              height: 2,
              color: Colors.blue.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> fixture, bool isHost, TournamentEntity t) {
    final dateStr = fixture['date'] as String? ?? '';
    final timeStr = fixture['time'] as String? ?? '';
    final hasSchedule = dateStr.isNotEmpty && timeStr.isNotEmpty;
    String scheduleLabel = "Not Scheduled";
    if (hasSchedule) {
      try {
        final parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        scheduleLabel = '${DateFormat('MMM dd').format(parsedDate)} at $timeStr';
      } catch (_) {
        scheduleLabel = '$dateStr $timeStr';
      }
    }

    return GestureDetector(
      onTap: isHost ? () => _editMatchSchedule(fixture) : null,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasSchedule ? Colors.green.shade400 : Colors.blue.shade200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header / Match Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasSchedule ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Match #${fixture['matchNumber']}",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: hasSchedule ? Colors.green.shade800 : Colors.blue.shade800,
                    ),
                  ),
                  if (isHost)
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: hasSchedule ? Colors.green : Colors.blue,
                    ),
                ],
              ),
            ),
            // Team 1
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                fixture['team1'] ?? 'TBD',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            // Team 2
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                fixture['team2'] ?? 'TBD',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            // Schedule Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasSchedule ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 11,
                    color: hasSchedule ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      scheduleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        color: hasSchedule ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      t.fixtures.fold<int>(0, (maxVal, element) {
                            final rIndex = element['roundIndex'] as int? ?? 0;
                            return rIndex > maxVal ? rIndex : maxVal;
                          }) +
                          1,
                      (rIndex) {
                        final roundMatches = t.fixtures
                            .where((f) => (f['roundIndex'] as int? ?? 0) == rIndex)
                            .toList();
                        final String roundName = roundMatches.isNotEmpty
                            ? (roundMatches.first['roundName'] ?? 'Round ${rIndex + 1}')
                            : 'Round ${rIndex + 1}';

                        final maxRoundIndex = t.fixtures.fold<int>(0, (maxVal, element) {
                          final rIndex = element['roundIndex'] as int? ?? 0;
                          return rIndex > maxVal ? rIndex : maxVal;
                        });

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    roundName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                ...roundMatches.asMap().entries.map((entry) {
                                  final int matchIdx = entry.key;
                                  final Map<String, dynamic> fixture = entry.value;
                                  final double slotHeight = 160.0 * (1 << rIndex);

                                  return SizedBox(
                                    width: 280,
                                    height: slotHeight,
                                    child: Row(
                                      children: [
                                        // Centered Match Card
                                        SizedBox(
                                          width: 220,
                                          child: Center(
                                            child: _buildMatchCard(fixture, isHost, t),
                                          ),
                                        ),
                                        // Connector Line to next round
                                        _buildConnector(
                                          rIndex: rIndex,
                                          matchIdx: matchIdx,
                                          slotHeight: slotHeight,
                                          isLastRound: rIndex == maxRoundIndex,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
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
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingFixtures ? null : _generateFixtures,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: _isGeneratingFixtures
                                ? const SizedBox.shrink()
                                : const Icon(Icons.refresh),
                            label: _isGeneratingFixtures
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Reset & Re-generate Bracket"),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _isGeneratingFixtures ? null : _generateFixtures,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isGeneratingFixtures ? const CircularProgressIndicator(color: Colors.white) : const Text("Set Fixtures Bracket"),
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
