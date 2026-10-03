import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../firebase_options.dart';
import '../../domain/session_state.dart';
import 'auth_providers.dart';

/// Asynchronous bootstrap for Firebase, notification channels, and FCM.
///
/// Running this inside a provider instead of blocking main() allows the app
/// to mount and display the splash screen immediately on frame 1 without delay.
final firebaseInitProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notification tray (foreground alerts via Firestore).
  NotificationService.instance.initialize().catchError((e) {
    debugPrint('Failed to initialize NotificationService: $e');
  });

  // Initialize Firebase Cloud Messaging (background & push notifications).
  FcmService.instance.initialize().catchError((e) {
    debugPrint('Failed to initialize FcmService: $e');
  });
});

/// Resolves where the user is in the app (signed out / needs household /
/// ready). Every router redirect reads this provider.
class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    // Ensure Firebase is initialized before accessing FirebaseAuth / Firestore
    await ref.watch(firebaseInitProvider.future);

    final authUser = await ref.watch(authStateProvider.future);
    if (authUser == null) return const SessionSignedOut();

    final appUser = await ref.watch(currentUserProvider.future);
    if (appUser == null) return const SessionSignedOut();
    if (appUser.householdId == null) {
      return SessionNeedsHousehold(user: appUser);
    }
    return SessionReady(user: appUser);
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Tracks whether the animated Lottie splash animation has completed.
///
/// Driven directly by the animation controller completing its forward pass,
/// eliminating hardcoded timers.
class SplashAnimationController extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}

final splashAnimationCompletedProvider =
    NotifierProvider<SplashAnimationController, bool>(
  SplashAnimationController.new,
);