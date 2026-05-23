import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../main_wrapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/common_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/home_controller.dart';
import '../../AddFeed/domain/AddFeed_entity.dart';
import '../../home/domain/ad_entity.dart';

class NearPlaySplashScreen extends ConsumerStatefulWidget {
  final bool isStatic;
  const NearPlaySplashScreen({super.key, this.isStatic = false});

  @override
  ConsumerState<NearPlaySplashScreen> createState() => _NearPlaySplashScreenState();
}

class _NearPlaySplashScreenState extends ConsumerState<NearPlaySplashScreen> {

  @override
  void initState() {
    super.initState();
    if (!widget.isStatic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _preloadAndInitialize();
        }
      });
    }
  }

  Future<void> _preloadAndInitialize() async {
    final startTime = DateTime.now();

    try {
      await precacheImage(const AssetImage('assets/icon_nearplay.png'), context);
      await _warmUpData();
    } catch (e) {
      debugPrint("Preloading data failed: $e");
    }

    final elapsed = DateTime.now().difference(startTime);
    final minimumDisplayDuration = const Duration(seconds: 4);
    
    final remainingDelay = minimumDisplayDuration - elapsed;
    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    if (mounted) {
      _navigateToMain();
    }
  }

  Future<void> _warmUpData() async {
    final auth = ref.read(firebaseAuthProvider);
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      await Future.wait([
        ref.read(userProfileProvider.future).catchError((_) => null),
        ref.read(feedListStreamProvider.future).catchError((_) => <FeedEntity>[]),
        ref.read(adListStreamProvider.future).catchError((_) => <AdEntity>[]),
      ]).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepPitch, 
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 380,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Radial Backdrop Glow
                      Container(
                        width: 250,
                        height: 250,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x4443A047),
                              Colors.transparent,
                            ],
                            stops: [0.0, 1.0],
                          ),
                        ),
                      ),
                      
                      
                      
                      // 3. Animated GIF layer
                      Positioned.fill(
                        child: Image.asset(
                          'assets/animations/splash_logo.gif',
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Play Near. Play Now.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          
        ],
      ),
    );
  }
}