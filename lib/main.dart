import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sportsmate/firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/common_providers.dart';

import 'features/splash/presentation/nearplay_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  await dotenv.load(fileName: ".env");
  
  // Set Mapbox access token from .env
  final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
  if (mapboxToken != null) {
    MapboxOptions.setAccessToken(mapboxToken);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'NearPlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const NearPlaySplashScreen(),
    );
  }
}
