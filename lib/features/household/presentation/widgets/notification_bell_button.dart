import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_system.dart';
import '../providers/notification_providers.dart';
import 'notifications_sheet.dart';

/// Reusable notification bell action with unread badge and instant local clearance.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadNotifs > 0,
        backgroundColor: CoSpendColors.alertRed,
        label: Text('$unreadNotifs'),
        child: Icon(
          Icons.notifications_outlined,
          color: isDark ? Colors.white70 : CoSpendColors.textMuted,
          size: 22,
        ),
      ),
      tooltip: 'Activity & Alerts',
      onPressed: () {
        ref.read(notificationActionsProvider.notifier).markAllAsRead();
        NotificationsSheet.show(context);
      },
    );
  }
}
