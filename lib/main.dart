import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notification tray (foreground alerts via Firestore).
  NotificationService.instance.initialize().catchError((e) {
    debugPrint('Failed to initialize NotificationService: $e');
  });

  // Initialize Firebase Cloud Messaging (background & terminated push).
  // FcmService registers the background handler BEFORE runApp() as required.
  FcmService.instance.initialize().catchError((e) {
    debugPrint('Failed to initialize FcmService: $e');
  });

  runApp(const ProviderScope(child: CoSpendApp()));
}