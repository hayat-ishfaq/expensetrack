import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/expense.dart';
import '../providers/expense_providers.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
  });

  final Expense expense;

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete expense?',
      message: 'This expense will be removed from your flat and balances will update.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;

    final currentHouseholdId =
        ref.read(sessionProvider).value?.householdId;
    if (currentHouseholdId == null) return;

    await ref.read(expenseActionsProvider.notifier).deleteExpense(
          householdId: currentHouseholdId,
          expenseId: expense.id,
        );

    final actionState = ref.read(expenseActionsProvider);
    if (!context.mounted) return;

    if (actionState.hasError) {
      final err = actionState.error!;
      final message = err is AppException
          ? err.message
          : FirebaseErrorMapper.messageFor(err);
      showAppSnack(context, message, error: true);
    } else {
      showAppSnack(context, 'Expense deleted.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final household = ref.watch(currentHouseholdProvider).value;

    final custom = expense.customCategoryId != null
        ? household?.customCategories
            .where((c) => c.id == expense.customCategoryId)
            .firstOrNull
        : null;
    final catLabel = custom?.label ?? expense.category.label;
    final catIcon = custom?.icon ?? expense.category.icon;
    final catColor = custom?.color ?? expense.category.color;

    final members = ref.watch(householdMembersProvider).value ?? const [];
    final memberMap = {for (final m in members) m.id: m};
    final payer = memberMap[expense.paidById];

    final isDeleting = ref.watch(expenseActionsProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? CoSpendColors.darkCanvas : CoSpendColors.canvas,
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            onPressed: isDeleting ? null : () => _deleteExpense(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
            color: CoSpendColors.alertRed,
            tooltip: 'Delete expense',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: CoSpendSpacing.md,
          vertical: CoSpendSpacing.md,
        ),
        children: [
          // Hero Card with Category Icon, Amount, and Title
          CoSpendCard(
            padding: const EdgeInsets.all(CoSpendSpacing.xl),
            child: Column(
              children: [
                TintedIcon(
                  icon: catIcon,
                  color: catColor,
                  containerSize: 64,
                  size: 32,
                ),
                const SizedBox(height: CoSpendSpacing.md),
                Text(
                  expense.description,
                  textAlign: TextAlign.center,
                  style: CoSpendTypography.ofHeadline(context).copyWith(
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.xs),
                Text(
                  Money.format(expense.amountPaisa),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? CoSpendColors.jadeGreen : CoSpendColors.prussianBlue,
                  ),
                ),
                const SizedBox(height: CoSpendSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: CoSpendRadii.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, size: 14, color: catColor),
                          const SizedBox(width: 5),
                          Text(
                            catLabel,
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (expense.subcategory != null &&
                        expense.subcategory!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CoSpendColors.darkCardElevated
                              : CoSpendColors.surfaceMuted,
                          borderRadius: CoSpendRadii.pillRadius,
                          border: Border.all(
                            color: isDark
                                ? CoSpendColors.darkBorder
                                : CoSpendColors.borderLight,
                          ),
                        ),
                        child: Text(
                          expense.subcategory!,
                          style: TextStyle(
                            color: isDark
                                ? CoSpendColors.darkTextPrimary
                                : CoSpendColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: CoSpendSpacing.md),

          // Payer & Date Info Card
          CoSpendCard(
            padding: const EdgeInsets.all(CoSpendSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    AppAvatar(
                      name: payer?.name ?? 'Flatmate',
                      photoUrl: payer?.photoUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paid by',
                            style: CoSpendTypography.ofCaption(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payer?.name ?? 'Flatmate',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? CoSpendColors.darkTextPrimary
                                  : CoSpendColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 24,
                  color: isDark
                      ? CoSpendColors.darkBorder
                      : CoSpendColors.borderLight,
                ),
                Row(
                  children: [
                    TintedIcon(
                      icon: Icons.calendar_today_rounded,
                      color: isDark
                          ? CoSpendColors.jadeGreen
                          : CoSpendColors.prussianBlue,
                      size: 18,
                      containerSize: 36,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date spent',
                          style: CoSpendTypography.ofCaption(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(expense.spentAt),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? CoSpendColors.darkTextPrimary
                                : CoSpendColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: CoSpendSpacing.lg),

          // Split Breakdown Section
          const CoSpendSectionHeader(
            title: 'SPLIT BREAKDOWN',
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          ),
          const SizedBox(height: CoSpendSpacing.xxs),

          CoSpendCard(
            padding: const EdgeInsets.symmetric(
              horizontal: CoSpendSpacing.md,
              vertical: CoSpendSpacing.xs,
            ),
            child: Column(
              children: [
                for (var i = 0; i < expense.splitAmongIds.length; i++) ...[
                  _SplitParticipantRow(
                    memberName:
                        memberMap[expense.splitAmongIds[i]]?.name ?? 'Flatmate',
                    photoUrl: memberMap[expense.splitAmongIds[i]]?.photoUrl,
                    sharePaisa: i < expense.splitAmountsPaisa.length
                        ? expense.splitAmountsPaisa[i]
                        : 0,
                    isPayer: expense.splitAmongIds[i] == expense.paidById,
                    isDark: isDark,
                  ),
                  if (i < expense.splitAmongIds.length - 1)
                    Divider(
                      height: 16,
                      color: isDark
                          ? CoSpendColors.darkBorder
                          : CoSpendColors.borderLight,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitParticipantRow extends StatelessWidget {
  const _SplitParticipantRow({
    required this.memberName,
    required this.sharePaisa,
    required this.isPayer,
    required this.isDark,
    this.photoUrl,
  });

  final String memberName;
  final String? photoUrl;
  final int sharePaisa;
  final bool isPayer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppAvatar(
            name: memberName,
            photoUrl: photoUrl,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    memberName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CoSpendColors.darkTextPrimary
                          : CoSpendColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPayer) ...[
                  const SizedBox(width: 8),
                  const CoSpendBadge(label: 'Payer'),
                ],
              ],
            ),
          ),
          Text(
            Money.format(sharePaisa),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark
                  ? CoSpendColors.darkTextPrimary
                  : CoSpendColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
