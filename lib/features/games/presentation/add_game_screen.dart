import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'add_game_controller.dart';
import '../domain/game_entity.dart';
import '../data/games_repository.dart';

class AddGameScreen extends ConsumerWidget {
  const AddGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addGameControllerProvider);
    final notifier = ref.read(addGameControllerProvider.notifier);
    final userProfile = ref.watch(userProfileProvider).value;

    final now = DateTime.now();
    final availableDays = List.generate(14, (index) => now.add(Duration(days: index)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("Host Match Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              value: state.sportType,
              decoration: const InputDecoration(labelText: "Select Sport", border: InputBorder.none),
              items: ["Football", "Cricket", "Basketball", "Badminton"].map((sport) {
                return DropdownMenuItem(value: sport, child: Text(sport));
              }).toList(),
              onChanged: (val) => notifier.updateSport(val!),
            ),
            const Divider(),
            TextFormField(
              initialValue: state.locationName,
              decoration: const InputDecoration(labelText: "Area / Location (Type name)", border: InputBorder.none),
              onChanged: (val) => notifier.updateLocation(val),
            ),
          ]),

          // 2. Horizontal Calendar Row
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            child: Text("Select Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                      color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(day).toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey)),
                        Text(day.day.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 3. Match Privacy Access
          _buildCardFrame("Game Access", [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Who can discover this game?", style: TextStyle(fontSize: 14)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Public', label: Text('Public')),
                    ButtonSegment(value: 'Private', label: Text('Private')),
                  ],
                  selected: {state.gameAccess},
                  onSelectionChanged: (set) => notifier.updateAccess(set.first),
                )
              ],
            )
          ]),

          // 4. Counters and Options Matrix
          _buildCardFrame("Players Configuration", [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Required Players", style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => notifier.updatePlayers(state.numberOfPlayers - 1)),
                    Text(state.numberOfPlayers.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => notifier.updatePlayers(state.numberOfPlayers + 1)),
                  ],
                )
              ],
            ),
            const Divider(),
            _buildToggleRow("Match skill levels via Profile Info?", state.matchSkillFromProfile, (_) => notifier.toggleSkillMatch()),
          ]),

          // 5. Costing & Gear Toggles
          _buildCardFrame("Pricing & Setup", [
            _buildToggleRow("Is this a Paid Match booking?", state.isPaid, (_) => notifier.togglePaid()),
            if (state.isPaid) ...[
              const Divider(),
              _buildToggleRow("Split venue cost equally among joined users?", state.isCostShared, (_) => notifier.toggleCostShared()),
            ],
            const Divider(),
            _buildToggleRow("Should players bring personal equipment?", state.bringEquipment, (_) => notifier.toggleEquipment()),
          ]),

          const SizedBox(height: 12),

          // Submit Publish Action Button
          ElevatedButton(
            onPressed: state.locationName.isEmpty 
                ? null 
                : () async {
                    // Fetch the currently active user session details
                    final currentUser = FirebaseAuth.instance.currentUser;

                    final gamePayload = GameEntity(
                      id: '', // Left blank; Firestore generates this dynamically
                      hostId: currentUser?.uid ?? 'unknown_id',
                      hostName: userProfile?.name ?? 'Athlete Host',
                      sportType: state.sportType,
                      locationName: state.locationName,
                      date: state.selectedDate,
                      gameAccess: state.gameAccess,
                      matchSkillFromProfile: state.matchSkillFromProfile,
                      isPaid: state.isPaid,
                      numberOfPlayers: state.numberOfPlayers,
                      isCostShared: state.isCostShared,
                      bringEquipment: state.bringEquipment,
                    );

                    // Send payload to Firestore via the repository provider
                    await ref.read(gamesRepositoryProvider).createGame(gamePayload);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Close form screen and return to the feed list
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Create Match Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Visual helper grouping structural rows into card panels matching reference screenshots
  static Widget _buildCardFrame(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[100]!)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ...children
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
        Switch.adaptive(value: val, activeColor: const Color(0xFF1DB954), onChanged: target)
      ],
    );
  }
}