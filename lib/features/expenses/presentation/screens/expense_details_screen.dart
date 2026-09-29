import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/expense.dart';
import '../providers/expense_providers.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  const ExpenseDetailsScreen({
    super.key,
    this.expense,
    this.expenseId,
  });

  final Expense? expense;
  final String? expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provided = expense;
    if (provided != null) {
      return _ExpenseDetailsBody(expense: provided);
    }

    final expensesAsync = ref.watch(householdExpensesProvider);
    return expensesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: ErrorView(
          message: error is AppException
              ? error.message
              : FirebaseErrorMapper.messageFor(error),
        ),
      ),
      data: (expenses) {
        final id = expenseId ?? '';
        final found = expenses.where((item) => item.id == id).firstOrNull;
        if (found == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense Details')),
            body: const ErrorView(
              title: 'Expense not found',
              message:
                  'This expense may have been deleted or is not in your flat.',
            ),
          );
        }
        return _ExpenseDetailsBody(expense: found);
      },
    );
  }
}

class _ExpenseDetailsBody extends ConsumerWidget {
  const _ExpenseDetailsBody({required this.expense});

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
    final scheme = theme.colorScheme;
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
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            onPressed: isDeleting ? null : () => _deleteExpense(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
            color: scheme.error,
            tooltip: 'Delete expense',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Hero Card with Category Icon, Amount, and Title
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(catIcon, color: catColor, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  expense.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Money.format(expense.amountPaisa),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
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
                        borderRadius: BorderRadius.circular(20),
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
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          expense.subcategory!,
                          style: TextStyle(
                            color: scheme.onSurface,
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
          const SizedBox(height: 16),

          // Payer & Date Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        payer != null && payer.name.isNotEmpty
                            ? payer.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paid by',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            payer?.name ?? 'Flatmate',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date spent',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(expense.spentAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Split Breakdown Card
          Text(
            'SPLIT BREAKDOWN',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < expense.splitAmongIds.length; i++) ...[
                  _SplitParticipantRow(
                    memberName:
                        memberMap[expense.splitAmongIds[i]]?.name ?? 'Flatmate',
                    sharePaisa: i < expense.splitAmountsPaisa.length
                        ? expense.splitAmountsPaisa[i]
                        : 0,
                    isPayer: expense.splitAmongIds[i] == expense.paidById,
                  ),
                  if (i < expense.splitAmongIds.length - 1)
                    const Divider(height: 16),
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
  });

  final String memberName;
  final int sharePaisa;
  final bool isPayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Text(
              memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  memberName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (isPayer) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Payer',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            Money.format(sharePaisa),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
