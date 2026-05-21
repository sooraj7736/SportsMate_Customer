import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/auth_controller.dart';
import '../../../domain/tournament_entity.dart';
import '../../data/cricket_live_score_repository.dart';
import '../../domain/cricket_live_score_entity.dart';

class AddCricketLiveScoreScreen extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const AddCricketLiveScoreScreen({super.key, required this.tournament});

  @override
  ConsumerState<AddCricketLiveScoreScreen> createState() => _AddCricketLiveScoreScreenState();
}

class _AddCricketLiveScoreScreenState extends ConsumerState<AddCricketLiveScoreScreen> {
  late final TextEditingController _noteController;
  Timer? _saveDebounce;

  // General state
  int _runs = 0;
  int _wickets = 0;
  int _overs = 0;
  int _balls = 0;
  String _matchStatus = 'Live';
  String _saveLabel = 'Auto-saving enabled';
  bool _isReady = false;

  // Team names
  String? _selectedBattingTeam;
  String? _selectedBowlingTeam;

  // Batsmen state
  String? _batsman1Name;
  int _batsman1Runs = 0;
  int _batsman1Balls = 0;

  String? _batsman2Name;
  int _batsman2Runs = 0;
  int _batsman2Balls = 0;

  bool _batsman1OnStrike = true;

  // Bowler state
  String? _bowlerName;
  double _bowlerOvers = 0.0;
  int _bowlerMaidens = 0;
  int _bowlerRuns = 0;
  int _bowlerWickets = 0;

  // Timeline
  List<String> _recentBalls = [];
  List<String> _incidents = [];

  // Undo History
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    final existingScore = ref.read(cricketLiveScoreStreamProvider(widget.tournament.id)).asData?.value;

    _runs = existingScore?.runs ?? 0;
    _wickets = existingScore?.wickets ?? 0;
    _overs = existingScore?.overs ?? 0;
    _balls = existingScore?.balls ?? 0;
    _matchStatus = existingScore?.matchStatus ?? 'Live';

    _selectedBattingTeam = existingScore?.battingTeamName ?? _defaultBattingTeam();
    _selectedBowlingTeam = existingScore?.bowlingTeamName ?? _defaultBowlingTeam();

    _batsman1Name = existingScore?.batsman1Name ?? _defaultPlayerForTeam(_selectedBattingTeam, 0);
    _batsman1Runs = existingScore?.batsman1Runs ?? 0;
    _batsman1Balls = existingScore?.batsman1Balls ?? 0;

    _batsman2Name = existingScore?.batsman2Name ?? _defaultPlayerForTeam(_selectedBattingTeam, 1);
    _batsman2Runs = existingScore?.batsman2Runs ?? 0;
    _batsman2Balls = existingScore?.batsman2Balls ?? 0;

    _batsman1OnStrike = existingScore?.batsman1OnStrike ?? true;

    _bowlerName = existingScore?.bowlerName ?? _defaultPlayerForTeam(_selectedBowlingTeam, 0);
    _bowlerOvers = existingScore?.bowlerOvers ?? 0.0;
    _bowlerMaidens = existingScore?.bowlerMaidens ?? 0;
    _bowlerRuns = existingScore?.bowlerRuns ?? 0;
    _bowlerWickets = existingScore?.bowlerWickets ?? 0;

    _recentBalls = List<String>.from(existingScore?.recentBalls ?? const []);
    _incidents = List<String>.from(existingScore?.incidents ?? const []);
    _noteController = TextEditingController(text: existingScore?.note ?? '');
    
    _isReady = true;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  // --- Defaults Helper ---
  String? _defaultBattingTeam() {
    return _teamNames.isNotEmpty ? _teamNames.first : null;
  }

  String? _defaultBowlingTeam() {
    if (_teamNames.length > 1) {
      return _teamNames[1];
    }
    return _teamNames.isNotEmpty ? _teamNames.first : null;
  }

  String? _defaultPlayerForTeam(String? teamName, int index) {
    final players = _playersForTeam(teamName);
    if (players.length > index) {
      return players[index];
    }
    return null;
  }

  List<String> get _teamNames {
    return widget.tournament.registeredTeams
        .map((team) => team['teamName']?.toString() ?? 'Unknown Team')
        .where((teamName) => teamName.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic>? _teamForName(String? teamName) {
    if (teamName == null || teamName.trim().isEmpty) {
      return null;
    }
    for (final team in widget.tournament.registeredTeams) {
      if ((team['teamName']?.toString() ?? '') == teamName) {
        return team;
      }
    }
    return null;
  }

  List<String> _playersForTeam(String? teamName) {
    final team = _teamForName(teamName);
    final players = (team?['players'] as List<dynamic>?) ?? const [];
    return players
        .map((player) => player.toString().trim())
        .where((player) => player.isNotEmpty)
        .toSet()
        .toList();
  }

  void _scheduleAutoSave() {
    if (!_isReady) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 450), _saveScore);
    if (mounted) {
      setState(() => _saveLabel = 'Saving...');
    }
  }

  // --- Undo & History State ---
  void _saveHistoryState() {
    _history.add({
      'runs': _runs,
      'wickets': _wickets,
      'overs': _overs,
      'balls': _balls,
      'batsman1Name': _batsman1Name,
      'batsman1Runs': _batsman1Runs,
      'batsman1Balls': _batsman1Balls,
      'batsman2Name': _batsman2Name,
      'batsman2Runs': _batsman2Runs,
      'batsman2Balls': _batsman2Balls,
      'batsman1OnStrike': _batsman1OnStrike,
      'bowlerName': _bowlerName,
      'bowlerOvers': _bowlerOvers,
      'bowlerMaidens': _bowlerMaidens,
      'bowlerRuns': _bowlerRuns,
      'bowlerWickets': _bowlerWickets,
      'recentBalls': List<String>.from(_recentBalls),
      'incidents': List<String>.from(_incidents),
    });
    if (_history.length > 10) {
      _history.removeAt(0);
    }
  }

  void _undo() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to undo')),
      );
      return;
    }
    final previousState = _history.removeLast();
    setState(() {
      _runs = previousState['runs'];
      _wickets = previousState['wickets'];
      _overs = previousState['overs'];
      _balls = previousState['balls'];
      _batsman1Name = previousState['batsman1Name'];
      _batsman1Runs = previousState['batsman1Runs'];
      _batsman1Balls = previousState['batsman1Balls'];
      _batsman2Name = previousState['batsman2Name'];
      _batsman2Runs = previousState['batsman2Runs'];
      _batsman2Balls = previousState['batsman2Balls'];
      _batsman1OnStrike = previousState['batsman1OnStrike'];
      _bowlerName = previousState['bowlerName'];
      _bowlerOvers = previousState['bowlerOvers'];
      _bowlerMaidens = previousState['bowlerMaidens'];
      _bowlerRuns = previousState['bowlerRuns'];
      _bowlerWickets = previousState['bowlerWickets'];
      _recentBalls = List<String>.from(previousState['recentBalls']);
      _incidents = List<String>.from(previousState['incidents'] ?? const []);
    });
    _scheduleAutoSave();
  }

  // --- Ball-by-ball actions ---
  void _handleBall(String type, int runsScored, bool isExtra, bool isWicket) {
    final activeBatsman = (_batsman1OnStrike ? _batsman1Name : _batsman2Name) ?? 'Batsman';
    final bowler = _bowlerName ?? 'Bowler';

    setState(() {
      _saveHistoryState();

      String commentary = '';
      if (isWicket) {
        _wickets = (_wickets + 1).clamp(0, 10);
        _balls++;
        _appendRecentBall('W');
        commentary = "🔴 WICKET! $activeBatsman is OUT! $bowler gets the breakthrough!";

        // Update active batsman statistics
        if (_batsman1OnStrike) {
          _batsman1Balls++;
        } else {
          _batsman2Balls++;
        }

        _bowlerWickets++;
        _bowlerRuns += runsScored;

        // Prompt for a new batsman
        if (_wickets < 10) {
          _promptNewBatsman();
        }
      } else if (type == 'wd') {
        _runs += 1 + runsScored;
        _appendRecentBall('wd');
        _bowlerRuns += 1 + runsScored;
        commentary = "🔵 WIDE! Extra run conceded by $bowler.";
        // Wides do not count as a ball faced for the batsman
      } else if (type == 'nb') {
        _runs += 1 + runsScored;
        _appendRecentBall('nb');
        _bowlerRuns += 1 + runsScored;
        commentary = "🔵 NO BALL! Extra run and a Free Hit coming up off $bowler!";
        if (_batsman1OnStrike) {
          _batsman1Runs += runsScored;
          _batsman1Balls++;
        } else {
          _batsman2Runs += runsScored;
          _batsman2Balls++;
        }
        // No balls swap strike if odd run scored
        if (runsScored % 2 != 0) {
          _batsman1OnStrike = !_batsman1OnStrike;
        }
      } else {
        // Normal ball
        _runs += runsScored;
        _balls++;
        _appendRecentBall(runsScored.toString());

        if (runsScored == 6) {
          commentary = "💥 SIX! Massive hit! $activeBatsman smashes a six off $bowler!";
        } else if (runsScored == 4) {
          commentary = "🏏 FOUR! Exquisite timing! $activeBatsman finds the boundary off $bowler!";
        } else if (runsScored == 0) {
          commentary = "⚾ Dot ball! Good delivery from $bowler to $activeBatsman.";
        } else {
          commentary = "🏏 $runsScored run(s)! $activeBatsman works it away off $bowler.";
        }

        if (_batsman1OnStrike) {
          _batsman1Runs += runsScored;
          _batsman1Balls++;
        } else {
          _batsman2Runs += runsScored;
          _batsman2Balls++;
        }

        _bowlerRuns += runsScored;

        // Swap strike on odd runs
        if (runsScored % 2 != 0) {
          _batsman1OnStrike = !_batsman1OnStrike;
        }
      }

      // Add commentary to incidents history (keep latest 10)
      if (commentary.isNotEmpty) {
        _incidents.add(commentary);
        if (_incidents.length > 10) {
          _incidents.removeAt(0);
        }
      }

      // Handle bowler over completion
      if (_balls >= 6) {
        _overs++;
        _balls = 0;
        _batsman1OnStrike = !_batsman1OnStrike; // Swap strike at end of over
        _bowlerOvers = _bowlerOvers.floor() + 1.0;
        
        // Reset this over timeline for next over
        _recentBalls = [];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Over completed! Match score is $_runs/$_wickets in $_overs overs.'),
            backgroundColor: Colors.teal.shade800,
          ),
        );
      } else {
        // Just update double over notation
        _bowlerOvers = _bowlerOvers.floor() + (_balls / 10.0);
      }
    });

    _scheduleAutoSave();
  }

  void _appendRecentBall(String entry) {
    if (_recentBalls.length >= 6) {
      _recentBalls.removeAt(0);
    }
    _recentBalls.add(entry);
  }

  void _promptNewBatsman() {
    final availablePlayers = _playersForTeam(_selectedBattingTeam)
        .where((player) => player != _batsman1Name && player != _batsman2Name)
        .toList();

    if (availablePlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other registered players in the batting team list. Using placeholder.')),
      );
      // Wait a frame and set a placeholder so game doesn't block
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (_batsman1OnStrike) {
            _batsman1Name = 'Batsman ${_wickets + 1}';
            _batsman1Runs = 0;
            _batsman1Balls = 0;
          } else {
            _batsman2Name = 'Batsman ${_wickets + 1}';
            _batsman2Runs = 0;
            _batsman2Balls = 0;
          }
        });
        _scheduleAutoSave();
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select New Batsman'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availablePlayers.length,
              itemBuilder: (context, index) {
                final player = availablePlayers[index];
                return ListTile(
                  title: Text(player, style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.sports_cricket, color: Colors.teal),
                  onTap: () {
                    setState(() {
                      if (_batsman1OnStrike) {
                        _batsman1Name = player;
                        _batsman1Runs = 0;
                        _batsman1Balls = 0;
                      } else {
                        _batsman2Name = player;
                        _batsman2Runs = 0;
                        _batsman2Balls = 0;
                      }
                    });
                    Navigator.pop(context);
                    _scheduleAutoSave();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveScore() async {
    if (!_isReady) return;

    try {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final entity = CricketLiveScoreEntity(
        tournamentId: widget.tournament.id,
        battingTeamName: _selectedBattingTeam ?? 'Batting Team',
        bowlingTeamName: _selectedBowlingTeam ?? 'Bowling Team',
        runs: _runs,
        wickets: _wickets,
        overs: _overs,
        balls: _balls,
        matchStatus: _matchStatus,
        batsman1Name: _batsman1Name,
        batsman1Runs: _batsman1Runs,
        batsman1Balls: _batsman1Balls,
        batsman2Name: _batsman2Name,
        batsman2Runs: _batsman2Runs,
        batsman2Balls: _batsman2Balls,
        batsman1OnStrike: _batsman1OnStrike,
        bowlerName: _bowlerName,
        bowlerOvers: _bowlerOvers,
        bowlerMaidens: _bowlerMaidens,
        bowlerRuns: _bowlerRuns,
        bowlerWickets: _bowlerWickets,
        recentBalls: _recentBalls,
        incidents: _incidents,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        updatedByUid: userProfile.uid,
        updatedByName: userProfile.name,
        updatedAt: DateTime.now(),
      );

      await ref.read(cricketLiveScoreRepositoryProvider).saveLiveScore(entity);

      if (mounted) {
        setState(() => _saveLabel = 'Saved just now');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveLabel = 'Save failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save live score: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Live Desk'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last ball',
            onPressed: _history.isNotEmpty ? _undo : null,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Live Dashboard Card ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade900, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_cricket, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.tournament.tournamentName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _saveLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Score display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedBattingTeam ?? 'Batting Team',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_runs/$_wickets',
                                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($_overs.$_balls ov)',
                                style: TextStyle(color: Colors.teal.shade100, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'BOWLING',
                            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedBowlingTeam ?? 'Bowling Team',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _matchStatus,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Recent Balls timeline
                  if (_recentBalls.isNotEmpty) ...[
                    const Divider(height: 24, color: Colors.white24),
                    Row(
                      children: [
                        const Text(
                          'Recent: ',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: _recentBalls.map((ball) {
                              final isWicket = ball == 'W';
                              final isBoundary = ball == '4' || ball == '6';
                              final isExtra = ball.contains('wd') || ball.contains('nb');
                              
                              Color bg = Colors.white24;
                              Color txt = Colors.white;
                              
                              if (isWicket) {
                                bg = Colors.redAccent;
                              } else if (isBoundary) {
                                bg = Colors.amber;
                                txt = Colors.teal.shade900;
                              } else if (isExtra) {
                                bg = Colors.blueGrey.shade800;
                              }
                              
                              return Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  ball,
                                  style: TextStyle(color: txt, fontSize: 12, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),

            // --- Team Config Selectors ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Teams Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _teamNames.contains(_selectedBattingTeam) ? _selectedBattingTeam : null,
                            decoration: const InputDecoration(labelText: 'Batting Team', border: OutlineInputBorder()),
                            items: _teamNames.map((teamName) => DropdownMenuItem(value: teamName, child: Text(teamName, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBattingTeam = val;
                                // Reset batsmen defaults
                                _batsman1Name = _defaultPlayerForTeam(val, 0);
                                _batsman1Runs = 0;
                                _batsman1Balls = 0;
                                _batsman2Name = _defaultPlayerForTeam(val, 1);
                                _batsman2Runs = 0;
                                _batsman2Balls = 0;
                              });
                              _scheduleAutoSave();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _teamNames.contains(_selectedBowlingTeam) ? _selectedBowlingTeam : null,
                            decoration: const InputDecoration(labelText: 'Bowling Team', border: OutlineInputBorder()),
                            items: _teamNames.map((teamName) => DropdownMenuItem(value: teamName, child: Text(teamName, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBowlingTeam = val;
                                // Reset bowler defaults
                                _bowlerName = _defaultPlayerForTeam(val, 0);
                                _bowlerOvers = 0.0;
                                _bowlerMaidens = 0;
                                _bowlerRuns = 0;
                                _bowlerWickets = 0;
                              });
                              _scheduleAutoSave();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Ball-by-ball interactive console ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.teal.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.teal.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Play Control Console',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tapping any action will automatically record runs, increment balls, and manage batsmen scores/strike rotation:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    
                    // Runs input buttons
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionBtn(label: '0 (Dot)', color: Colors.grey.shade100, textColor: Colors.black87, onTap: () => _handleBall('dot', 0, false, false)),
                        _actionBtn(label: '1 (Single)', color: Colors.teal.shade50, textColor: Colors.teal.shade900, onTap: () => _handleBall('1', 1, false, false)),
                        _actionBtn(label: '2 (Double)', color: Colors.teal.shade50, textColor: Colors.teal.shade900, onTap: () => _handleBall('2', 2, false, false)),
                        _actionBtn(label: '3 (Triple)', color: Colors.teal.shade50, textColor: Colors.teal.shade900, onTap: () => _handleBall('3', 3, false, false)),
                        _actionBtn(label: '4 (FOUR)', color: Colors.amber.shade100, textColor: Colors.amber.shade900, onTap: () => _handleBall('4', 4, false, false)),
                        _actionBtn(label: '6 (SIX)', color: Colors.amber.shade200, textColor: Colors.amber.shade900, onTap: () => _handleBall('6', 6, false, false)),
                        _actionBtn(label: '+1 Wide', color: Colors.blue.shade50, textColor: Colors.blue.shade900, onTap: () => _handleBall('wd', 0, true, false)),
                        _actionBtn(label: '+1 No Ball', color: Colors.blue.shade50, textColor: Colors.blue.shade900, onTap: () => _handleBall('nb', 0, true, false)),
                        _actionBtn(label: '🔴 Wicket', color: Colors.red.shade100, textColor: Colors.red.shade900, onTap: () => _handleBall('W', 0, false, true)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Active Batsmen and Bowler Panel ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Players Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // Batsman 1 Row
                    _playerSelectorRow(
                      isStriker: _batsman1OnStrike,
                      onStrikeSelected: () => setState(() {
                        _saveHistoryState();
                        _batsman1OnStrike = true;
                        _scheduleAutoSave();
                      }),
                      labelText: 'Batsman 1 (On Strike)',
                      name: _batsman1Name,
                      runs: _batsman1Runs,
                      balls: _batsman1Balls,
                      playersList: _playersForTeam(_selectedBattingTeam),
                      onNameChanged: (val) => setState(() { _batsman1Name = val; _scheduleAutoSave(); }),
                      onRunsChanged: (delta) => setState(() { _batsman1Runs = (_batsman1Runs + delta).clamp(0, 500); _scheduleAutoSave(); }),
                      onBallsChanged: (delta) => setState(() { _batsman1Balls = (_batsman1Balls + delta).clamp(0, 500); _scheduleAutoSave(); }),
                    ),
                    const Divider(height: 20),
                    
                    // Batsman 2 Row
                    _playerSelectorRow(
                      isStriker: !_batsman1OnStrike,
                      onStrikeSelected: () => setState(() {
                        _saveHistoryState();
                        _batsman1OnStrike = false;
                        _scheduleAutoSave();
                      }),
                      labelText: 'Batsman 2',
                      name: _batsman2Name,
                      runs: _batsman2Runs,
                      balls: _batsman2Balls,
                      playersList: _playersForTeam(_selectedBattingTeam),
                      onNameChanged: (val) => setState(() { _batsman2Name = val; _scheduleAutoSave(); }),
                      onRunsChanged: (delta) => setState(() { _batsman2Runs = (_batsman2Runs + delta).clamp(0, 500); _scheduleAutoSave(); }),
                      onBallsChanged: (delta) => setState(() { _batsman2Balls = (_batsman2Balls + delta).clamp(0, 500); _scheduleAutoSave(); }),
                    ),
                    const Divider(height: 24),

                    // Bowler Row
                    const Text('Active Bowler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _playersForTeam(_selectedBowlingTeam).contains(_bowlerName) ? _bowlerName : null,
                            decoration: const InputDecoration(labelText: 'Bowler Name', border: OutlineInputBorder()),
                            items: _playersForTeam(_selectedBowlingTeam).map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() { _bowlerName = val; _scheduleAutoSave(); }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: _bowlerWickets.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Wkts', border: OutlineInputBorder()),
                            onChanged: (val) {
                              final intVal = int.tryParse(val) ?? 0;
                              setState(() => _bowlerWickets = intVal);
                              _scheduleAutoSave();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: _bowlerRuns.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Runs Con', border: OutlineInputBorder()),
                            onChanged: (val) {
                              final intVal = int.tryParse(val) ?? 0;
                              setState(() => _bowlerRuns = intVal);
                              _scheduleAutoSave();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Manual Overrides Panel ---
            ExpansionTile(
              title: const Text('Manual Overrides (Correction panel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              children: [
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('runs_$_runs'),
                                initialValue: _runs.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Total Runs', border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final intVal = int.tryParse(val) ?? 0;
                                  setState(() => _runs = intVal);
                                  _scheduleAutoSave();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('wickets_$_wickets'),
                                initialValue: _wickets.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Total Wickets', border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final intVal = int.tryParse(val) ?? 0;
                                  setState(() => _wickets = intVal);
                                  _scheduleAutoSave();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('overs_$_overs'),
                                initialValue: _overs.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Overs completed', border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final intVal = int.tryParse(val) ?? 0;
                                  setState(() => _overs = intVal);
                                  _scheduleAutoSave();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('balls_$_balls'),
                                initialValue: _balls.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Balls in current over', border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final intVal = int.tryParse(val) ?? 0;
                                  setState(() => _balls = intVal);
                                  _scheduleAutoSave();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Match status & state chip card ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Match Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statusChip('Not Started'),
                        _statusChip('Live'),
                        _statusChip('Innings Break'),
                        _statusChip('Finished'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Live Match Note/Commentary',
                        hintText: 'e.g. Needs 32 runs in 18 balls to win...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _scheduleAutoSave(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({required String label, required Color color, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _playerSelectorRow({
    required bool isStriker,
    required VoidCallback onStrikeSelected,
    required String labelText,
    required String? name,
    required int runs,
    required int balls,
    required List<String> playersList,
    required ValueChanged<String?> onNameChanged,
    required ValueChanged<int> onRunsChanged,
    required ValueChanged<int> onBallsChanged,
  }) {
    return Row(
      children: [
        Radio<bool>(
          value: true,
          groupValue: isStriker,
          activeColor: Colors.teal.shade800,
          onChanged: (_) => onStrikeSelected(),
        ),
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<String>(
            value: playersList.contains(name) ? name : null,
            decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
            items: playersList.map((pName) => DropdownMenuItem(value: pName, child: Text(pName, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: onNameChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: ValueKey('runs_$runs'),
            initialValue: runs.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Runs', border: OutlineInputBorder()),
            onChanged: (val) {
              final parsed = int.tryParse(val) ?? 0;
              onRunsChanged(parsed - runs);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: ValueKey('balls_$balls'),
            initialValue: balls.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Balls', border: OutlineInputBorder()),
            onChanged: (val) {
              final parsed = int.tryParse(val) ?? 0;
              onBallsChanged(parsed - balls);
            },
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final isSelected = _matchStatus == status;
    return ChoiceChip(
      label: Text(status),
      selected: isSelected,
      selectedColor: Colors.teal.shade100,
      onSelected: (val) {
        if (val) {
          setState(() => _matchStatus = status);
          _scheduleAutoSave();
        }
      },
    );
  }
}
