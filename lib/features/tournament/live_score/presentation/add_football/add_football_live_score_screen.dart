import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/auth_controller.dart';
import '../../../domain/tournament_entity.dart';
import '../../data/football_live_score_repository.dart';
import '../../domain/football_live_score_entity.dart';

class AddFootballLiveScoreScreen extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const AddFootballLiveScoreScreen({super.key, required this.tournament});

  @override
  ConsumerState<AddFootballLiveScoreScreen> createState() => _AddFootballLiveScoreScreenState();
}

class _AddFootballLiveScoreScreenState extends ConsumerState<AddFootballLiveScoreScreen> {
  late final TextEditingController _hostTeamController;
  late final TextEditingController _guestTeamController;
  late final TextEditingController _noteController;
  late final TextEditingController _foulController;
  Timer? _saveDebounce;
  int _hostScore = 0;
  int _guestScore = 0;
  double _minute = 0;
  String _matchStatus = 'Live';
  String _selectedEventType = 'Yellow card';
  String? _selectedEventTeam;
  String? _selectedEventPlayer;
  bool _isSaving = false;
  bool _isReady = false;
  List<String> _foulEvents = [];
  String _saveLabel = 'Auto-saving enabled';

  // Live Timer states
  Timer? _matchTimer;
  bool _isTimerRunning = false;
  int _elapsedSeconds = 0;
  DateTime? _timerStartedAt;
  int _timerAccumulatedSeconds = 0;

  @override
  void initState() {
    super.initState();
    final existingScore = ref.read(footballLiveScoreStreamProvider(widget.tournament.id)).asData?.value;
    _hostTeamController = TextEditingController(text: existingScore?.hostTeamName ?? _defaultHostTeam());
    _guestTeamController = TextEditingController(text: existingScore?.guestTeamName ?? _defaultGuestTeam());
    _noteController = TextEditingController(text: existingScore?.note ?? '');
    _foulController = TextEditingController();
    _hostScore = existingScore?.hostTeamScore ?? 0;
    _guestScore = existingScore?.guestTeamScore ?? 0;

    // Restore persistent states
    _isTimerRunning = existingScore?.isTimerRunning ?? false;
    _timerStartedAt = existingScore?.timerStartedAt;
    _timerAccumulatedSeconds = existingScore?.timerAccumulatedSeconds ?? ((existingScore?.minute ?? 0) * 60);

    if (_isTimerRunning && _timerStartedAt != null) {
      final difference = DateTime.now().difference(_timerStartedAt!).inSeconds;
      _elapsedSeconds = (_timerAccumulatedSeconds + difference).clamp(0, 7200);
    } else {
      _elapsedSeconds = _timerAccumulatedSeconds.clamp(0, 7200);
    }
    _minute = (_elapsedSeconds ~/ 60).toDouble();

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
    _foulController.dispose();
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
            _elapsedSeconds = (_timerAccumulatedSeconds + difference).clamp(0, 7200);
          } else {
            _elapsedSeconds = _timerAccumulatedSeconds.clamp(0, 7200);
          }
          _minute = (_elapsedSeconds ~/ 60).toDouble();
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
      _saveScore(); // Save immediately when pausing
    } else {
      setState(() {
        _isTimerRunning = true;
        _timerStartedAt = DateTime.now();
        _timerAccumulatedSeconds = _elapsedSeconds;
      });
      _startTickingLoop();
      _saveScore(); // Save immediately when resuming
    }
  }

  void _adjustTimer(int newSeconds) {
    setState(() {
      _elapsedSeconds = newSeconds.clamp(0, 7200);
      _minute = (_elapsedSeconds ~/ 60).toDouble();
      _timerAccumulatedSeconds = _elapsedSeconds;
      if (_isTimerRunning) {
        _timerStartedAt = DateTime.now();
      } else {
        _timerStartedAt = null;
      }
    });
    _saveScore(); // Save immediately to database on manual time adjustment
  }

  void _changeScore({required bool host, required int delta}) {
    setState(() {
      if (host) {
        _hostScore = (_hostScore + delta).clamp(0, 99);
      } else {
        _guestScore = (_guestScore + delta).clamp(0, 99);
      }
    });
    _scheduleAutoSave();
  }

  void _addFoul(String value) {
    final normalizedNote = value.trim();
    final normalizedType = _selectedEventType.trim();
    final teamName = _selectedEventTeam?.trim() ?? '';
    final playerName = _selectedEventPlayer?.trim() ?? '';
    if (teamName.isEmpty || playerName.isEmpty) return;

    final minuteStr = "${_minute.round()}'";
    final segments = [minuteStr, normalizedType, teamName, playerName];
    if (normalizedNote.isNotEmpty) {
      segments.add(normalizedNote);
    }

    final eventText = segments.join(' • ');
    setState(() {
      _foulEvents = [..._foulEvents, eventText];
      _foulController.clear();

      // Auto-increment scores on Goals
      if (normalizedType.toLowerCase() == 'goal') {
        if (teamName == _hostTeamController.text.trim()) {
          _hostScore = (_hostScore + 1).clamp(0, 99);
        } else if (teamName == _guestTeamController.text.trim()) {
          _guestScore = (_guestScore + 1).clamp(0, 99);
        }
      }
    });
    _scheduleAutoSave();
  }

  void _removeFoul(String value) {
    setState(() {
      _foulEvents = _foulEvents.where((event) => event != value).toList();
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

      final entity = FootballLiveScoreEntity(
        tournamentId: widget.tournament.id,
        hostTeamName: _hostTeamController.text.trim(),
        guestTeamName: _guestTeamController.text.trim(),
        hostTeamScore: _hostScore,
        guestTeamScore: _guestScore,
        matchStatus: _matchStatus,
        minute: _minute <= 0 ? null : _minute.round(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        foulEvents: _foulEvents,
        updatedByUid: userProfile.uid,
        updatedByName: userProfile.name,
        updatedAt: DateTime.now(),
        timerStartedAt: _timerStartedAt,
        timerAccumulatedSeconds: _timerAccumulatedSeconds,
        isTimerRunning: _isTimerRunning,
      );

      await ref.read(footballLiveScoreRepositoryProvider).saveLiveScore(entity);

      if (mounted) {
        setState(() => _saveLabel = 'Saved just now');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveLabel = 'Save failed');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save live score: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _scoreControl({required String teamName, required int score, required bool isHost}) {
    final textColor = isHost ? AppColors.footballHostTextColor : AppColors.footballGuestTextColor;
    final gradient = isHost
        ? [AppColors.footballHostGradientTop, AppColors.footballHostGradientBottom]
        : [AppColors.footballGuestGradientTop, AppColors.footballGuestGradientBottom];

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.footballBorderColor),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(teamName, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
              child: Text(
                score.toString(),
                key: ValueKey('${teamName}_$score'),
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreButton(icon: Icons.remove, onTap: () => _changeScore(host: isHost, delta: -1)),
                const SizedBox(width: 14),
                _ScoreButton(icon: Icons.add, onTap: () => _changeScore(host: isHost, delta: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Football Live Desk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header Card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.footballHeaderGradientTop, AppColors.footballHeaderGradientBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.shadowDark, blurRadius: 18, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, color: AppColors.footballHostTextColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.tournament.tournamentName,
                        style: const TextStyle(color: AppColors.footballHostTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.overlayWhiteMid, borderRadius: BorderRadius.circular(999)),
                      child: Text(_saveLabel, style: const TextStyle(color: AppColors.footballHostTextColor, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _scoreControl(teamName: _hostTeamController.text, score: _hostScore, isHost: true),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.overlayWhiteLight, borderRadius: BorderRadius.circular(14)),
                          child: const Text('VS', style: TextStyle(color: AppColors.footballHostTextColor, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 18),
                        Text(_matchStatus, style: const TextStyle(color: AppColors.footballHostTextColor, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    _scoreControl(teamName: _guestTeamController.text, score: _guestScore, isHost: false),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Timer Widget ──────────────────────────────────────────────
                Builder(
                  builder: (context) {
                    int matchDuration = 90;
                    for (final fixture in widget.tournament.fixtures) {
                      if (fixture['duration'] != null) {
                        final d = int.tryParse(fixture['duration'].toString());
                        if (d != null) {
                          matchDuration = d;
                          break;
                        }
                      }
                    }

                    final minutes = _elapsedSeconds ~/ 60;
                    final seconds = _elapsedSeconds % 60;
                    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                    Widget stoppageChip(String label, int minutesToAdd) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: AppColors.footballStoppageChipBg,
                          label: Text(label, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                          side: const BorderSide(color: Colors.white24),
                          onPressed: () => _adjustTimer(_elapsedSeconds + (minutesToAdd * 60)),
                        ),
                      );
                    }

                    Widget presetButton(String label, int targetMinutes) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: AppColors.footballPresetChipBg,
                          label: Text(label, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                          side: const BorderSide(color: Colors.amberAccent),
                          onPressed: () => _adjustTimer(targetMinutes * 60),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.overlayWhiteLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: AppColors.footballHostTextColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isTimerRunning ? 'Match Timer Running' : 'Match Timer Paused',
                                    style: const TextStyle(color: AppColors.footballHostTextColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Text(
                                'Limit: $matchDuration Mins',
                                style: const TextStyle(color: AppColors.subTextDark, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_elapsedSeconds / (matchDuration * 60)).clamp(0.0, 1.0),
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.footballClockGlow),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left Column: Controls
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _toggleTimer,
                                      icon: Icon(
                                        _isTimerRunning ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        _isTimerRunning
                                            ? 'PAUSE TIMER'
                                            : (_elapsedSeconds == 0 ? 'START MATCH' : 'RESUME TIMER'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isTimerRunning ? AppColors.footballTimerRunningBg : AppColors.footballTimerStoppedBg,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.replay, color: Colors.white, size: 20),
                                          tooltip: 'Reset to 0:00',
                                          onPressed: () => _adjustTimer(0),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                          tooltip: '-1 Min',
                                          onPressed: () => _adjustTimer(_elapsedSeconds - 60),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                          tooltip: '+1 Min',
                                          onPressed: () => _adjustTimer(_elapsedSeconds + 60),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column: LED Clock
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Color.fromRGBO(105, 240, 174, 0.4), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color.fromRGBO(105, 240, 174, 0.2),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        timeStr,
                                        style: const TextStyle(
                                          color: AppColors.footballClockGlow,
                                          fontSize: 28,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Add Stoppage / Injury Time',
                                    style: TextStyle(color: AppColors.subTextDark, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  if (minutes == matchDuration ~/ 2 || minutes == matchDuration)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.stoppageRedBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.redAccent, width: 0.5),
                                      ),
                                      child: const Text(
                                        'Stoppage Phase',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    stoppageChip('+1m', 1),
                                    stoppageChip('+2m', 2),
                                    stoppageChip('+3m', 3),
                                    stoppageChip('+5m', 5),
                                    stoppageChip('+10m', 10),
                                    presetButton('Go 45m', 45),
                                    presetButton('Go 90m', 90),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Match State Card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.footballMatchCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.footballBorderColor),
              boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match State', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(label: 'Not Started', selected: _matchStatus == 'Not Started', onTap: () { setState(() => _matchStatus = 'Not Started'); _scheduleAutoSave(); }),
                    _StatusChip(label: 'Live', selected: _matchStatus == 'Live', onTap: () { setState(() => _matchStatus = 'Live'); _scheduleAutoSave(); }),
                    _StatusChip(label: 'Half Time', selected: _matchStatus == 'Half Time', onTap: () { setState(() => _matchStatus = 'Half Time'); _scheduleAutoSave(); }),
                    _StatusChip(label: 'Finished', selected: _matchStatus == 'Finished', onTap: () { setState(() => _matchStatus = 'Finished'); _scheduleAutoSave(); }),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.footballIncidentsBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.footballIncidentsBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Incidents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickEventChip(label: 'Goal', color: AppColors.eventGoalBg, textColor: AppColors.eventGoalText, selected: _selectedEventType == 'Goal', onTap: () => setState(() => _selectedEventType = 'Goal')),
                          _QuickEventChip(label: 'Yellow card', color: AppColors.eventYellowBg, textColor: AppColors.eventYellowText, selected: _selectedEventType == 'Yellow card', onTap: () => setState(() => _selectedEventType = 'Yellow card')),
                          _QuickEventChip(label: 'Red card', color: AppColors.eventRedBg, textColor: AppColors.eventRedText, selected: _selectedEventType == 'Red card', onTap: () => setState(() => _selectedEventType = 'Red card')),
                          _QuickEventChip(label: 'Foul', color: AppColors.eventFoulBg, textColor: AppColors.eventFoulText, selected: _selectedEventType == 'Foul', onTap: () => setState(() => _selectedEventType = 'Foul')),
                          _QuickEventChip(label: 'Penalty', color: AppColors.eventPenaltyBg, textColor: AppColors.eventPenaltyText, selected: _selectedEventType == 'Penalty', onTap: () => setState(() => _selectedEventType = 'Penalty')),
                          _QuickEventChip(label: 'Offside', color: AppColors.eventOffsideBg, textColor: AppColors.eventOffsideText, selected: _selectedEventType == 'Offside', onTap: () => setState(() => _selectedEventType = 'Offside')),
                          _QuickEventChip(label: 'Corner', color: AppColors.eventCornerBg, textColor: AppColors.eventCornerText, selected: _selectedEventType == 'Corner', onTap: () => setState(() => _selectedEventType = 'Corner')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _teamNames.contains(_selectedEventTeam) ? _selectedEventTeam : null,
                        decoration: const InputDecoration(labelText: 'Team', border: OutlineInputBorder()),
                        items: _teamNames
                            .map(
                              (teamName) => DropdownMenuItem(
                                value: teamName,
                                child: Text(teamName, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEventTeam = value;
                            final players = _playersForTeam(value);
                            _selectedEventPlayer = players.isNotEmpty ? players.first : null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: (_selectedEventPlayer != null && _playersForTeam(_selectedEventTeam).contains(_selectedEventPlayer))
                            ? _selectedEventPlayer
                            : null,
                        decoration: const InputDecoration(labelText: 'Player', border: OutlineInputBorder()),
                        items: _playersForTeam(_selectedEventTeam)
                            .map(
                              (playerName) => DropdownMenuItem(
                                value: playerName,
                                child: Text(playerName, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedEventPlayer = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _foulController,
                              decoration: const InputDecoration(
                                labelText: 'Incident note (optional)',
                                hintText: '2nd yellow, handball, dangerous tackle',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: _addFoul,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _addFoul(_foulController.text),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_foulEvents.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _foulEvents
                        .map(
                          (event) => InputChip(
                            avatar: const Icon(Icons.sports_soccer, size: 18),
                            label: Text(event),
                            onDeleted: () => _removeFoul(event),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Match note',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _scheduleAutoSave(),
                ),
                const SizedBox(height: 10),
                Text(
                  _isSaving ? 'Saving changes...' : 'Changes are saved automatically.',
                  style: const TextStyle(color: AppColors.subTextLight),
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
      color: AppColors.footballScoreButtonBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.footballHostTextColor),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _QuickEventChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool selected;
  final VoidCallback onTap;

  const _QuickEventChip({required this.label, required this.color, required this.textColor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      selected: selected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.55),
      side: BorderSide(color: textColor.withOpacity(0.2)),
      onSelected: (_) => onTap(),
    );
  }
}