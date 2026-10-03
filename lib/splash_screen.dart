import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'app/router/routes.dart';
import 'features/auth/domain/session_state.dart';
import 'features/auth/presentation/providers/session_provider.dart';

/// Animated Lottie splash screen.
///
/// Plays `assets/animations/logo_splash.json` once on a clean white background.
/// When the animation finishes, it marks the splash sequence complete and navigates
/// with [pushReplacement] to the app's existing first screen based on session state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAnimationComplete() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Signal router that the splash animation has completed
    ref.read(splashAnimationCompletedProvider.notifier).complete();

    // Resolve session if still initializing in the background
    SessionState? session = ref.read(sessionProvider).value;
    if (session == null || session is SessionInitializing) {
      try {
        session = await ref.read(sessionProvider.future);
      } catch (_) {
        // Fallback gracefully on initialization error
      }
    }

    if (!mounted) return;

    final String targetRoute;
    switch (session) {
      case SessionSignedOut():
        targetRoute = Routes.onboarding;
      case SessionNeedsHousehold():
        targetRoute = Routes.householdSetup;
      case SessionReady():
        targetRoute = Routes.home;
      default:
        targetRoute = Routes.onboarding;
    }

    if (mounted) {
      try {
        context.pushReplacement(targetRoute);
      } catch (_) {
        if (mounted) {
          context.go(targetRoute);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/animations/logo_splash.json',
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  _controller.forward().then((_) {
                    _handleAnimationComplete();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
              ),
              child: const Text(
                'CoSpend',
                style: TextStyle(
                  fontFamily: 'Lufga',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF0A2542),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
