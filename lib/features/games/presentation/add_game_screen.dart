import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/notifications/data/notifications_repository.dart';
import 'package:sportsmate/features/notifications/domain/notification_entity.dart';
import 'package:sportsmate/features/sports/data/sports_catalog.dart';
import 'add_game_controller.dart';
import '../domain/game_entity.dart';
import '../data/games_repository.dart';
import 'package:sportsmate/features/tournament/data/tournament_repository.dart';
import 'package:sportsmate/core/widgets/location_picker.dart';

class AddGameScreen extends ConsumerStatefulWidget {
  const AddGameScreen({super.key});

  @override
  ConsumerState<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends ConsumerState<AddGameScreen> {
  String? _selectedLocationId;
  List<Map<String, dynamic>> _availableTurfs = [];
  bool _isOtherLocation = false;
  double? _latitude;
  double? _longitude;
  final TextEditingController _customAddressController =
      TextEditingController();

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
  void initState() {
    super.initState();
    _fetchTurfs();
  }

  Future<void> _fetchTurfs() async {
    try {
      final turfs = await ref
          .read(tournamentRepositoryProvider)
          .getAvailableTurfs();
      if (mounted) {
        setState(() {
          _availableTurfs = turfs;
          if (turfs.isNotEmpty) {
            _selectedLocationId = turfs.first['id'] as String;
            _isOtherLocation = false;
          } else {
            _selectedLocationId = 'other';
            _isOtherLocation = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedLocationId = 'other';
          _isOtherLocation = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _customAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addGameControllerProvider);
    final notifier = ref.read(addGameControllerProvider.notifier);
    final userProfile = ref.watch(userProfileProvider).value;
    final sportsAsync = ref.watch(sportsCatalogProvider);
    final availableSports = sportsAsync.asData?.value ?? const [];
    final sportNames = availableSports.isNotEmpty
        ? availableSports.map((sport) => sport.name).toList()
        : ['Football'];
    final selectedSport = sportNames.contains(state.sportType)
        ? state.sportType
        : sportNames.first;

    final now = DateTime.now();
    final availableDays = List.generate(
      14,
      (index) => now.add(Duration(days: index)),
    );

    Future<void> pickStartTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: state.startTime,
      );

      if (picked != null) {
        notifier.updateStartTime(picked);
      }
    }

    Future<void> pickEndTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: state.endTime,
      );

      if (picked == null) {
        return;
      }

      if (_toMinutes(picked) <= _toMinutes(state.startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("End time must be later than start time"),
          ),
        );
        return;
      }

      notifier.updateEndTime(picked);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Host Match Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Sport Type & Location
          _buildCardFrame("Match Context", [
            DropdownButtonFormField<String>(
              value: selectedSport,
              decoration: const InputDecoration(
                labelText: "Select Sport",
                border: InputBorder.none,
              ),
              items: sportNames
                  .map(
                    (sport) =>
                        DropdownMenuItem(value: sport, child: Text(sport)),
                  )
                  .toList(),
              onChanged: (val) => notifier.updateSport(val!),
            ),
            const Divider(),
            if (_selectedLocationId != null)
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedLocationId,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: InputBorder.none,
                ),
                items: [
                  ..._availableTurfs.map((turf) {
                    final isVerified = turf['isVerified'] == true;
                    return DropdownMenuItem<String>(
                      value: turf['id'] as String,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              turf['name'] ?? 'Turf',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const DropdownMenuItem<String>(
                    value: 'other',
                    child: Text(
                      'Other (Custom Map / Address)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedLocationId = val;
                    _isOtherLocation = val == 'other';
                  });
                },
              ),
            if (_isOtherLocation) ...[
              const Divider(),
              TextFormField(
                controller: _customAddressController,
                decoration: const InputDecoration(
                  labelText: 'Custom Address / Map Details',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPicker(
                        onLocationSelected: (lat, lng) {
                          setState(() {
                            _latitude = lat;
                            _longitude = lng;
                            _customAddressController.text =
                                "Map Location Selected";
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(
                  _latitude != null
                      ? "Location Selected on Map"
                      : "Pick Location on Map",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _latitude != null
                      ? const Color(0xFF1DB954)
                      : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ]),

          // 2. Horizontal Calendar Row
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            child: Text(
              "Select Date",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableDays.length,
              itemBuilder: (context, index) {
                final day = availableDays[index];
                final isSelected = DateUtils.isSameDay(day, state.selectedDate);
                return GestureDetector(
                  onTap: () => notifier.updateDate(day),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1DB954)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 3. Time Slot
          _buildCardFrame("Time Slot", [
            const Text(
              "Choose starting and ending time",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    context: context,
                    title: "Start",
                    value: _formatTime(context, state.startTime),
                    onPressed: pickStartTime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTimeButton(
                    context: context,
                    title: "End",
                    value: _formatTime(context, state.endTime),
                    onPressed: pickEndTime,
                  ),
                ),
              ],
            ),
          ]),

          // 4. Match Privacy Access
          _buildCardFrame("Game Access", [
            const Text(
              "Who can discover this game?",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Public', label: Text('Public')),
                  ButtonSegment(value: 'Private', label: Text('Private')),
                ],
                selected: {state.gameAccess},
                onSelectionChanged: (set) => notifier.updateAccess(set.first),
              ),
            ),
          ]),

          // 5. Counters and Options Matrix
          _buildCardFrame("Players Configuration", [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Required Players",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          notifier.updatePlayers(state.numberOfPlayers - 1),
                    ),
                    Text(
                      state.numberOfPlayers.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          notifier.updatePlayers(state.numberOfPlayers + 1),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _buildToggleRow(
              "Match skill levels via Profile Info?",
              state.matchSkillFromProfile,
              (_) => notifier.toggleSkillMatch(),
            ),
          ]),

          // 6. Costing & Gear Toggles
          _buildCardFrame("Pricing & Setup", [
            _buildToggleRow(
              "Is this a Paid Match booking?",
              state.isPaid,
              (_) => notifier.togglePaid(),
            ),
            if (state.isPaid) ...[
              const Divider(),
              _buildToggleRow(
                "Split venue cost equally among joined users?",
                state.isCostShared,
                (_) => notifier.toggleCostShared(),
              ),
            ],
            const Divider(),
            _buildToggleRow(
              "Should players bring personal equipment?",
              state.bringEquipment,
              (_) => notifier.toggleEquipment(),
            ),
          ]),

          const SizedBox(height: 12),

          // Submit Publish Action Button
          ElevatedButton(
            onPressed:
                (_isOtherLocation && _customAddressController.text.isEmpty)
                ? null
                : () async {
                    // Fetch the currently active user session details
                    final currentUser = FirebaseAuth.instance.currentUser;

                    String finalLocationName = '';
                    String? finalTurfId;
                    String? finalCustomAddress;
                    bool finalIsVerifiedTurf = false;
                    double? latToUse = _latitude;
                    double? lngToUse = _longitude;

                    if (_isOtherLocation) {
                      finalLocationName = _customAddressController.text.trim();
                      finalCustomAddress = finalLocationName;
                    } else {
                      final turf = _availableTurfs.firstWhere(
                        (t) => t['id'] == _selectedLocationId,
                        orElse: () => {'name': 'Unknown Turf'},
                      );
                      finalLocationName = turf['name'] ?? 'Unknown Turf';
                      finalTurfId = turf['id'];
                      finalIsVerifiedTurf = turf['isVerified'] ?? false;
                      latToUse =
                          turf['lat']?.toDouble() ??
                          turf['latitude']?.toDouble();
                      lngToUse =
                          turf['lng']?.toDouble() ??
                          turf['longitude']?.toDouble();
                    }

                    final gamePayload = GameEntity(
                      id: '', // Left blank; Firestore generates this dynamically
                      hostId: currentUser?.uid ?? 'unknown_id',
                      hostName: userProfile?.name ?? 'Athlete Host',
                      sportType: selectedSport,
                      locationName: finalLocationName,
                      turfId: finalTurfId,
                      isVerifiedTurf: finalIsVerifiedTurf,
                      lat: latToUse,
                      lng: lngToUse,
                      customAddress: finalCustomAddress,
                      date: state.selectedDate,
                      startTime: _toStorageTime(state.startTime),
                      endTime: _toStorageTime(state.endTime),
                      gameAccess: state.gameAccess,
                      matchSkillFromProfile: state.matchSkillFromProfile,
                      isPaid: state.isPaid,
                      numberOfPlayers: state.numberOfPlayers,
                      isCostShared: state.isCostShared,
                      bringEquipment: state.bringEquipment,
                      joinedPlayers: [
                        Participant(
                          uid: currentUser?.uid ?? 'unknown_id',
                          name: userProfile?.name ?? 'Athlete Host',
                          isGuest: false,
                        ),
                      ],
                    );

                    // Send payload to Firestore via the repository provider
                    await ref
                        .read(gamesRepositoryProvider)
                        .createGame(gamePayload);

                    // Send notifications to users within 5km
                    if (latToUse != null && lngToUse != null) {
                      final activeAddressesSnapshot = await FirebaseFirestore
                          .instance
                          .collection('addresses')
                          .where('isActive', isEqualTo: true)
                          .get();

                      for (final doc in activeAddressesSnapshot.docs) {
                        final addrData = doc.data();
                        final athleteUid = addrData['uid'] as String? ?? '';
                        if (athleteUid == currentUser?.uid) continue;

                        final addrLat =
                            (addrData['lat'] as num?)?.toDouble() ?? 0.0;
                        final addrLng =
                            (addrData['lng'] as num?)?.toDouble() ?? 0.0;

                        final distance = _calculateDistance(
                          latToUse,
                          lngToUse,
                          addrLat,
                          addrLng,
                        );
                        if (distance <= 5.0) {
                          final notification = NotificationEntity(
                            id: '',
                            targetUserId: athleteUid,
                            title: 'New Game Nearby!',
                            body:
                                '${userProfile?.name ?? "Someone"} created a $selectedSport game near you at $finalLocationName.',
                            date: DateTime.now(),
                          );
                          await ref
                              .read(notificationsRepositoryProvider)
                              .sendNotification(notification);
                        }
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(
                        context,
                      ); // Close form screen and return to the feed list
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Create Match Event",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTimeButton({
    required BuildContext context,
    required String title,
    required String value,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF1DB954)),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(BuildContext context, TimeOfDay time) {
    final now = DateTime.now();
    final value = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat.jm().format(value);
  }

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _toStorageTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // Visual helper grouping structural rows into card panels matching reference screenshots
  static Widget _buildCardFrame(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  static Widget _buildToggleRow(String text, bool val, Function(bool) target) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        Switch.adaptive(
          value: val,
          activeColor: const Color(0xFF1DB954),
          onChanged: target,
        ),
      ],
    );
  }
}
