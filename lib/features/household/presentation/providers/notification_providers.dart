import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../auth/presentation/providers/session_provider.dart';
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

class NotificationActions extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> markAllAsRead() async {
    final householdId = ref.read(sessionProvider).value?.householdId;
    final uid = ref.read(sessionProvider).value?.user?.id;
    if (householdId == null || uid == null) return;

    final notifications =
        ref.read(householdNotificationsProvider).value ?? const [];
    final unread = notifications
        .where((notification) => !notification.readByUserIds.contains(uid))
        .toList();
    if (unread.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    for (final notification in unread) {
      final doc = firestore
          .collection(FirestoreCollections.households)
          .doc(householdId)
          .collection('notifications')
          .doc(notification.id);
      batch.update(doc, {
        'readByUserIds': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
  }
}

final notificationActionsProvider =
    AsyncNotifierProvider<NotificationActions, void>(NotificationActions.new);

/// Count of notifications the current user has not marked read.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final uid = ref.watch(sessionProvider).value?.user?.id;
  if (uid == null) return 0;
  final notifications =
      ref.watch(householdNotificationsProvider).value ?? const [];
  return notifications
      .where((notification) => !notification.readByUserIds.contains(uid))
      .length;
});
