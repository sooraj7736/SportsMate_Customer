import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import 'package:sportsmate/features/games/data/games_repository.dart';
import 'package:sportsmate/features/notifications/data/notifications_repository.dart';
import 'package:sportsmate/features/notifications/domain/notification_entity.dart';
import 'package:sportsmate/features/friends/presentation/user_profile_screen.dart';

class GameInvitationsScreen extends ConsumerWidget {
  const GameInvitationsScreen({super.key});

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'football':
      case 'soccer':
        return Icons.sports_soccer;
      case 'cricket':
        return Icons.sports_cricket;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_tennis; // Icon fallback
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingInvitationsAsync = ref.watch(
      incomingGameInvitationsStreamProvider,
    );
    final userProfile = ref.watch(userProfileProvider).value;

    final primaryGreen = const Color(0xFF1DB954);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Game Invitations",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: scaffoldBg,
      body: incomingInvitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No pending game invitations",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invite = invitations[index];
              final invitationId = invite['id'] ?? '';
              final gameId = invite['gameId'] ?? '';
              final sportType = invite['sportType'] ?? 'Match';
              final hostId = invite['hostId'] ?? '';
              final hostName = invite['hostName'] ?? 'Host';
              final locationName = invite['locationName'] ?? 'Turf';

              // Handle Timestamp conversion safely
              final timestamp = invite['date'];
              final DateTime gameDate = timestamp != null
                  ? (timestamp as dynamic).toDate()
                  : DateTime.now();

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getSportIcon(sportType),
                            size: 20,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$sportType game",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                locationName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE, MMM d').format(gameDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        if (hostId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserProfileScreen(userId: hostId),
                            ),
                          );
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Invited by ",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            TextSpan(
                              text: hostName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                                decoration: TextDecoration.underline,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Accept",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final participantPayload = {
                                'uid':
                                    userProfile?.uid ??
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '',
                                'name': userProfile?.name ?? 'Athlete',
                                'isGuest': false,
                              };

                              try {
                                await ref
                                    .read(gamesRepositoryProvider)
                                    .acceptGameInvitation(
                                      invitationId: invitationId,
                                      gameId: gameId,
                                      participantPayload: participantPayload,
                                    );

                                try {
                                  await ref
                                      .read(notificationsRepositoryProvider)
                                      .sendNotification(
                                        NotificationEntity(
                                          id: '',
                                          targetUserId: hostId,
                                          title: 'Invitation Accepted',
                                          body:
                                              '${userProfile?.name ?? 'A player'} accepted your invitation for the $sportType game at $locationName.',
                                          date: DateTime.now(),
                                        ),
                                      );
                                } catch (_) {
                                  // Ignore notification failures for invite acceptance.
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Accepted invitation to join $hostName's game!",
                                      ),
                                      backgroundColor: primaryGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Failed to accept invitation: $e",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              "Decline",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(gamesRepositoryProvider)
                                    .declineGameInvitation(
                                      invitationId: invitationId,
                                    );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Declined invitation"),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Failed to decline: $e"),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
