import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/auth_controller.dart';
import '../../../domain/tournament_entity.dart';
import '../../data/basketball_live_score_repository.dart';
import '../../domain/basketball_live_score_entity.dart';

class AddBasketballLiveScoreScreen extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const AddBasketballLiveScoreScreen({super.key, required this.tournament});

  @override
  ConsumerState<AddBasketballLiveScoreScreen> createState() => _AddBasketballLiveScoreScreenState();
}

class _AddBasketballLiveScoreScreenState extends ConsumerState<AddBasketballLiveScoreScreen> {
  late final TextEditingController _hostTeamController;
  late final TextEditingController _guestTeamController;
  late final TextEditingController _noteController;
  late final TextEditingController _customIncidentController;
  Timer? _saveDebounce;

  // Basketball State
  int _hostScore = 0;
  int _guestScore = 0;
  int _hostFouls = 0;
  int _guestFouls = 0;
  int _currentQuarter = 1;
  String _matchStatus = 'Live';
  bool _isSaving = false;
  bool _isReady = false;
  List<String> _foulEvents = [];
  String _saveLabel = 'Auto-saving enabled';

  // Event Log Form States
  String _selectedPlayType = '2 Points';
  String? _selectedEventTeam;
  String? _selectedEventPlayer;

  // Live Timer states (counting down or up, basketball counts down or up, but let's count up to align with football/cricket elapsed seconds, or count down from quarter limit. Let's stick to elapsed quarter time for robust calculations)
  Timer? _matchTimer;
  bool _isTimerRunning = false;
  int _elapsedSeconds = 0;
  DateTime? _timerStartedAt;
  int _timerAccumulatedSeconds = 0;

  @override
  void initState() {
    super.initState();
    final existingScore = ref.read(basketballLiveScoreStreamProvider(widget.tournament.id)).asData?.value;
    _hostTeamController = TextEditingController(text: existingScore?.hostTeamName ?? _defaultHostTeam());
    _guestTeamController = TextEditingController(text: existingScore?.guestTeamName ?? _defaultGuestTeam());
    _noteController = TextEditingController(text: existingScore?.note ?? '');
    _customIncidentController = TextEditingController();
    _hostScore = existingScore?.hostTeamScore ?? 0;
    _guestScore = existingScore?.guestTeamScore ?? 0;
    _hostFouls = existingScore?.hostTeamFouls ?? 0;
    _guestFouls = existingScore?.guestTeamFouls ?? 0;
    _currentQuarter = existingScore?.currentQuarter ?? 1;

    // Restore persistent timer states
    _isTimerRunning = existingScore?.isTimerRunning ?? false;
    _timerStartedAt = existingScore?.timerStartedAt;
    _timerAccumulatedSeconds = existingScore?.timerAccumulatedSeconds ?? 0;

    if (_isTimerRunning && _timerStartedAt != null) {
      final difference = DateTime.now().difference(_timerStartedAt!).inSeconds;
      _elapsedSeconds = (_timerAccumulatedSeconds + difference).clamp(0, 3600);
    } else {
      _elapsedSeconds = _timerAccumulatedSeconds.clamp(0, 3600);
    }

    _matchStatus = existingScore?.matchStatus ?? 'Live';
    _foulEvents = List<String>.from(existingScore?.foulEvents ?? const []);
    _selectedEventTeam = _teamNames.isNotEmpty ? _teamNames.first : null;
    _selectedEventPlayer = _playersForTeam(_selectedEventTeam).isNotEmpty ? _playersForTeam(_selectedEventTeam).first : null;
    _isReady = true;

    if (_isTimerRunning) {
      _startTickingLoop();
    }
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    _saveDebounce?.cancel();
    _hostTeamController.dispose();
    _guestTeamController.dispose();
    _noteController.dispose();
    _customIncidentController.dispose();
    super.dispose();
  }

  String _defaultHostTeam() {
    return widget.tournament.registeredTeams.isNotEmpty
        ? widget.tournament.registeredTeams.first['teamName']?.toString() ?? 'Team A'
        : 'Team A';
  }

  String _defaultGuestTeam() {
    if (widget.tournament.registeredTeams.length > 1) {
      return widget.tournament.registeredTeams[1]['teamName']?.toString() ?? 'Team B';
    }
    return 'Team B';
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

  void _startTickingLoop() {
    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerStartedAt != null) {
            final difference = DateTime.now().difference(_timerStartedAt!).inSeconds;
            _elapsedSeconds = (_timerAccumulatedSeconds + difference).clamp(0, 3600);
          } else {
            _elapsedSeconds = _timerAccumulatedSeconds.clamp(0, 3600);
          }
        });
        if (_elapsedSeconds % 15 == 0) {
          _scheduleAutoSave();
        }
      }
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _matchTimer?.cancel();
      setState(() {
        _isTimerRunning = false;
        _timerAccumulatedSeconds = _elapsedSeconds;
        _timerStartedAt = null;
      });
      _saveScore();
    } else {
      setState(() {
        _isTimerRunning = true;
        _timerStartedAt = DateTime.now();
        _timerAccumulatedSeconds = _elapsedSeconds;
      });
      _startTickingLoop();
      _saveScore();
    }
  }

  void _adjustTimer(int newSeconds) {
    setState(() {
      _elapsedSeconds = newSeconds.clamp(0, 3600);
      _timerAccumulatedSeconds = _elapsedSeconds;
      if (_isTimerRunning) {
        _timerStartedAt = DateTime.now();
      } else {
        _timerStartedAt = null;
      }
    });
    _saveScore();
  }

  void _changeScore({required bool host, required int delta}) {
    setState(() {
      if (host) {
        _hostScore = (_hostScore + delta).clamp(0, 199);
      } else {
        _guestScore = (_guestScore + delta).clamp(0, 199);
      }
    });
    _scheduleAutoSave();
  }

  void _changeFouls({required bool host, required int delta}) {
    setState(() {
      if (host) {
        _hostFouls = (_hostFouls + delta).clamp(0, 9);
      } else {
        _guestFouls = (_guestFouls + delta).clamp(0, 9);
      }
    });
    _scheduleAutoSave();
  }

  void _changeQuarter(int quarter) {
    setState(() {
      _currentQuarter = quarter.clamp(1, 5);
      // Under basketball rules, team fouls reset at the end of each quarter
      _hostFouls = 0;
      _guestFouls = 0;
      // Also reset quarter timer to 0:00
      _elapsedSeconds = 0;
      _timerAccumulatedSeconds = 0;
      _timerStartedAt = null;
      _isTimerRunning = false;
      _matchTimer?.cancel();
    });
    _saveScore();
  }

  void _logIncident(String customText) {
    final teamName = _selectedEventTeam?.trim() ?? '';
    final playerName = _selectedEventPlayer?.trim() ?? '';
    if (teamName.isEmpty || playerName.isEmpty) return;

    final quarterLabel = _currentQuarter == 5 ? 'OT' : 'Q$_currentQuarter';
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    final normalizedPlay = customText.trim().isNotEmpty ? customText.trim() : _selectedPlayType;
    final eventText = '$quarterLabel $timeStr • $normalizedPlay • $teamName • $playerName';

    setState(() {
      _foulEvents = [..._foulEvents, eventText];
      _customIncidentController.clear();

      // Automatically add points or team fouls based on logged play
      final playLower = normalizedPlay.toLowerCase();
      final isHost = teamName == _hostTeamController.text.trim();

      if (playLower.contains('3 pointer')) {
        _changeScore(host: isHost, delta: 3);
      } else if (playLower.contains('2 points') || playLower.contains('field goal')) {
        _changeScore(host: isHost, delta: 2);
      } else if (playLower.contains('free throw') || playLower.contains('1 point')) {
        _changeScore(host: isHost, delta: 1);
      } else if (playLower.contains('foul')) {
        _changeFouls(host: isHost, delta: 1);
      }
    });
    _scheduleAutoSave();
  }

  void _removeIncident(String eventText) {
    setState(() {
      _foulEvents = _foulEvents.where((e) => e != eventText).toList();
    });
    _scheduleAutoSave();
  }

  Future<void> _saveScore() async {
    if (!_isReady) return;
    setState(() => _isSaving = true);

    try {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final entity = BasketballLiveScoreEntity(
        tournamentId: widget.tournament.id,
        hostTeamName: _hostTeamController.text.trim(),
        guestTeamName: _guestTeamController.text.trim(),
        hostTeamScore: _hostScore,
        guestTeamScore: _guestScore,
        hostTeamFouls: _hostFouls,
        guestTeamFouls: _guestFouls,
        currentQuarter: _currentQuarter,
        matchStatus: _matchStatus,
        foulEvents: _foulEvents,
        updatedByUid: userProfile.uid,
        updatedByName: userProfile.name,
        updatedAt: DateTime.now(),
        timerStartedAt: _timerStartedAt,
        timerAccumulatedSeconds: _timerAccumulatedSeconds,
        isTimerRunning: _isTimerRunning,
      );

      await ref.read(basketballLiveScoreRepositoryProvider).saveLiveScore(entity);

      if (mounted) {
        setState(() => _saveLabel = 'Saved just now');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveLabel = 'Save failed');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save score: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _scoreControl({required String teamName, required int score, required int fouls, required bool isHost}) {
    final primaryColor = isHost ? Colors.orange.shade800 : Colors.blue.shade900;
    final gradient = isHost
        ? [Colors.orange.shade800, Colors.orange.shade600]
        : [Colors.blue.shade800, Colors.blue.shade600];

    final isBonus = fouls >= 5;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(
              teamName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                score.toString(),
                key: ValueKey('${teamName}_$score'),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreButton(icon: Icons.remove, onTap: () => _changeScore(host: isHost, delta: -1)),
                const SizedBox(width: 10),
                _ScoreButton(icon: Icons.add, onTap: () => _changeScore(host: isHost, delta: 1)),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FOULS', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$fouls/5', style: TextStyle(color: isBonus ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (isBonus) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                            child: const Text('BONUS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeFouls(host: isHost, delta: -1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.remove, color: Colors.white, size: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _changeFouls(host: isHost, delta: 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int quarterLimit = 10;
    for (final fixture in widget.tournament.fixtures) {
      if (fixture['quarterDuration'] != null) {
        final qd = int.tryParse(fixture['quarterDuration'].toString());
        if (qd != null) {
          quarterLimit = qd;
          break;
        }
      }
    }

    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Basketball Live Desk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade900, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.shade800.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade800.withOpacity(0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_basketball, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.tournament.tournamentName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text(_saveLabel, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _scoreControl(
                      teamName: _hostTeamController.text,
                      score: _hostScore,
                      fouls: _hostFouls,
                      isHost: true,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                          child: const Text('VS', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _matchStatus,
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    _scoreControl(
                      teamName: _guestTeamController.text,
                      score: _guestScore,
                      fouls: _guestFouls,
                      isHost: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _isTimerRunning ? 'Clock Ticking' : 'Clock Paused',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      'Quarter Limit: $quarterLimit Mins',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_elapsedSeconds / (quarterLimit * 60)).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 14),
                // Side-by-Side controls
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Controls (Start / Pause, Replay, Adjustments)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _toggleTimer,
                            icon: Icon(
                              _isTimerRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                              size: 18,
                            ),
                            label: Text(
                              _isTimerRunning
                                  ? 'PAUSE CLOCK'
                                  : (_elapsedSeconds == 0 ? 'START QUARTER' : 'RESUME CLOCK'),
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 11, color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTimerRunning ? Colors.redAccent : Colors.orangeAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay, color: Colors.white, size: 18),
                                tooltip: 'Reset Qtr Clock',
                                onPressed: () => _adjustTimer(0),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                                tooltip: '-1 Min',
                                onPressed: () => _adjustTimer(_elapsedSeconds - 60),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                tooltip: '+1 Min',
                                onPressed: () => _adjustTimer(_elapsedSeconds + 60),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Column: Live Orange Monospace LED Timer Clock Box
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                // Quarter Control Selector Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Match Quarter',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        final qNum = index + 1;
                        final isSelected = _currentQuarter == qNum;
                        final label = qNum == 5 ? 'OT' : 'Q$qNum';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.orange.shade800 : Colors.white10,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _changeQuarter(qNum),
                              child: Text(label),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Basketball Scoring Event Creator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Score / Play Incident',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPlayType,
                  decoration: InputDecoration(
                    labelText: 'Select Play Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '3 Pointer', child: Text('🏀 3 Pointer (Goal)')),
                    DropdownMenuItem(value: '2 Points', child: Text('🏀 2 Points (Field Goal)')),
                    DropdownMenuItem(value: 'Free Throw', child: Text('🏀 Free Throw (1 Point)')),
                    DropdownMenuItem(value: 'Personal Foul', child: Text('⚠️ Personal Foul')),
                    DropdownMenuItem(value: 'Technical Foul', child: Text('🟨 Technical Foul')),
                    DropdownMenuItem(value: 'Timeout', child: Text('⏱️ Timeout')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPlayType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEventTeam,
                        decoration: InputDecoration(
                          labelText: 'Team',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _teamNames.map((team) => DropdownMenuItem(value: team, child: Text(team, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedEventTeam = val;
                            final players = _playersForTeam(val);
                            _selectedEventPlayer = players.isNotEmpty ? players.first : null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEventPlayer,
                        decoration: InputDecoration(
                          labelText: 'Player',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _playersForTeam(_selectedEventTeam).map((player) => DropdownMenuItem(value: player, child: Text(player, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setState(() => _selectedEventPlayer = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customIncidentController,
                  decoration: InputDecoration(
                    labelText: 'Custom Play Note (Optional)',
                    hintText: 'e.g. Steal / Block / Assist details',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _logIncident(_customIncidentController.text),
                    child: const Text('LOG PLAY & AUTOMATE SCORE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Game Logs List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match Commentary & Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                if (_foulEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No plays logged yet. Use the panel above to record incidents.', style: TextStyle(color: Colors.black45, fontSize: 12)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _foulEvents.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final item = _foulEvents[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () => _removeIncident(item),
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Match notes & Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match Control Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _matchStatus,
                  decoration: InputDecoration(
                    labelText: 'Overall Match Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Live', child: Text('🟢 Live / Active')),
                    DropdownMenuItem(value: 'Quarter Break', child: Text('🟡 Quarter Break')),
                    DropdownMenuItem(value: 'Finished', child: Text('🔴 Finished / Completed')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _matchStatus = val);
                      _scheduleAutoSave();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Host Notes / Summary',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => _scheduleAutoSave(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ScoreButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
