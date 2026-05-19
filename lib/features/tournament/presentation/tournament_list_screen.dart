import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsmate/features/tournament/data/tournament_repository.dart';
import 'package:sportsmate/features/tournament/presentation/create_tournament_screen.dart';
import 'package:sportsmate/features/tournament/presentation/tournament_details_screen.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:sportsmate/features/tournament/live_score/data/football_live_score_repository.dart';
import 'package:sportsmate/features/tournament/live_score/presentation/view_football/view_football_live_score_screen.dart';
import 'package:sportsmate/features/tournament/live_score/presentation/add_football/add_football_live_score_screen.dart';

class BlinkingDot extends StatefulWidget {
  final double size;
  const BlinkingDot({this.size = 10, super.key});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(_controller),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

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
                final isFootball = t.sport.toString().toLowerCase() == 'football';
                final liveScoreAsync = isFootball ? ref.watch(footballLiveScoreStreamProvider(t.id)) : const AsyncValue.data(null);
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
                              ],

                              if (isFootball) ...[
                                const SizedBox(height: 12),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade100),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: liveScoreAsync.when(
                                          data: (score) {
                                            if (score == null) {
                                              return Text('No live score', style: TextStyle(color: Colors.grey.shade700));
                                            }
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${score.hostTeamName} ${score.hostTeamScore}  —  ${score.guestTeamScore} ${score.guestTeamName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    if (score.matchStatus.toLowerCase().contains('live')) ...[
                                                      const BlinkingDot(size: 10),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    Text(score.matchStatus, style: TextStyle(color: Colors.grey.shade700)),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                          loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                          error: (_, __) => Text('Live score unavailable', style: TextStyle(color: Colors.grey.shade700)),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_red_eye),
                                            onPressed: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => ViewFootballLiveScoreScreen(tournament: t)));
                                            },
                                          ),
                                          if (userProfile != null && userProfile.uid == t.hostUid)
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddFootballLiveScoreScreen(tournament: t)));
                                              },
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
