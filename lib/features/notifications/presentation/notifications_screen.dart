import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsmate/core/theme/app_colors.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final userProfile = ref.watch(userProfileProvider).value;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0.5,
      ),
      body: StreamBuilder(
        stream: ref.read(notificationsRepositoryProvider).watchMyNotifications(userProfile.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cs.outline),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              // Unread tint that works in both themes
              final tileBg = notif.isRead
                  ? Colors.transparent
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.notifUnreadDark
                      : AppColors.notifUnreadLight);

              return ListTile(
                tileColor: tileBg,
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? cs.surfaceContainerHighest : cs.primaryContainer,
                  child: Icon(
                    Icons.notifications,
                    color: notif.isRead ? cs.onSurfaceVariant : cs.primary,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.body, style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(notif.date),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                onTap: () {
                  if (!notif.isRead) {
                    ref.read(notificationsRepositoryProvider).markAsRead(notif.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
