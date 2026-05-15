import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/tournament/data/tournament_repository.dart';
import 'package:sportsmate/features/tournament/presentation/create_tournament_screen.dart';
import 'package:sportsmate/features/tournament/presentation/tournament_details_screen.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:intl/intl.dart';

class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentListStreamProvider);

    final userProfile = ref.watch(userProfileProvider).value;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tournaments'),
          elevation: 0.5,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Explore'),
              Tab(text: 'My Hosted'),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Host Tournament'),
      ),
      body: tournamentsAsync.when(
        data: (tournaments) {
          final myHostedTournaments = userProfile != null ? tournaments.where((t) => t.hostUid == userProfile.uid).toList() : [];

          Widget buildList(List<dynamic> list) {
            if (list.isEmpty) {
              return const Center(child: Text("No tournaments found."));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final t = list[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TournamentDetailsScreen(tournament: t)),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.posterUrl.isNotEmpty)
                          Image.network(
                            t.posterUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            color: Colors.blue.shade100,
                            width: double.infinity,
                            child: Center(
                              child: Icon(Icons.emoji_events, size: 60, color: Colors.blue.shade700),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(t.sport, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  if (t.isBoosted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.bolt, size: 14, color: Colors.orange.shade700),
                                          Text('Boosted', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(t.tournamentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Hosted by ${t.hostName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${DateFormat('MMM dd').format(t.startDate)} - ${DateFormat('MMM dd, yyyy').format(t.endDate)}",
                                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(t.location, style: TextStyle(color: Colors.grey.shade800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        if (t.isVerifiedTurf) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Entry Fee", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                        Text(t.registrationFee > 0 ? "₹${t.registrationFee}" : "Free", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                  if (t.prizePool.isNotEmpty)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text("Prize Pool", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                          Text(t.prizePool, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("Teams", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                        Text("${t.registeredTeams.length}/${t.maxTeams}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (t.contactPhone.isNotEmpty || t.rules.isNotEmpty) ...[
                                const Divider(height: 24),
                                if (t.contactPhone.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(t.contactPhone, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                                    ],
                                  ),
                                if (t.rules.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.rule, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(t.rules, style: TextStyle(color: Colors.grey.shade800, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return TabBarView(
            children: [
              buildList(tournaments),
              buildList(myHostedTournaments),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    ),
    );
  }
}
