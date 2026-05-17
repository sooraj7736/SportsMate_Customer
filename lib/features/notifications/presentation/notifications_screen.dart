import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsmate/features/auth/presentation/auth_controller.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("Please sign in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        elevation: 0.5,
      ),
      body: StreamBuilder(
        stream: ref.read(notificationsRepositoryProvider).watchMyNotifications(userProfile.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                tileColor: notif.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? Colors.grey[300] : Colors.blue[100],
                  child: Icon(Icons.notifications, color: notif.isRead ? Colors.grey : Colors.blue),
                ),
                title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.body),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(notif.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
