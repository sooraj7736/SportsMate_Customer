import 'package:flutter/material.dart';
import 'hosted_games_screen.dart';
import 'joined_games_screen.dart';

class MyGamesDashboardScreen extends StatelessWidget {
  const MyGamesDashboardScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
          elevation: 0,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Games',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Manage your match events',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            indicatorColor: _primaryGreen,
            indicatorWeight: 3,
            labelColor: _primaryGreen,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
            tabs: const [
              Tab(text: 'Hosted By Me'),
              Tab(text: 'Joined By Me'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HostedGamesScreen(),
            JoinedGamesScreen(),
          ],
        ),
      ),
    );
  }
}
