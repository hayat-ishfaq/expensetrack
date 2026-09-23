import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../domain/household_notification.dart';
import '../providers/notification_providers.dart';

enum _NotificationType {
  budgetApproaching,
  budgetExceeded,
  expense,
  settlement,
  household,
  system,
}

sealed class _NotificationRowEntry {
  const _NotificationRowEntry();
}

final class _NotificationHeaderEntry extends _NotificationRowEntry {
  const _NotificationHeaderEntry(this.title, this.count);
  final String title;
  final int count;
}

final class _NotificationItemEntry extends _NotificationRowEntry {
  const _NotificationItemEntry(this.notification);
  final HouseholdNotification notification;
}

class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  /// Track which notifications have been clicked/read during this view session.
  final Set<String> _locallyReadIds = {};

  void _markAsRead(String id) {
    if (!_locallyReadIds.contains(id)) {
      setState(() {
        _locallyReadIds.add(id);
      });
    }
  }

  void _markAllAsRead() {
    ref.read(lastViewedNotificationProvider.notifier).markAllAsRead();
    setState(() {
      _locallyReadIds.clear();
    });
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  _NotificationType _classifyNotification(HouseholdNotification item) {
    final title = item.title.toLowerCase();
    final body = item.body.toLowerCase();
    final category = item.category.toLowerCase();

    // 1. System (Explicit system category or system announcements)
    if (category.contains('system') ||
        title.contains('system update') ||
        title.contains('maintenance') ||
        title.contains('welcome to')) {
      return _NotificationType.system;
    }

    // 2. Budget Exceeded
    if (title.contains('exceeded') ||
        body.contains('exceeded') ||
        (category.contains('budget') && (title.contains('over') || body.contains('over')))) {
      return _NotificationType.budgetExceeded;
    }

    // 3. Budget Approaching
    if (title.contains('approaching') ||
        body.contains('approaching') ||
        title.contains('budget limit') ||
        body.contains('budget limit') ||
        category.contains('budget')) {
      return _NotificationType.budgetApproaching;
    }

    // 4. Settlement
    if (category.contains('settle') ||
        title.contains('settle') ||
        body.contains('settle') ||
        title.contains('reconcil') ||
        body.contains('transfer')) {
      return _NotificationType.settlement;
    }

    // 5. Household / Member
    if (category.contains('household') ||
        category.contains('member') ||
        title.contains('joined') ||
        body.contains('joined') ||
        title.contains('invite') ||
        body.contains('invite')) {
      return _NotificationType.household;
    }

    // 6. Expense (Default spending update)
    return _NotificationType.expense;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notificationsAsync = ref.watch(householdNotificationsProvider);
    final lastViewed = ref.watch(lastViewedNotificationProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? CoSpendColors.darkBorder
                    : CoSpendColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          notificationsAsync.maybeWhen(
            data: (items) {
              final unreadCount = items
                  .where((n) =>
                      n.createdAt.isAfter(lastViewed) &&
                      !_locallyReadIds.contains(n.id))
                  .length;

              return _NotificationsHeader(
                unreadCount: unreadCount,
                isDark: isDark,
                onMarkAllRead: unreadCount > 0 ? _markAllAsRead : null,
                onClose: () => Navigator.of(context).pop(),
              );
            },
            orElse: () => _NotificationsHeader(
              unreadCount: 0,
              isDark: isDark,
              onMarkAllRead: null,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),

          // Notification List / States
          Expanded(
            child: notificationsAsync.when(
              loading: () => const _NotificationSkeletonList(),
              error: (err, _) => _NotificationErrorView(
                errorMessage: err.toString(),
                onRetry: () => ref.invalidate(householdNotificationsProvider),
                isDark: isDark,
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _NotificationEmptyState(isDark: isDark);
                }

                // Partition into date groups: Today, Yesterday, Earlier
                final now = DateTime.now();
                final todayItems = <HouseholdNotification>[];
                final yesterdayItems = <HouseholdNotification>[];
                final earlierItems = <HouseholdNotification>[];

                for (final item in items) {
                  final diffDays = now.difference(item.createdAt).inDays;
                  final isSameDay = item.createdAt.year == now.year &&
                      item.createdAt.month == now.month &&
                      item.createdAt.day == now.day;
                  final isYesterday = item.createdAt.year == now.year &&
                      item.createdAt.month == now.month &&
                      item.createdAt.day == now.day - 1;

                  if (isSameDay) {
                    todayItems.add(item);
                  } else if (isYesterday || diffDays == 1) {
                    yesterdayItems.add(item);
                  } else {
                    earlierItems.add(item);
                  }
                }

                final rows = <_NotificationRowEntry>[];
                if (todayItems.isNotEmpty) {
                  rows.add(_NotificationHeaderEntry('Today', todayItems.length));
                  for (final item in todayItems) {
                    rows.add(_NotificationItemEntry(item));
                  }
                }
                if (yesterdayItems.isNotEmpty) {
                  rows.add(_NotificationHeaderEntry(
                      'Yesterday', yesterdayItems.length));
                  for (final item in yesterdayItems) {
                    rows.add(_NotificationItemEntry(item));
                  }
                }
                if (earlierItems.isNotEmpty) {
                  rows.add(_NotificationHeaderEntry(
                      'Earlier', earlierItems.length));
                  for (final item in earlierItems) {
                    rows.add(_NotificationItemEntry(item));
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    if (row is _NotificationHeaderEntry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 16,
                          bottom: 8,
                        ),
                        child: _GroupHeader(
                          title: row.title,
                          count: row.count,
                          isDark: isDark,
                        ),
                      );
                    }
                    final item = (row as _NotificationItemEntry).notification;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildNotificationCard(item, lastViewed, isDark),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    HouseholdNotification item,
    DateTime lastViewed,
    bool isDark,
  ) {
    final isUnread =
        item.createdAt.isAfter(lastViewed) && !_locallyReadIds.contains(item.id);
    final type = _classifyNotification(item);
    final relativeTime = _formatRelativeTime(item.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _NotificationCard(
        key: ValueKey('notification_${item.id}'),
        item: item,
        type: type,
        isUnread: isUnread,
        relativeTime: relativeTime,
        isDark: isDark,
        onTap: () => _markAsRead(item.id),
      ),
    );
  }
}

// =============================================================================
// HEADER COMPONENT
// =============================================================================

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.isDark,
    required this.onMarkAllRead,
    required this.onClose,
  });

  final int unreadCount;
  final bool isDark;
  final VoidCallback? onMarkAllRead;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? CoSpendColors.prussianBlueMedium.withValues(alpha: 0.6)
                  : CoSpendColors.prussianBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_rounded,
              size: 18,
              color: isDark ? Colors.white : CoSpendColors.prussianBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CoSpendColors.jadeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: CoSpendColors.jadeGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onMarkAllRead != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CoSpendColors.jadeGreen,
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Close',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// GROUP SECTION HEADER
// =============================================================================

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.count,
    required this.isDark,
  });

  final String title;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark
                ? CoSpendColors.darkTextMuted
                : CoSpendColors.textMuted,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark
                ? CoSpendColors.darkTextSubtle
                : CoSpendColors.textSubtle,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// NOTIFICATION CARD
// =============================================================================

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.item,
    required this.type,
    required this.isUnread,
    required this.relativeTime,
    required this.isDark,
    required this.onTap,
  });

  final HouseholdNotification item;
  final _NotificationType type;
  final bool isUnread;
  final String relativeTime;
  final bool isDark;
  final VoidCallback onTap;

  IconData get _icon {
    switch (type) {
      case _NotificationType.budgetExceeded:
        return Icons.error_outline_rounded;
      case _NotificationType.budgetApproaching:
        return Icons.warning_amber_rounded;
      case _NotificationType.settlement:
        return Icons.swap_horiz_rounded;
      case _NotificationType.household:
        return Icons.group_rounded;
      case _NotificationType.system:
        return Icons.info_outline_rounded;
      case _NotificationType.expense:
        return Icons.receipt_rounded;
    }
  }

  Color get _iconColor {
    switch (type) {
      case _NotificationType.budgetExceeded:
        return CoSpendColors.alertRed;
      case _NotificationType.budgetApproaching:
        return CoSpendColors.warningAmber;
      case _NotificationType.settlement:
        return CoSpendColors.prussianBlue;
      case _NotificationType.household:
        return const Color(0xFF6366F1); // Indigo
      case _NotificationType.system:
        return const Color(0xFF64748B);
      case _NotificationType.expense:
        return CoSpendColors.jadeGreen;
    }
  }

  String get _typeLabel {
    switch (type) {
      case _NotificationType.budgetExceeded:
        return 'Budget Exceeded';
      case _NotificationType.budgetApproaching:
        return 'Budget Limit';
      case _NotificationType.settlement:
        return 'Settlement';
      case _NotificationType.household:
        return 'Household';
      case _NotificationType.system:
        return 'System';
      case _NotificationType.expense:
        return item.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor;

    final backgroundColor = isUnread
        ? (isDark
            ? const Color(0xFF0D2D4E)
            : const Color(0xFFF1F8F4))
        : (isDark ? CoSpendColors.darkCard : Colors.white);

    final borderColor = isUnread
        ? CoSpendColors.jadeGreen.withValues(alpha: 0.35)
        : (isDark ? CoSpendColors.darkBorder : const Color(0x140A2542));

    return AnimatedContainer(
      duration: CoSpendAnimations.fast,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isUnread ? 1.5 : 1.0,
        ),
        boxShadow: CoSpendShadows.softCard,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contextual Icon Container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _icon,
                    size: 19,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Content Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Badge + Timestamp + Unread Dot
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _typeLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: iconColor,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            relativeTime,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? CoSpendColors.darkTextMuted
                                  : CoSpendColors.textSubtle,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: CoSpendColors.jadeGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                          color: isDark
                              ? CoSpendColors.darkTextPrimary
                              : CoSpendColors.prussianBlue,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Body Description
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),

                      // Optional Amount Chip
                      if (item.amountPaisa > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CoSpendColors.jadeGreen
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            Money.format(item.amountPaisa),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CoSpendColors.jadeGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SKELETON LOADING
// =============================================================================

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 16, width: 70),
        SizedBox(height: 10),
        SkeletonBox(height: 86),
        SizedBox(height: 10),
        SkeletonBox(height: 86),
        SizedBox(height: 20),
        SkeletonBox(height: 16, width: 90),
        SizedBox(height: 10),
        SkeletonBox(height: 86),
        SizedBox(height: 10),
        SkeletonBox(height: 86),
      ],
    );
  }
}

// =============================================================================
// INTENTIONAL EMPTY STATE
// =============================================================================

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? CoSpendColors.prussianBlueMedium.withValues(alpha: 0.6)
                    : CoSpendColors.prussianBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CoSpendColors.jadeGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: CoSpendColors.jadeGreen,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Inbox zero',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: CoSpendColors.jadeGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All caught up!',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When roommates log flat expenses or budget alerts trigger, you\'ll see them right here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? CoSpendColors.darkTextMuted
                    : CoSpendColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ERROR STATE
// =============================================================================

class _NotificationErrorView extends StatelessWidget {
  const _NotificationErrorView({
    required this.errorMessage,
    required this.onRetry,
    required this.isDark,
  });

  final String errorMessage;
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: CoSpendColors.alertRed,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load notifications',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? CoSpendColors.darkTextMuted : CoSpendColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
