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

class _NearPlaySplashScreenState extends ConsumerState<NearPlaySplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    
    if (!widget.isStatic) {
      _preloadAndInitialize();
    }
  }

  Future<void> _preloadAndInitialize() async {
    final startTime = DateTime.now();

    try {
      // Precache image assets to avoid flickering later.
      await precacheImage(const AssetImage('assets/nearplay.png'), context);
      await precacheImage(const AssetImage('assets/icon_nearplay.png'), context);

      _warmUpData();
    } catch (e) {
      debugPrint("Preloading failed or timed out: $e");
    }

    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(seconds: 2) - elapsed;
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
    } catch (_) {
      // Ignore preload failures; navigation should not be blocked.
    }
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepPitch, 
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/nearplay.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Play Near. Play Now.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xCC0F5132)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
