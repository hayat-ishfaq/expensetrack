import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Singleton wrapper managing system-level notification tray alerts (outside the app).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Cache of notification IDs already presented in system tray to prevent duplicate alerts.
  final Set<String> _presentedNotificationIds = {};

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      _initialized = true;

      // Request notification permission asynchronously without blocking UI
      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        androidPlatform.requestNotificationsPermission().catchError((e) {
          debugPrint('Notification permission error: $e');
          return null;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Displays an immediate system notification in the device's status bar and lock screen.
  Future<void> showNotification({
    required String notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Avoid spamming duplicate alerts for the same event
    if (_presentedNotificationIds.contains(notificationId)) return;
    _presentedNotificationIds.add(notificationId);

    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'cospend_household_alerts',
      'Household Activity Alerts',
      channelDescription:
          'Notifications for roommate expenses, settlements, and member activity.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final id = notificationId.hashCode.abs() % 100000;

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
}
