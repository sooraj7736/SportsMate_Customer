import 'package:flutter/material.dart';
import 'hosted_games_screen.dart';
import 'joined_games_screen.dart';

class MyGamesDashboardScreen extends StatelessWidget {
  const MyGamesDashboardScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Games',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Manage your match events',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            indicatorColor: _primaryGreen,
            indicatorWeight: 3,
            labelColor: _primaryGreen,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
