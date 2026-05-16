import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'add_game_screen.dart';
import 'games_feed_controller.dart';

class GamesFeedScreen extends ConsumerStatefulWidget {
  const GamesFeedScreen({super.key});

  @override
  ConsumerState<GamesFeedScreen> createState() => _GamesFeedScreenState();
}

class _GamesFeedScreenState extends ConsumerState<GamesFeedScreen> {
  DateTime? _selectedDay;
  String? _selectedSport;

  static const Color _primaryGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    final gamesStream = ref.watch(allGamesStreamProvider);
    final monthDays = _buildCurrentMonthDays();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Games',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Let\'s Go Game Around',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGameScreen()),
          );
        },
        backgroundColor: _primaryGreen,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Add Game',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: Stack(
        children: [
          gamesStream.when(
            data: (gamesList) {
              final filteredGames = gamesList.where((game) {
                // Filter by selected day
                if (_selectedDay != null && !DateUtils.isSameDay(game.date, _selectedDay)) {
                  return false;
                }
                // Filter by selected sport
                if (_selectedSport != null && _selectedSport != 'All' && game.sportType != _selectedSport) {
                  return false;
                }
                return true;
              }).toList();

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F8F1), Color(0xFFF0FDF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primaryGreen.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_month_outlined, size: 18, color: _primaryGreen),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap a day to filter games.',
                          style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 74,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: monthDays.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final day = monthDays[index];
                              final isSelected = _selectedDay != null && DateUtils.isSameDay(day, _selectedDay);
                              final isToday = DateUtils.isSameDay(day, DateTime.now());

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDay = day;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 56,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _primaryGreen : const Color(0xFFF7F9FC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? _primaryGreen
                                          : isToday
                                              ? _primaryGreen.withValues(alpha: 0.35)
                                              : Colors.black12,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('E').format(day).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        day.day.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _selectedDay == null
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDay = null;
                                    });
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: _primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        if (_selectedDay != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Showing games for ${DateFormat('EEE, MMM d').format(_selectedDay!)}',
                            style: const TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen.withValues(alpha: 0.10),
                            foregroundColor: _primaryGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.location_on_outlined, size: 16),
                          label: const Text(
                            '25 km',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Sport:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButton<String>(
                            underline: const SizedBox(),
                            value: _selectedSport ?? 'All',
                            items: ['All', 'Football', 'Basketball', 'Tennis', 'Cricket', 'Volleyball'].map((sport) {
                              return DropdownMenuItem<String>(
                                value: sport,
                                child: Text(sport),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSport = value == 'All' ? null : value;
                              });
                            },
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            icon: const Icon(Icons.expand_more, size: 18, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredGames.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                _selectedDay == null
                                    ? 'No matches yet. Be the first to add a game!'
                                    : 'No matches found for this day.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                            itemCount: filteredGames.length,
                            itemBuilder: (context, index) {
                              final game = filteredGames[index];
                              final isPublic = game.gameAccess == 'Public';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFBFC),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x08000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _primaryGreen.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.sports_soccer, size: 18, color: _primaryGreen),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: "${game.hostName}'s ",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${game.sportType} game',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 16,
                                                      color: _primaryGreen,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ' at ${game.locationName}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isPublic ? Colors.blue[50] : Colors.amber[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              game.gameAccess,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isPublic ? Colors.blue[700] : Colors.amber[900],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildInfoChip(
                                            icon: Icons.calendar_month_outlined,
                                            label: DateFormat('EEE, MMM d').format(game.date),
                                            backgroundColor: const Color(0xFFF1F5FF),
                                            foregroundColor: const Color(0xFF3451B2),
                                          ),
                                          if (game.startTime.isNotEmpty && game.endTime.isNotEmpty)
                                            _buildInfoChip(
                                              icon: Icons.access_time,
                                              label: '${_formatStoredTime(game.startTime)} - ${_formatStoredTime(game.endTime)}',
                                              backgroundColor: const Color(0xFFF2FBF5),
                                              foregroundColor: _primaryGreen,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.place_outlined, size: 16, color: Colors.black54),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              game.locationName,
                                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Spacer(),
                                          Text(
                                            '${game.numberOfPlayers} slots',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _primaryGreen,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.black45),
                                          const SizedBox(width: 6),
                                          Text(
                                            game.hostName,
                                            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error fetching games: $err')),
          ),
        ],
      ),
    );
  }

  List<DateTime> _buildCurrentMonthDays() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final totalDays = nextMonth.difference(firstDay).inDays;
    return List.generate(totalDays, (index) => DateTime(now.year, now.month, index + 1));
  }

  static String _formatStoredTime(String value) {
    try {
      final parsed = DateFormat('HH:mm').parse(value);
      return DateFormat.jm().format(parsed);
    } catch (_) {
      return value;
    }
  }

  static Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
