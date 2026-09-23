import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../domain/household_notification.dart';
import 'household_providers.dart';

/// Stream of recent notifications for the active household.
final householdNotificationsProvider =
    StreamProvider<List<HouseholdNotification>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);

  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection(FirestoreCollections.households)
      .doc(household.id)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => HouseholdNotification.fromMap(doc.id, doc.data()))
        .toList();
  });
});

/// Tracks the timestamp when the user last opened the notifications sheet.
class LastViewedNotificationNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void markAllAsRead() {
    state = DateTime.now();
  }
}

final lastViewedNotificationProvider =
    NotifierProvider<LastViewedNotificationNotifier, DateTime>(
  LastViewedNotificationNotifier.new,
);

/// Count of notifications newer than the last viewed time (excluding current user's own expenses).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(householdNotificationsProvider).value ?? const [];
  final lastViewed = ref.watch(lastViewedNotificationProvider);
  return notifications.where((n) => n.createdAt.isAfter(lastViewed)).length;
});
