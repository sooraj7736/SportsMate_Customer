import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/tournament/domain/tournament_entity.dart';
import 'package:sportsmate/features/tournament/data/tournament_repository.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:sportsmate/features/tournament/live_score/data/football_live_score_repository.dart';
import 'package:sportsmate/features/tournament/live_score/domain/football_live_score_entity.dart';
import 'package:sportsmate/features/tournament/live_score/presentation/add_football/add_football_live_score_screen.dart';
import 'package:sportsmate/features/tournament/live_score/presentation/view_football/view_football_live_score_screen.dart';
import 'package:sportsmate/features/tournament/live_score/data/cricket_live_score_repository.dart';
import 'package:sportsmate/features/tournament/live_score/domain/cricket_live_score_entity.dart';
import 'package:sportsmate/features/tournament/live_score/presentation/add_cricket/add_cricket_live_score_screen.dart';
import 'package:sportsmate/features/tournament/live_score/presentation/view_cricket/view_cricket_live_score_screen.dart';
import 'package:sportsmate/features/notifications/data/notifications_repository.dart';
import 'package:sportsmate/features/notifications/domain/notification_entity.dart';

class TournamentDetailsScreen extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const TournamentDetailsScreen({super.key, required this.tournament});

  @override
  ConsumerState<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends ConsumerState<TournamentDetailsScreen> {
  bool _isGeneratingFixtures = false;

  bool get _isFootballTournament => widget.tournament.sport.toLowerCase() == 'football';
  bool get _isCricketTournament => widget.tournament.sport.toLowerCase() == 'cricket';

  bool _isLiveScoreUpdateEnabled(Map<String, dynamic> fixture) {
    final date = fixture['date'] as String? ?? '';
    final time = fixture['time'] as String? ?? '';
    if (date.isEmpty || time.isEmpty) return false;
    try {
      final scheduledTime = DateTime.parse('$date $time');
      final now = DateTime.now();
      return now.isAfter(scheduledTime.subtract(const Duration(hours: 1)));
    } catch (_) {
      return false;
    }
  }

  String _formatFootballIncident(String eventText) {
    final parts = eventText.split(' • ').map((e) => e.trim()).toList();
    if (parts.isEmpty) return eventText;

    String minutePrefix = '';
    int offset = 0;
    if (parts.isNotEmpty && parts[0].endsWith("'")) {
      minutePrefix = parts[0] + ' ';
      offset = 1;
    }

    final type = parts.length > offset ? parts[offset] : '';
    final team = parts.length > offset + 1 ? parts[offset + 1] : '';
    final player = parts.length > offset + 2 ? parts[offset + 2] : '';
    final note = parts.length > offset + 3 ? parts[offset + 3] : '';

    final displayTeam = team.isNotEmpty ? ' ($team)' : '';
    final displayPlayer = player.isNotEmpty ? player : 'A player';
    final displayNote = note.isNotEmpty ? ' ($note)' : '';

    switch (type.toLowerCase()) {
      case 'goal':
        return minutePrefix + '⚽ GOAL!!! Spectacular play by $displayPlayer$displayTeam!$displayNote';
      case 'yellow card':
        return minutePrefix + '🟨 YELLOW CARD! $displayPlayer$displayTeam booked$displayNote.';
      case 'red card':
        return minutePrefix + '🟥 RED CARD! $displayPlayer$displayTeam sent off$displayNote!';
      case 'foul':
        return minutePrefix + '🚨 FOUL! Infraction by $displayPlayer$displayTeam$displayNote.';
      case 'penalty':
        return minutePrefix + '🥅 PENALTY! Spot kick awarded to $displayTeam. $displayPlayer steps up!';
      case 'offside':
        return minutePrefix + '🚩 OFFSIDE! Flag up against $displayPlayer$displayTeam.';
      case 'corner':
        return minutePrefix + '📐 CORNER KICK! $displayTeam takes a set-piece opportunity.';
      default:
        return minutePrefix + '📢 $type: $displayPlayer$displayTeam$displayNote';
    }
  }

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
    final List<TextEditingController> memberControllers = [];

    // Prefill user profile
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to register a team.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.sports_soccer, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text("Register Team"),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Fill in the details to register your team. You are automatically set as the Captain.",
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: teamNameController,
                        decoration: const InputDecoration(
                          labelText: "Team Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Captain field (Read-only)
                      TextFormField(
                        initialValue: "${userProfile.name} (Captain)",
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: "Team Captain",
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: const Icon(Icons.star, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Teammates (${1 + memberControllers.length})",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "Min: ${widget.tournament.minPlayersPerTeam} • Max: 15",
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      // List of dynamic teammates
                      if (memberControllers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "No teammates added yet. Tap the button below to add your squad.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ...memberControllers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: "Teammate #${idx + 1} Name",
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.person_outline),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    memberControllers.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (1 + memberControllers.length >= 15) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Maximum capacity of 15 reached.")),
                            );
                            return;
                          }
                          setDialogState(() {
                            memberControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Team Member"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    for (var c in memberControllers) {
                      c.dispose();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final teamName = teamNameController.text.trim();
                    if (teamName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a team name.")),
                      );
                      return;
                    }

                    // Validate blank teammate names
                    for (int i = 0; i < memberControllers.length; i++) {
                      if (memberControllers[i].text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Teammate #${i + 1} name cannot be empty.")),
                        );
                        return;
                      }
                    }

                    final newPlayerNames = memberControllers.map((c) => c.text.trim()).toList();
                    final allNewPlayers = [userProfile.name, ...newPlayerNames];

                    // Capacity validation
                    final totalPlayers = allNewPlayers.length;
                    if (totalPlayers < widget.tournament.minPlayersPerTeam) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Your team needs at least ${widget.tournament.minPlayersPerTeam} players to register. Currently has $totalPlayers."),
                          backgroundColor: Colors.red.shade800,
                        ),
                      );
                      return;
                    }

                    if (totalPlayers > 15) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Maximum squad size is 15 players."),
                          backgroundColor: Colors.red.shade800,
                        ),
                      );
                      return;
                    }

                    // Duplication Guard 1: Captain UID Check
                    final existingCaptains = widget.tournament.registeredTeams.map((t) => t['captainUid'] as String?).toList();
                    if (existingCaptains.contains(userProfile.uid)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("You have already registered a team in this tournament!"),
                          backgroundColor: Colors.red.shade800,
                        ),
                      );
                      return;
                    }

                    // Duplication Guard 2: Case-insensitive Name Check against other teams
                    final Set<String> registeredNames = {};
                    for (final team in widget.tournament.registeredTeams) {
                      final String captName = team['captainName'] as String? ?? '';
                      if (captName.isNotEmpty) {
                        registeredNames.add(captName.toLowerCase());
                      }
                      final playersList = (team['players'] as List<dynamic>?) ?? [];
                      for (final p in playersList) {
                        if (p != null) {
                          registeredNames.add(p.toString().toLowerCase());
                        }
                      }
                    }

                    for (final name in allNewPlayers) {
                      if (registeredNames.contains(name.toLowerCase())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Player '$name' is already registered in another team in this tournament!"),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                        return;
                      }
                    }

                    // Duplication Guard 3: Internal Name Check
                    final uniqueNewPlayers = allNewPlayers.map((n) => n.toLowerCase()).toSet();
                    if (uniqueNewPlayers.length < allNewPlayers.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Duplicate player names detected in your team list!"),
                          backgroundColor: Colors.red.shade800,
                        ),
                      );
                      return;
                    }

                    // Limit registration count
                    if (widget.tournament.registeredTeams.length >= widget.tournament.maxTeams) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tournament is already full! No more teams can join.")),
                      );
                      Navigator.pop(context);
                      return;
                    }

                    final teamData = {
                      'teamName': teamName,
                      'captainUid': userProfile.uid,
                      'captainName': userProfile.name,
                      'players': newPlayerNames, // Keep teammates in players array
                    };

                    try {
                      await ref.read(tournamentRepositoryProvider).joinTournament(widget.tournament.id, teamData);
                      for (var c in memberControllers) {
                        c.dispose();
                      }
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
    DateTime? initialDate;
    if (targetFixture['date'] != null && targetFixture['date'].toString().isNotEmpty) {
      try {
        initialDate = DateTime.parse(targetFixture['date'].toString());
      } catch (_) {}
    }
    initialDate ??= (widget.tournament.startDate.isAfter(DateTime.now()) ? widget.tournament.startDate : DateTime.now());

    TimeOfDay? initialTime;
    if (targetFixture['time'] != null && targetFixture['time'].toString().isNotEmpty) {
      try {
        final parts = targetFixture['time'].toString().split(':');
        if (parts.length >= 2) {
          initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (_) {}
    }
    initialTime ??= const TimeOfDay(hour: 15, minute: 0);

    final isCricket = widget.tournament.sport.toLowerCase() == 'cricket';
    final isFootball = widget.tournament.sport.toLowerCase() == 'football';

    final initialParam = isCricket
        ? (targetFixture['overs']?.toString() ?? '20')
        : (targetFixture['duration']?.toString() ?? '90');

    showDialog(
      context: context,
      builder: (dialogContext) {
        DateTime selectedDate = initialDate!;
        TimeOfDay selectedTime = initialTime!;
        final controller = TextEditingController(text: initialParam);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
            final formattedTimeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
            final formattedDisplayDate = DateFormat('MMM dd, yyyy').format(selectedDate);
            final formattedDisplayTime = selectedTime.format(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF1DB954)),
                  const SizedBox(width: 10),
                  const Text(
                    'Schedule Match',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${targetFixture['team1']} vs ${targetFixture['team2']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Match Date',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: widget.tournament.startDate,
                          lastDate: widget.tournament.endDate,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDisplayDate,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const Icon(Icons.edit_calendar, color: Colors.black54, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Match Time',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDisplayTime,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const Icon(Icons.access_time, color: Colors.black54, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isCricket) ...[
                      const Text(
                        'Number of Overs',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter overs (e.g., 20)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.sports_cricket, size: 18),
                        ),
                      ),
                    ] else if (isFootball) ...[
                      const Text(
                        'Match Duration (Minutes)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter duration (e.g., 90)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.timer, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final customValStr = controller.text.trim();
                    if (customValStr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a value')),
                      );
                      return;
                    }
                    final customVal = int.tryParse(customValStr);
                    if (customVal == null || customVal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid positive number')),
                      );
                      return;
                    }

                    final formattedDate = formattedDateStr;
                    final formattedTime = formattedTimeStr;

                    final List<Map<String, dynamic>> updatedFixtures = widget.tournament.fixtures.map((f) {
                      final map = Map<String, dynamic>.from(f);
                      if (map['matchNumber'] == targetFixture['matchNumber']) {
                        map['date'] = formattedDate;
                        map['time'] = formattedTime;
                        if (isCricket) {
                          map['overs'] = customVal;
                        } else if (isFootball) {
                          map['duration'] = customVal;
                        }
                      }
                      return map;
                    }).toList();

                    final String team1Name = targetFixture['team1'] as String? ?? '';
                    final String team2Name = targetFixture['team2'] as String? ?? '';

                    String? team1CaptainUid;
                    String? team2CaptainUid;

                    for (final team in widget.tournament.registeredTeams) {
                      final String name = team['teamName'] as String? ?? '';
                      if (name == team1Name) {
                        team1CaptainUid = team['captainUid'] as String?;
                      }
                      if (name == team2Name) {
                        team2CaptainUid = team['captainUid'] as String?;
                      }
                    }

                    Navigator.pop(dialogContext);

                    try {
                      await ref.read(tournamentRepositoryProvider).updateTournamentFixtures(
                            widget.tournament.id,
                            updatedFixtures,
                          );

                      final notificationsRepo = ref.read(notificationsRepositoryProvider);
                      final displayDateFormatted = DateFormat('MMM dd, yyyy').format(selectedDate);

                      if (team1CaptainUid != null && team1CaptainUid.isNotEmpty) {
                        await notificationsRepo.sendNotification(
                          NotificationEntity(
                            id: '',
                            targetUserId: team1CaptainUid,
                            title: 'Match Scheduled: $team1Name vs $team2Name',
                            body:
                                'Your match has been scheduled on $displayDateFormatted at $formattedTime in the tournament ${widget.tournament.tournamentName}.',
                            date: DateTime.now(),
                          ),
                        );
                      }
                      if (team2CaptainUid != null &&
                          team2CaptainUid.isNotEmpty &&
                          team2CaptainUid != team1CaptainUid) {
                        await notificationsRepo.sendNotification(
                          NotificationEntity(
                            id: '',
                            targetUserId: team2CaptainUid,
                            title: 'Match Scheduled: $team1Name vs $team2Name',
                            body:
                                'Your match has been scheduled on $displayDateFormatted at $formattedTime in the tournament ${widget.tournament.tournamentName}.',
                            date: DateTime.now(),
                          ),
                        );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Match schedule updated successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating match schedule: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
      if (t.sport.toLowerCase() == 'cricket' && fixture['overs'] != null) {
        scheduleLabel += ' • ' + fixture['overs'].toString() + ' Overs';
      } else if (t.sport.toLowerCase() == 'football' && fixture['duration'] != null) {
        scheduleLabel += ' • ' + fixture['duration'].toString() + ' Mins';
      }
    }

    final liveScoreAsync = _isFootballTournament
        ? ref.watch(footballLiveScoreStreamProvider(t.id))
        : _isCricketTournament
            ? ref.watch(cricketLiveScoreStreamProvider(t.id))
            : const AsyncValue.data(null);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
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
                      color: hasSchedule ? Colors.green.shade600 : Colors.blue.shade400,
                    ),
                ],
              ),
            ),
            // Team 1
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            // Live score snippet on card (compact)
            if (_isFootballTournament || _isCricketTournament) ...[
              const Divider(height: 1, thickness: 1, color: Colors.black12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: liveScoreAsync.when(
                  data: (score) {
                    if (score == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          isHost ? 'No score yet.' : 'No live score posted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    if (_isFootballTournament && score is FootballLiveScoreEntity) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  score.hostTeamName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  '${score.hostTeamScore} - ${score.guestTeamScore}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  score.guestTeamName,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(score.matchStatus, style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              if (score.minute != null) Text('Min ${score.minute}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ],
                      );
                    } else if (_isCricketTournament && score is CricketLiveScoreEntity) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  score.battingTeamName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  '${score.runs}/${score.wickets}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '(${score.overs}.${score.balls})',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(score.matchStatus, style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Expanded(
                                child: Text(
                                  'vs ${score.bowlingTeamName}',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox(height: 36, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                  error: (err, st) => Text('Live score unavailable', style: TextStyle(color: Colors.red.shade600)),
                ),
              ),
            ],
            // Schedule Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasSchedule ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
                borderRadius: (_isFootballTournament || _isCricketTournament)
                    ? null
                    : const BorderRadius.vertical(bottom: Radius.circular(10)),
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
            // Bottom Action Button
            if (_isFootballTournament || _isCricketTournament) ...[
              const Divider(height: 1, thickness: 1, color: Colors.black12),
              if (isHost) ...[
                // Host sees Update Live Score
                InkWell(
                  onTap: () {
                    if (!_isLiveScoreUpdateEnabled(fixture)) {
                      final dateStr = fixture['date'] as String? ?? '';
                      final timeStr = fixture['time'] as String? ?? '';
                      final scheduleLabel = (dateStr.isNotEmpty && timeStr.isNotEmpty)
                          ? '$dateStr $timeStr'
                          : 'Not Scheduled';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            dateStr.isEmpty || timeStr.isEmpty
                                ? "This match has not been scheduled yet. Please schedule it first to enable live score updates."
                                : "Live score updates are only enabled starting 1 hour before the scheduled time ($scheduleLabel).",
                          ),
                          backgroundColor: Colors.red.shade800,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _isFootballTournament
                            ? AddFootballLiveScoreScreen(tournament: t)
                            : AddCricketLiveScoreScreen(tournament: t),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isLiveScoreUpdateEnabled(fixture)
                          ? (_isFootballTournament ? Colors.orange.shade700 : Colors.teal.shade700)
                          : Colors.grey.shade300,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),
                    child: Center(
                      child: Text(
                        "Update Live Score",
                        style: TextStyle(
                          color: _isLiveScoreUpdateEnabled(fixture) ? Colors.white : Colors.grey.shade600,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Non-host sees View Live Score
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _isFootballTournament
                            ? ViewFootballLiveScoreScreen(tournament: t)
                            : ViewCricketLiveScoreScreen(tournament: t),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isFootballTournament ? Colors.orange.shade50 : Colors.teal.shade50,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),
                    child: Center(
                      child: Text(
                        "View Live Score",
                        style: TextStyle(
                          color: _isFootballTournament ? Colors.orange.shade800 : Colors.teal.shade800,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveScoreCard(BuildContext context, bool isHost, TournamentEntity tournament, AsyncValue<FootballLiveScoreEntity?> liveScoreAsync) {
    return liveScoreAsync.when(
      data: (liveScore) {
        final score = liveScore;
        final hasScore = score != null;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.orange.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Football Live Score',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasScore ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        score?.matchStatus ?? 'No score posted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: hasScore ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (score != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(score.hostTeamName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      Text('${score.hostTeamScore} - ${score.guestTeamScore}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(score.guestTeamName, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  if (score.minute != null) ...[
                    const SizedBox(height: 8),
                    Text('Minute: ${score.minute}'),
                  ],
                  if (score.foulEvents.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final rawFoulEvents = score.foulEvents;
                        final formattedIncidents = rawFoulEvents.map((e) => _formatFootballIncident(e)).toList();
                        final latestIncidents = formattedIncidents.length > 3
                            ? formattedIncidents.sublist(formattedIncidents.length - 3)
                            : formattedIncidents;
                        return BroadcastTicker(
                          incidents: latestIncidents,
                          badgeColor: const Color(0xFFD84315),
                          backgroundColor: const Color(0xFF1A1A1A),
                          badgeText: 'EVENT',
                        );
                      }
                    ),
                  ],
                ] else ...[
                  Text(
                    isHost
                        ? 'No live score has been posted yet. Add the first update for this tournament.'
                        : 'The host has not posted a live score yet.',
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final anyEnabled = tournament.fixtures.any((f) => _isLiveScoreUpdateEnabled(f));
                          final btnBgColor = isHost
                              ? (anyEnabled ? Colors.orange.shade700 : Colors.grey.shade300)
                              : Colors.orange.shade50;
                          final btnFgColor = isHost
                              ? (anyEnabled ? Colors.white : Colors.grey.shade600)
                              : Colors.orange.shade800;

                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBgColor,
                              foregroundColor: btnFgColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isHost
                                      ? (anyEnabled ? Colors.orange.shade800 : Colors.grey.shade400)
                                      : Colors.orange.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (isHost) {
                                if (!anyEnabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        "No matches are currently scheduled to start within 1 hour. Please schedule or reschedule a match first.",
                                      ),
                                      backgroundColor: Colors.red.shade800,
                                    ),
                                  );
                                  return;
                                }
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => isHost
                                      ? AddFootballLiveScoreScreen(tournament: tournament)
                                      : ViewFootballLiveScoreScreen(tournament: tournament),
                                ),
                              );
                            },
                            icon: Icon(isHost ? Icons.edit : Icons.visibility),
                            label: Text(
                              isHost ? 'Update Live Score' : 'View Live Score',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text('Failed to load live score: $err'),
      ),
    );
  }

  Widget _buildCricketLiveScoreCard(BuildContext context, bool isHost, TournamentEntity tournament, AsyncValue<CricketLiveScoreEntity?> liveScoreAsync) {
    return liveScoreAsync.when(
      data: (liveScore) {
        final score = liveScore;
        final hasScore = score != null;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.teal.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cricket Live Score',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasScore ? Colors.teal.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        score?.matchStatus ?? 'No score posted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: hasScore ? Colors.teal.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (score != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(score.battingTeamName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '${score.runs}/${score.wickets}',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Overs: ${score.overs}.${score.balls}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('vs ${score.bowlingTeamName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  if (score.incidents.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final latestIncidents = score.incidents.length > 3
                            ? score.incidents.sublist(score.incidents.length - 3)
                            : score.incidents;
                        return BroadcastTicker(
                          incidents: latestIncidents,
                          badgeColor: const Color(0xFFFFB300),
                          backgroundColor: const Color(0xFF0B1713),
                          badgeText: 'EVENT',
                        );
                      }
                    ),
                  ],
                ] else ...[
                  Text(
                    isHost
                        ? 'No live score has been posted yet. Add the first update for this tournament.'
                        : 'The host has not posted a live score yet.',
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final anyEnabled = tournament.fixtures.any((f) => _isLiveScoreUpdateEnabled(f));
                          final btnBgColor = isHost
                              ? (anyEnabled ? Colors.teal.shade700 : Colors.grey.shade300)
                              : Colors.teal.shade50;
                          final btnFgColor = isHost
                              ? (anyEnabled ? Colors.white : Colors.grey.shade600)
                              : Colors.teal.shade800;

                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBgColor,
                              foregroundColor: btnFgColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isHost
                                      ? (anyEnabled ? Colors.teal.shade800 : Colors.grey.shade400)
                                      : Colors.teal.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (isHost) {
                                if (!anyEnabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        "No matches are currently scheduled to start within 1 hour. Please schedule or reschedule a match first.",
                                      ),
                                      backgroundColor: Colors.red.shade800,
                                    ),
                                  );
                                  return;
                                }
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => isHost
                                      ? AddCricketLiveScoreScreen(tournament: tournament)
                                      : ViewCricketLiveScoreScreen(tournament: tournament),
                                ),
                              );
                            },
                            icon: Icon(isHost ? Icons.edit : Icons.visibility),
                            label: Text(
                              isHost ? 'Update Live Score' : 'View Live Score',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text('Failed to load live score: $err'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final userProfile = ref.watch(userProfileProvider).value;
    final isHost = userProfile?.uid == t.hostUid;
    final liveScoreAsync = _isFootballTournament ? ref.watch(footballLiveScoreStreamProvider(t.id)) : null;
    final cricketLiveScoreAsync = _isCricketTournament ? ref.watch(cricketLiveScoreStreamProvider(t.id)) : null;

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
            if (_isFootballTournament && liveScoreAsync != null) ...[
              const SizedBox(height: 8),
              _buildLiveScoreCard(context, isHost, t, liveScoreAsync),
            ],
            if (_isCricketTournament && cricketLiveScoreAsync != null) ...[
              const SizedBox(height: 8),
              _buildCricketLiveScoreCard(context, isHost, t, cricketLiveScoreAsync),
            ],
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
                                  final double slotHeight = 330.0 * (1 << rIndex);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isFootballTournament || _isCricketTournament) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isHost) {
                        final anyEnabled = t.fixtures.any((f) => _isLiveScoreUpdateEnabled(f));
                        if (!anyEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "No matches are currently scheduled to start within 1 hour. Please schedule or reschedule a match first.",
                              ),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                          return;
                        }
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isHost
                              ? (_isFootballTournament
                                  ? AddFootballLiveScoreScreen(tournament: t)
                                  : AddCricketLiveScoreScreen(tournament: t))
                              : (_isFootballTournament
                                  ? ViewFootballLiveScoreScreen(tournament: t)
                                  : ViewCricketLiveScoreScreen(tournament: t)),
                        ),
                      );
                    },
                    icon: Icon(isHost ? Icons.edit : Icons.visibility),
                    label: Text(isHost ? 'Update Live Score' : 'View Live Score'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFootballTournament ? Colors.orange.shade700 : Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              isHost
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
                      : t.registeredTeams.length >= t.maxTeams
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text("Tournament Full"),
                            )
                          : ElevatedButton(
                              onPressed: _showJoinDialog,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("Join Tournament"),
                            )),
            ],
          ),
        ),
      ),
    );
  }
}

class BroadcastTicker extends StatefulWidget {
  final List<String> incidents;
  final Color badgeColor;
  final Color backgroundColor;
  final String badgeText;

  const BroadcastTicker({
    super.key,
    required this.incidents,
    this.badgeColor = const Color(0xFFE65100),
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.badgeText = 'EVENT',
  });

  @override
  State<BroadcastTicker> createState() => _BroadcastTickerState();
}

class _BroadcastTickerState extends State<BroadcastTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _cycleTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCycling();
  }

  @override
  void didUpdateWidget(covariant BroadcastTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.incidents.length != oldWidget.incidents.length) {
      _startCycling();
    }
  }

  void _startCycling() {
    _cycleTimer?.cancel();
    if (widget.incidents.isEmpty) return;

    _currentIndex = 0;

    _cycleTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && widget.incidents.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.incidents.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.incidents.isEmpty) return const SizedBox.shrink();

    final activeIndex = _currentIndex < widget.incidents.length ? _currentIndex : 0;
    final String currentText = widget.incidents[activeIndex];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.badgeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pulseAnimation.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  widget.badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(12, 40),
            painter: _SlantedDividerPainter(color: widget.badgeColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

                  final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeIn);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey<String>(currentText),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlantedDividerPainter extends CustomPainter {
  final Color color;

  _SlantedDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SlantedDividerPainter oldDelegate) => oldDelegate.color != color;
}
