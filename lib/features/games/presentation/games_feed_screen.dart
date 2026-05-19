import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/friends/data/friends_repository.dart';
import 'package:sportsmate/features/notifications/data/notifications_repository.dart';
import 'package:sportsmate/features/notifications/domain/notification_entity.dart';
import 'package:sportsmate/features/profile/data/profile_repository.dart';
import 'package:sportsmate/features/profile/domain/athlete_entity.dart';
import 'package:sportsmate/features/sports/data/sports_catalog.dart';
import '../data/games_repository.dart';
import '../domain/game_entity.dart';
import 'add_game_screen.dart';
import 'games_feed_controller.dart';
import 'my_games_dashboard_screen.dart';
import 'package:sportsmate/features/friends/presentation/user_profile_screen.dart';
import 'package:sportsmate/features/games/presentation/game_invitations_screen.dart';
import 'package:sportsmate/features/profile/presentation/address_selection_screen.dart';

class GamesFeedScreen extends ConsumerStatefulWidget {
  const GamesFeedScreen({super.key});

  @override
  ConsumerState<GamesFeedScreen> createState() => _GamesFeedScreenState();
}

class _GamesFeedScreenState extends ConsumerState<GamesFeedScreen> {
  DateTime? _selectedDay;
  String? _selectedSport;
  int? _selectedDistance;

  static const Color _primaryGreen = Color(0xFF1DB954);

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final gamesStream = ref.watch(allGamesStreamProvider);
    final activeAddressMap = ref.watch(activeAddressStreamProvider).value;
    final activeAddress = activeAddressMap != null
        ? Address.fromMap(activeAddressMap)
        : null;
    final sportsAsync = ref.watch(sportsCatalogProvider);
    final availableSports = sportsAsync.asData?.value ?? const [];
    final sportNames = ['All', ...availableSports.map((sport) => sport.name)];
    final selectedSport = _selectedSport != null && sportNames.contains(_selectedSport) ? _selectedSport : 'All';
    final monthDays = _buildCurrentMonthDays();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Games',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddressSelectionScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 13,
                    color: activeAddress != null ? _primaryGreen : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      activeAddress != null
                          ? '${activeAddress.name} (${activeAddress.addressText})'
                          : 'No active address (Tap to set)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: activeAddress != null ? Colors.black54 : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final gameInvites =
                  ref.watch(incomingGameInvitationsStreamProvider).value ?? [];
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 26,
                      color: Colors.black87,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameInvitationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (gameInvites.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${gameInvites.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyGamesDashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.my_library_books, size: 18),
                label: const Text('My Games'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1DB954),
                  side: const BorderSide(color: Color(0xFF1DB954)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                if (_selectedDay != null &&
                    !DateUtils.isSameDay(game.date, _selectedDay)) {
                  return false;
                }
                // Filter by selected sport
                if (_selectedSport != null &&
                    _selectedSport != 'All' &&
                    game.sportType != _selectedSport) {
                  return false;
                }
                // Filter by distance
                if (_selectedDistance != null) {
                  if (activeAddress == null) return false;
                  if (game.lat == null || game.lng == null) return false;
                  final distance = _calculateDistance(
                    activeAddress.lat,
                    activeAddress.lng,
                    game.lat!,
                    game.lng!,
                  );
                  if (distance > _selectedDistance!) {
                    return false;
                  }
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
                      border: Border.all(
                        color: _primaryGreen.withValues(alpha: 0.25),
                      ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: _primaryGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap a day to filter games.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 74,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: monthDays.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final day = monthDays[index];
                              final isSelected =
                                  _selectedDay != null &&
                                  DateUtils.isSameDay(day, _selectedDay);
                              final isToday = DateUtils.isSameDay(
                                day,
                                DateTime.now(),
                              );

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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _primaryGreen
                                        : const Color(0xFFF7F9FC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? _primaryGreen
                                          : isToday
                                          ? _primaryGreen.withValues(
                                              alpha: 0.35,
                                            )
                                          : Colors.black12,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'E',
                                        ).format(day).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        day.day.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        if (_selectedDay != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Showing games for ${DateFormat('EEE, MMM d').format(_selectedDay!)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Dist:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButton<int?>(
                            underline: const SizedBox(),
                            value: _selectedDistance,
                            items: const [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Any'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 5,
                                child: Text('< 5 km'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 10,
                                child: Text('< 10 km'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 25,
                                child: Text('< 25 km'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 50,
                                child: Text('< 50 km'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDistance = value;
                              });
                            },
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            icon: const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Colors.black54,
                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButton<String>(
                            underline: const SizedBox(),
                            value: selectedSport,
                            items: sportNames
                                .map((sport) => DropdownMenuItem<String>(value: sport, child: Text(sport)))
                                .toList(),
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
                            icon: const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeAddress == null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE599)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB27A00), size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Please set an active address to filter games by distance.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF664600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddressSelectionScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB27A00),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Set Address',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: filteredGames.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
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
                              final filledSpots = game.joinedPlayers.length;
                              final maxPlayers = game.maxPlayers;
                              final progressValue = maxPlayers <= 0
                                  ? 0.0
                                  : (filledSpots / maxPlayers).clamp(0.0, 1.0);
                              final isMatchFull = filledSpots >= maxPlayers;
                              final distance = (activeAddress != null &&
                                      game.lat != null &&
                                      game.lng != null)
                                  ? _calculateDistance(
                                      activeAddress.lat,
                                      activeAddress.lng,
                                      game.lat!,
                                      game.lng!,
                                    )
                                  : null;

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
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _primaryGreen.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.sports_soccer,
                                              size: 18,
                                              color: _primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: "${game.hostName}'s ",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${game.sportType} game',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                      color: _primaryGreen,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' at ${game.locationName}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPublic
                                                  ? Colors.blue[50]
                                                  : Colors.amber[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              game.gameAccess,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isPublic
                                                    ? Colors.blue[700]
                                                    : Colors.amber[900],
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
                                            label: DateFormat(
                                              'EEE, MMM d',
                                            ).format(game.date),
                                            backgroundColor: const Color(
                                              0xFFF1F5FF,
                                            ),
                                            foregroundColor: const Color(
                                              0xFF3451B2,
                                            ),
                                          ),
                                          if (game.startTime.isNotEmpty &&
                                              game.endTime.isNotEmpty)
                                            _buildInfoChip(
                                              icon: Icons.access_time,
                                              label:
                                                  '${_formatStoredTime(game.startTime)} - ${_formatStoredTime(game.endTime)}',
                                              backgroundColor: const Color(
                                                0xFFF2FBF5,
                                              ),
                                              foregroundColor: _primaryGreen,
                                            ),
                                          if (distance != null)
                                            _buildInfoChip(
                                              icon: Icons.directions_run_outlined,
                                              label: '${distance.toStringAsFixed(1)} km away',
                                              backgroundColor: const Color(
                                                0xFFFFF2E6,
                                              ),
                                              foregroundColor: const Color(
                                                0xFFE65C00,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place_outlined,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              game.locationName,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$filledSpots / $maxPlayers Spots Filled',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _primaryGreen,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: progressValue,
                                            minHeight: 6,
                                            backgroundColor: const Color(
                                              0xFFE7ECEF,
                                            ),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(_primaryGreen),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () {
                                          if (game.hostId.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserProfileScreen(
                                                      userId: game.hostId,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 16,
                                              color: _primaryGreen,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              game.hostName,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: _primaryGreen,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      (game.hostId ==
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid)
                                          ? Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () =>
                                                        showInviteFriendsBottomSheet(
                                                          context,
                                                          game,
                                                          ref,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.person_add_alt_1,
                                                      size: 15,
                                                    ),
                                                    label: const Text(
                                                      'Add Friend',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.blueAccent,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () =>
                                                        showGameInviteUsersBottomSheet(
                                                          context,
                                                          game,
                                                          ref,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.forward_to_inbox,
                                                      size: 15,
                                                    ),
                                                    label: const Text(
                                                      'Invite User',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.indigoAccent,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: isMatchFull
                                                    ? null
                                                    : () =>
                                                          showJoinGameBottomSheet(
                                                            context,
                                                            game,
                                                            ref,
                                                          ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _primaryGreen,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      Colors.grey[300],
                                                  disabledForegroundColor:
                                                      Colors.black54,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  isMatchFull
                                                      ? 'Match Full'
                                                      : 'Join',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
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
            error: (err, stack) =>
                Center(child: Text('Error fetching games: $err')),
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
    return List.generate(
      totalDays,
      (index) => DateTime(now.year, now.month, index + 1),
    );
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

Future<void> showJoinGameBottomSheet(
  BuildContext context,
  GameEntity game,
  WidgetRef ref,
) {
  final currentUser = FirebaseAuth.instance.currentUser;
  final currentUserName = _resolveCurrentUserName(currentUser, ref);
  final currentUserUid = currentUser?.uid;

  if (currentUserUid == null) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign in required'),
        content: const Text('Please sign in before joining a game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _JoinGameBottomSheet(
      game: game,
      ref: ref,
      currentUserName: currentUserName,
      currentUserUid: currentUserUid,
    ),
  );
}

class _JoinGameBottomSheet extends StatefulWidget {
  final GameEntity game;
  final WidgetRef ref;
  final String currentUserName;
  final String currentUserUid;

  const _JoinGameBottomSheet({
    required this.game,
    required this.ref,
    required this.currentUserName,
    required this.currentUserUid,
  });

  @override
  State<_JoinGameBottomSheet> createState() => _JoinGameBottomSheetState();
}

class _JoinGameBottomSheetState extends State<_JoinGameBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static const Color _accentGreen = Color(0xFF1DB954);
  bool _selfAdded = false;
  final List<TextEditingController> _guestControllers = [];

  @override
  void dispose() {
    for (final controller in _guestControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmRegistration() async {
    if (!_selfAdded) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final participantPayloads = <Map<String, dynamic>>[
      Participant(
        uid: widget.currentUserUid,
        name: widget.currentUserName,
        isGuest: false,
      ).toMap(),
      ..._guestControllers.asMap().entries.map(
        (entry) => Participant(
          uid: widget.currentUserUid,
          name: entry.value.text.trim(),
          isGuest: true,
        ).toMap(),
      ),
    ];

    await widget.ref
        .read(gamesRepositoryProvider)
        .joinGame(widget.game.id, participantPayloads);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Join ${widget.game.sportType} game',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to add yourself, then add any guest players joining with you.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_selfAdded) {
                      return;
                    }

                    setState(() {
                      _selfAdded = true;
                    });
                  },
                  icon: Icon(
                    _selfAdded ? Icons.check_circle : Icons.person_add_alt_1,
                  ),
                  label: Text(_selfAdded ? 'Added' : 'Add Myself'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selfAdded ? _accentGreen : Colors.black87,
                    side: BorderSide(
                      color: _selfAdded ? _accentGreen : Colors.black12,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_selfAdded) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2FBF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _accentGreen.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: _accentGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.currentUserName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: _accentGreen,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ..._guestControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Guest Player ${index + 1}',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller.dispose();
                                    _guestControllers.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a guest name';
                              }
                              return null;
                            },
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _guestControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('+ Add Guest Player'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selfAdded ? _confirmRegistration : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirm Registration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _resolveCurrentUserName(User? currentUser, WidgetRef ref) {
  final profileName = ref.read(userProfileProvider).value?.name.trim();
  if (profileName != null && profileName.isNotEmpty) {
    return profileName;
  }

  final displayName = currentUser?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final emailName = currentUser?.email?.split('@').first.trim();
  if (emailName != null && emailName.isNotEmpty) {
    return emailName;
  }

  return 'Player';
}

Future<void> showInviteFriendsBottomSheet(
  BuildContext context,
  GameEntity game,
  WidgetRef ref,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _InviteFriendsBottomSheet(game: game, ref: ref),
  );
}

class _InviteFriendsBottomSheet extends ConsumerStatefulWidget {
  final GameEntity game;
  final WidgetRef ref;

  const _InviteFriendsBottomSheet({required this.game, required this.ref});

  @override
  ConsumerState<_InviteFriendsBottomSheet> createState() =>
      _InviteFriendsBottomSheetState();
}

class _InviteFriendsBottomSheetState
    extends ConsumerState<_InviteFriendsBottomSheet> {
  final List<String> _invitedUids = [];

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsStreamProvider);
    final primaryGreen = const Color(0xFF1DB954);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Invite Friends',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select friends to invite to your ${widget.game.sportType} game.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                // Filter out friends who are already joined in the game
                final availableFriends = friends.where((friend) {
                  return !widget.game.joinedPlayers.any(
                    (player) => player.uid == friend.uid,
                  );
                }).toList();

                if (availableFriends.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No available friends to invite',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All your friends are already in this game!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableFriends.length,
                  itemBuilder: (context, index) {
                    final friend = availableFriends[index];
                    final isInvited = _invitedUids.contains(friend.uid);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isInvited
                            ? const Color(0xFFF2FBF5)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isInvited
                              ? primaryGreen.withValues(alpha: 0.18)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                friend.profilePic != null &&
                                    friend.profilePic!.isNotEmpty
                                ? NetworkImage(friend.profilePic!)
                                : null,
                            child:
                                friend.profilePic == null ||
                                    friend.profilePic!.isEmpty
                                ? const Icon(Icons.person, color: Colors.blue)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${friend.username}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: isInvited
                                ? null
                                : () async {
                                    setState(() {
                                      _invitedUids.add(friend.uid);
                                    });

                                    try {
                                      // Add participant to game
                                      final newParticipant = Participant(
                                        uid: friend.uid,
                                        name: friend.name,
                                        isGuest: false,
                                      );
                                      await widget.ref
                                          .read(gamesRepositoryProvider)
                                          .joinGame(widget.game.id, [
                                            newParticipant.toMap(),
                                          ]);

                                      // Send invitation notification
                                      final hostProfile = ref
                                          .read(userProfileProvider)
                                          .value;
                                      final hostName =
                                          hostProfile?.name ?? 'Host';
                                      final notification = NotificationEntity(
                                        id: '',
                                        targetUserId: friend.uid,
                                        title: 'Game Invitation! ✉️',
                                        body:
                                            '$hostName invited you to join their ${widget.game.sportType} game at ${widget.game.locationName}.',
                                        date: DateTime.now(),
                                      );
                                      await widget.ref
                                          .read(notificationsRepositoryProvider)
                                          .sendNotification(notification);

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Invited ${friend.name} successfully!',
                                            ),
                                            backgroundColor: primaryGreen,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() {
                                        _invitedUids.remove(friend.uid);
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to invite: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInvited
                                  ? Colors.grey.shade300
                                  : primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isInvited ? 'Invited' : 'Invite',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Error loading friends: $err',
                    style: const TextStyle(color: Colors.red),
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

Future<void> showGameInviteUsersBottomSheet(
  BuildContext context,
  GameEntity game,
  WidgetRef ref,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _InviteUsersBottomSheet(game: game, ref: ref),
  );
}

class _InviteUsersBottomSheet extends ConsumerStatefulWidget {
  final GameEntity game;
  final WidgetRef ref;

  const _InviteUsersBottomSheet({required this.game, required this.ref});

  @override
  ConsumerState<_InviteUsersBottomSheet> createState() =>
      _InviteUsersBottomSheetState();
}

class _InviteUsersBottomSheetState
    extends ConsumerState<_InviteUsersBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Athlete> _allAthletes = [];
  bool _loading = true;
  final List<String> _invitedUids = [];

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    try {
      final athletes = await ref
          .read(profileRepositoryProvider)
          .getAllAthletes();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (mounted) {
        setState(() {
          _allAthletes = athletes.where((a) => a.uid != currentUid).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentInvitationsAsync = ref.watch(
      sentInvitationsForGameStreamProvider(widget.game.id),
    );
    final sentUids = sentInvitationsAsync.value ?? [];
    final primaryGreen = const Color(0xFF1DB954);

    final filteredAthletes = _allAthletes.where((athlete) {
      final matchesQuery =
          athlete.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          athlete.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final isAlreadyJoined = widget.game.joinedPlayers.any(
        (player) => player.uid == athlete.uid,
      );
      return matchesQuery && !isAlreadyJoined;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Invite Users to Game',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search and invite athletes to join your ${widget.game.sportType} game.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAthletes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No other athletes found'
                                  : 'No matches found',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredAthletes.length,
                      itemBuilder: (context, index) {
                        final athlete = filteredAthletes[index];
                        final isInvited =
                            _invitedUids.contains(athlete.uid) ||
                            sentUids.contains(athlete.uid);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isInvited
                                ? const Color(0xFFF0F4FE)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isInvited
                                  ? Colors.blue.withOpacity(0.18)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    athlete.profilePic != null &&
                                        athlete.profilePic!.isNotEmpty
                                    ? NetworkImage(athlete.profilePic!)
                                    : null,
                                child:
                                    athlete.profilePic == null ||
                                        athlete.profilePic!.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      athlete.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${athlete.username}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: isInvited
                                    ? null
                                    : () async {
                                        setState(() {
                                          _invitedUids.add(athlete.uid);
                                        });

                                        try {
                                          final hostProfile = ref
                                              .read(userProfileProvider)
                                              .value;
                                          final hostName =
                                              hostProfile?.name ?? 'Host';
                                          final hostId =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid ??
                                              '';

                                          await ref
                                              .read(gamesRepositoryProvider)
                                              .sendGameInvitation(
                                                gameId: widget.game.id,
                                                hostId: hostId,
                                                hostName: hostName,
                                                invitedUserId: athlete.uid,
                                                sportType:
                                                    widget.game.sportType,
                                                date: widget.game.date,
                                                locationName:
                                                    widget.game.locationName,
                                              );

                                          final notification = NotificationEntity(
                                            id: '',
                                            targetUserId: athlete.uid,
                                            title: 'Game Invitation! ✉️',
                                            body:
                                                '$hostName invited you to join their ${widget.game.sportType} game at ${widget.game.locationName}.',
                                            date: DateTime.now(),
                                          );
                                          await ref
                                              .read(
                                                notificationsRepositoryProvider,
                                              )
                                              .sendNotification(notification);

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Invitation sent to ${athlete.name}!',
                                                ),
                                                backgroundColor:
                                                    Colors.blueAccent,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setState(() {
                                            _invitedUids.remove(athlete.uid);
                                          });
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to invite: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInvited
                                      ? Colors.grey.shade300
                                      : Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isInvited ? 'Invited' : 'Invite',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
