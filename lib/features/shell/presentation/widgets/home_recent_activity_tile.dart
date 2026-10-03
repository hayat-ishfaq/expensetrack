import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../household/presentation/providers/household_providers.dart';

/// A single tile in the Recent Activity list on the home dashboard.
class HomeRecentActivityTile extends ConsumerWidget {
  const HomeRecentActivityTile({
    super.key,
    required this.description,
    required this.amountPaisa,
    required this.category,
    this.customCategoryId,
    this.subcategory,
    required this.spentAt,
    required this.payerName,
    required this.onTap,
    required this.isDark,
  });

  final String description;
  final int amountPaisa;
  final dynamic category;
  final String? customCategoryId;
  final String? subcategory;
  final DateTime spentAt;
  final String payerName;
  final VoidCallback onTap;
  final bool isDark;

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today, ${DateFormat('hh:mm a').format(date)}';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final custom = customCategoryId != null
        ? household?.customCategories
            .where((c) => c.id == customCategoryId)
            .firstOrNull
        : null;
    final catIcon = custom?.icon ?? category.icon as IconData;
    final catColor = custom?.color ?? category.color as Color;
    final catLabel = custom?.label ?? category.label as String;

    return InkWell(
      onTap: onTap,
      borderRadius: CoSpendRadii.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(catIcon, size: 20, color: catColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : CoSpendColors.prussianBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        catLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                      Text(
                        ' · ${_relativeDate(spentAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? CoSpendColors.darkTextMuted
                              : CoSpendColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '- ${Money.format(amountPaisa)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : CoSpendColors.prussianBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
