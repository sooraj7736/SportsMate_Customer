import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/splash/presentation/nearplay_splash_screen.dart';

import 'core/providers/common_providers.dart'; 


class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;
      if (prevUser != null && nextUser == null) {
        // User transitioned from logged in to logged out: clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        
        if (user != null) return const HomeScreen();
        return const LoginScreen();
      },
      loading: () => const NearPlaySplashScreen(isStatic: true),
      error: (e, trace) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }
}