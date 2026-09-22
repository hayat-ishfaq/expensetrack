import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/household_member.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/custom_category.dart';
import '../../domain/expense.dart';
import '../../domain/expense_category.dart';
import '../../domain/split_modes.dart';
import '../providers/expense_providers.dart';
import '../widgets/create_category_sheet.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  CustomCategory? _selectedCustomCategory;
  String? _selectedSubcategory;
  DateTime _spentAt = DateTime.now();
  String? _paidById;
  SplitMode _splitMode = SplitMode.equal;

  // Selected participant IDs for equal split
  final Set<String> _selectedMemberIds = {};

  // Controllers for custom amount inputs
  final Map<String, TextEditingController> _customControllers = {};

  // Controllers for percentage inputs
  final Map<String, TextEditingController> _percentageControllers = {};

  bool _initializedMembers = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    for (final controller in _customControllers.values) {
      controller.dispose();
    }
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  void _initMembersIfNeeded(List<HouseholdMember> members) {
    if (_initializedMembers || members.isEmpty) return;
    _initializedMembers = true;

    final currentUid = ref.read(sessionProvider).value?.user?.id;
    _paidById = members.any((m) => m.id == currentUid)
        ? currentUid
        : members.first.id;

    _selectedMemberIds.addAll(members.map((m) => m.id));

    // Initialize custom & percentage controllers
    final equalPercent = (100.0 / members.length).toStringAsFixed(1);
    for (final m in members) {
      final customCtrl = TextEditingController();
      customCtrl.addListener(() => setState(() {}));
      _customControllers[m.id] = customCtrl;

      final pctCtrl = TextEditingController(text: equalPercent);
      pctCtrl.addListener(() => setState(() {}));
      _percentageControllers[m.id] = pctCtrl;
    }
  }

  int get _amountPaisa => Money.tryParsePaisa(_amountController.text) ?? 0;

  String? _validateSplits(List<HouseholdMember> members) {
    if (_amountPaisa <= 0) return 'Enter an expense amount greater than zero.';
    if (_paidById == null) return 'Select who paid for this expense.';

    switch (_splitMode) {
      case SplitMode.equal:
        if (_selectedMemberIds.isEmpty) {
          return 'Select at least one member to split with.';
        }
        return null;

      case SplitMode.custom:
        final shares = members.map((m) {
          final text = _customControllers[m.id]?.text ?? '0';
          return Money.tryParsePaisa(text) ?? 0;
        }).toList();
        return SplitHelper.validateCustomShares(
          totalPaisa: _amountPaisa,
          sharesPaisa: shares,
        );

      case SplitMode.percentage:
        final percentages = members.map((m) {
          final text = _percentageControllers[m.id]?.text ?? '0';
          return double.tryParse(text) ?? 0.0;
        }).toList();
        return SplitHelper.validatePercentages(
          totalPaisa: _amountPaisa,
          percentages: percentages,
        );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _spentAt = picked);
    }
  }

  Future<void> _promptAddSubcategory(String categoryId) async {
    final controller = TextEditingController();
    final newSubcat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Chai, Groceries, Generator Fuel',
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newSubcat != null && newSubcat.isNotEmpty) {
      final household = ref.read(currentHouseholdProvider).value;
      if (household != null) {
        ref.read(householdActionsProvider.notifier).addSubcategory(
              householdId: household.id,
              categoryId: categoryId,
              subcategory: newSubcat,
            );
      }
      setState(() => _selectedSubcategory = newSubcat);
      HapticFeedback.selectionClick();
    }
  }

  void _showCategoryPicker() {
    final household = ref.read(currentHouseholdProvider).value;
    final customCategories = household?.customCategories ?? const [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final created =
                              await CreateCategorySheet.show(context);
                          if (created != null && mounted) {
                            setState(() {
                              _selectedCustomCategory = created;
                              _category = ExpenseCategory.other;
                              _selectedSubcategory = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Custom'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (customCategories.isNotEmpty) ...[
                          Text(
                            'HOUSEHOLD CUSTOM CATEGORIES',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                            itemCount: customCategories.length,
                            itemBuilder: (context, index) {
                              final cat = customCategories[index];
                              final isSelected =
                                  _selectedCustomCategory?.id == cat.id;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCustomCategory = cat;
                                    _category = ExpenseCategory.other;
                                    _selectedSubcategory = null;
                                  });
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cat.color.withValues(alpha: 0.15)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    border: Border.all(
                                      color: isSelected
                                          ? cat.color
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: cat.color
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(cat.icon,
                                            color: cat.color, size: 24),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          'STANDARD CATEGORIES',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: ExpenseCategory.values.length,
                          itemBuilder: (context, index) {
                            final cat = ExpenseCategory.values[index];
                            final isSelected = _selectedCustomCategory ==
                                    null &&
                                cat == _category;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _category = cat;
                                  _selectedCustomCategory = null;
                                  _selectedSubcategory = null;
                                });
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cat.color.withValues(alpha: 0.15)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  border: Border.all(
                                    color: isSelected
                                        ? cat.color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            cat.color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(cat.icon,
                                          color: cat.color, size: 24),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.label,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPayerPicker(List<HouseholdMember> members) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Who paid?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final member in members)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(member.email),
                    trailing: _paidById == member.id
                        ? Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _paidById = member.id);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(List<HouseholdMember> members) async {
    if (!_formKey.currentState!.validate()) return;

    final splitError = _validateSplits(members);
    if (splitError != null) {
      showAppSnack(context, splitError, error: true);
      return;
    }

    final householdId = ref.read(sessionProvider).value?.householdId;
    final currentUid = ref.read(sessionProvider).value?.user?.id;
    if (householdId == null || currentUid == null) {
      showAppSnack(context, 'Missing flat session.', error: true);
      return;
    }

    List<String> splitAmongIds = [];
    List<int> splitAmountsPaisa = [];

    switch (_splitMode) {
      case SplitMode.equal:
        splitAmongIds = _selectedMemberIds.toList();
        splitAmountsPaisa = SplitHelper.computeEqualShares(
          _amountPaisa,
          splitAmongIds.length,
        );
        break;

      case SplitMode.custom:
        for (final m in members) {
          final amt = Money.tryParsePaisa(_customControllers[m.id]?.text) ?? 0;
          if (amt > 0) {
            splitAmongIds.add(m.id);
            splitAmountsPaisa.add(amt);
          }
        }
        break;

      case SplitMode.percentage:
        final activeMembers = <HouseholdMember>[];
        final pcts = <double>[];
        for (final m in members) {
          final pct =
              double.tryParse(_percentageControllers[m.id]?.text ?? '') ?? 0.0;
          if (pct > 0) {
            activeMembers.add(m);
            pcts.add(pct);
          }
        }
        splitAmongIds = activeMembers.map((m) => m.id).toList();
        splitAmountsPaisa = SplitHelper.computePercentageShares(
          totalPaisa: _amountPaisa,
          percentages: pcts,
        );
        break;
    }

    final expense = Expense(
      id: '',
      householdId: householdId,
      description: _descriptionController.text.trim(),
      category: _category,
      customCategoryId: _selectedCustomCategory?.id,
      subcategory: _selectedSubcategory,
      amountPaisa: _amountPaisa,
      paidById: _paidById!,
      splitAmongIds: splitAmongIds,
      splitAmountsPaisa: splitAmountsPaisa,
      spentAt: _spentAt,
      createdByUserId: currentUid,
      createdAt: DateTime.now(),
      splitType: _splitMode.name,
    );

    await ref.read(expenseActionsProvider.notifier).addExpense(expense);

    final actionState = ref.read(expenseActionsProvider);
    if (!mounted) return;

    if (actionState.hasError) {
      final err = actionState.error!;
      final message = err is AppException
          ? err.message
          : FirebaseErrorMapper.messageFor(err);
      showAppSnack(context, message, error: true);
    } else {
      showAppSnack(context, 'Expense added successfully.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final membersAsync = ref.watch(householdMembersProvider);
    final isSaving = ref.watch(expenseActionsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: false,
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(FirebaseErrorMapper.messageFor(error)),
        ),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No household members found.'));
          }
          _initMembersIfNeeded(members);

          final payer = members.firstWhere(
            (m) => m.id == _paidById,
            orElse: () => members.first,
          );

          final splitValidationError = _validateSplits(members);
          final isFormValid =
              _amountPaisa > 0 &&
              _descriptionController.text.trim().isNotEmpty &&
              splitValidationError == null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Top Amount Card
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How much was spent?',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Rs. ',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                style:
                                    theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: Validators.amount,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Chicken + Drinks, Rice, Rent',
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: Validators.description,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Category & Date in a Row
                Row(
                  children: [
                    // Category selector chip
                    Builder(
                      builder: (context) {
                        final activeCatLabel =
                            _selectedCustomCategory?.label ?? _category.label;
                        final activeCatIcon =
                            _selectedCustomCategory?.icon ?? _category.icon;
                        final activeCatColor =
                            _selectedCustomCategory?.color ?? _category.color;

                        return Expanded(
                          child: InkWell(
                            onTap: _showCategoryPicker,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: activeCatColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      activeCatIcon,
                                      color: activeCatColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedCustomCategory != null
                                              ? 'Custom Category'
                                              : 'Category',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          activeCatLabel,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // Date selector chip
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: scheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(_spentAt),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Subcategories Section
                Builder(
                  builder: (context) {
                    final activeCatId =
                        _selectedCustomCategory?.id ?? _category.id;
                    final activeCatColor =
                        _selectedCustomCategory?.color ?? _category.color;
                    final household = ref.watch(currentHouseholdProvider).value;
                    final availableSubcats = household?.getSubcategories(activeCatId) ??
                        defaultCategorySubcategories[activeCatId] ??
                        const [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SUBCATEGORY (OPTIONAL)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (_selectedSubcategory != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedSubcategory = null),
                                child: Text(
                                  'Clear',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...availableSubcats.map((subcat) {
                                final isSelected = _selectedSubcategory == subcat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(subcat),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    avatar: isSelected
                                        ? const Icon(Icons.check, size: 16)
                                        : null,
                                    backgroundColor: scheme.surfaceContainerLow,
                                    selectedColor: activeCatColor.withValues(alpha: 0.2),
                                    side: BorderSide(
                                      color: isSelected
                                          ? activeCatColor
                                          : scheme.outlineVariant.withValues(alpha: 0.4),
                                    ),
                                    labelStyle: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? activeCatColor : scheme.onSurface,
                                      fontSize: 13,
                                    ),
                                    onSelected: (selected) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedSubcategory = selected ? subcat : null;
                                      });
                                    },
                                  ),
                                );
                              }),
                              ActionChip(
                                avatar: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Subcategory'),
                                backgroundColor: scheme.surfaceContainerLow,
                                side: BorderSide(
                                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                  fontSize: 13,
                                ),
                                onPressed: () => _promptAddSubcategory(activeCatId),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Paid By Selector Tile
                InkWell(
                  onTap: () => _showPayerPicker(members),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            payer.name.isNotEmpty
                                ? payer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                payer.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Change',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Split Header & Segmented Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Split expense',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_splitMode == SplitMode.equal &&
                        _selectedMemberIds.isNotEmpty)
                      Text(
                        '${Money.format(_amountPaisa ~/ _selectedMemberIds.length)} / person',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                SegmentedButton<SplitMode>(
                  segments: const [
                    ButtonSegment(
                      value: SplitMode.equal,
                      label: Text('Equal'),
                      icon: Icon(Icons.drag_handle_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: SplitMode.custom,
                      label: Text('Exact'),
                      icon: Icon(Icons.attach_money_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: SplitMode.percentage,
                      label: Text('%'),
                      icon: Icon(Icons.percent_rounded, size: 18),
                    ),
                  ],
                  selected: {_splitMode},
                  onSelectionChanged: (newSelection) {
                    setState(() => _splitMode = newSelection.first);
                  },
                ),
                const SizedBox(height: 12),

                // Split Validation Warning / Success Card
                if (splitValidationError != null && _amountPaisa > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: scheme.onErrorContainer, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            splitValidationError,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Participant List per mode
                _buildSplitSection(theme, scheme, members),

                const SizedBox(height: 24),

                // Submit Button
                LoadingButton(
                  label: 'Add Expense',
                  icon: Icons.check_rounded,
                  isLoading: isSaving,
                  onPressed: isFormValid ? () => _submit(members) : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitSection(
    ThemeData theme,
    ColorScheme scheme,
    List<HouseholdMember> members,
  ) {
    switch (_splitMode) {
      case SplitMode.equal:
        return Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              for (final member in members)
                CheckboxListTile(
                  value: _selectedMemberIds.contains(member.id),
                  activeColor: scheme.primary,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedMemberIds.add(member.id);
                      } else {
                        // Prevent unselecting all
                        if (_selectedMemberIds.length > 1) {
                          _selectedMemberIds.remove(member.id);
                        }
                      }
                    });
                  },
                  secondary: CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _selectedMemberIds.contains(member.id) &&
                            _selectedMemberIds.isNotEmpty
                        ? Money.format(
                            _amountPaisa ~/ _selectedMemberIds.length)
                        : 'Excluded',
                    style: TextStyle(
                      color: _selectedMemberIds.contains(member.id)
                          ? scheme.onSurfaceVariant
                          : scheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );

      case SplitMode.custom:
        return Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final member in members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.surfaceContainerHighest,
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: TextFormField(
                            controller: _customControllers[member.id],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              isDense: true,
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

      case SplitMode.percentage:
        return Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final member in members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.surfaceContainerHighest,
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                Money.format(
                                  (_amountPaisa *
                                          (double.tryParse(
                                                _percentageControllers[
                                                        member.id]
                                                    ?.text ??
                                                '0',
                                              ) ??
                                              0) /
                                          100)
                                      .round(),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            controller: _percentageControllers[member.id],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,1}'),
                              ),
                            ],
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              suffixText: '%',
                              isDense: true,
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }
}
