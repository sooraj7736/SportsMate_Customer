import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _minute = (existingScore?.minute ?? 0).toDouble();
    _matchStatus = existingScore?.matchStatus ?? 'Live';
    _foulEvents = List<String>.from(existingScore?.foulEvents ?? const []);
    _selectedEventTeam = _teamNames.isNotEmpty ? _teamNames.first : null;
    _selectedEventPlayer = _playersForTeam(_selectedEventTeam).isNotEmpty ? _playersForTeam(_selectedEventTeam).first : null;
    _isReady = true;
  }

  @override
  void dispose() {
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
    return players.map((player) => player.toString()).where((player) => player.trim().isNotEmpty).toList();
  }

  void _scheduleAutoSave() {
    if (!_isReady) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 450), _saveScore);
    if (mounted) {
      setState(() => _saveLabel = 'Saving...');
    }
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

    final segments = [normalizedType, teamName, playerName];
    if (normalizedNote.isNotEmpty) {
      segments.add(normalizedNote);
    }

    final eventText = segments.join(' • ');
    setState(() {
      _foulEvents = [..._foulEvents, eventText];
      _foulController.clear();
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
    final textColor = isHost ? Colors.white : Colors.green.shade900;
    final gradient = isHost
        ? [Colors.green.shade800, Colors.green.shade600]
        : [Colors.green.shade50, Colors.green.shade100];

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
    final fieldLine = Colors.green.shade200;

    return Scaffold(
      appBar: AppBar(title: const Text('Football Live Desk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade900, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 18, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.tournament.tournamentName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(999)),
                      child: Text(_saveLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                          child: const Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 18),
                        Text(_matchStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    _scoreControl(teamName: _guestTeamController.text, score: _guestScore, isHost: false),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(_minute <= 0 ? 'Minute not set' : 'Minute ${_minute.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Slider(
                        value: _minute,
                        min: 0,
                        max: 120,
                        divisions: 120,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        label: _minute <= 0 ? 'Off' : _minute.round().toString(),
                        onChanged: (value) {
                          setState(() => _minute = value);
                          _scheduleAutoSave();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: fieldLine),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.green.shade100),
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
                          _QuickEventChip(label: 'Yellow card', color: Colors.amber.shade100, textColor: Colors.amber.shade900, selected: _selectedEventType == 'Yellow card', onTap: () => setState(() => _selectedEventType = 'Yellow card')),
                          _QuickEventChip(label: 'Red card', color: Colors.red.shade100, textColor: Colors.red.shade900, selected: _selectedEventType == 'Red card', onTap: () => setState(() => _selectedEventType = 'Red card')),
                          _QuickEventChip(label: 'Foul', color: Colors.blue.shade50, textColor: Colors.blue.shade900, selected: _selectedEventType == 'Foul', onTap: () => setState(() => _selectedEventType = 'Foul')),
                          _QuickEventChip(label: 'Penalty', color: Colors.green.shade100, textColor: Colors.green.shade900, selected: _selectedEventType == 'Penalty', onTap: () => setState(() => _selectedEventType = 'Penalty')),
                          _QuickEventChip(label: 'Offside', color: Colors.purple.shade50, textColor: Colors.purple.shade900, selected: _selectedEventType == 'Offside', onTap: () => setState(() => _selectedEventType = 'Offside')),
                          _QuickEventChip(label: 'Corner', color: Colors.teal.shade50, textColor: Colors.teal.shade900, selected: _selectedEventType == 'Corner', onTap: () => setState(() => _selectedEventType = 'Corner')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedEventTeam,
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
                        value: _selectedEventPlayer,
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
                  style: TextStyle(color: Colors.grey.shade700),
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
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white),
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