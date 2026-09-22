import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../household/presentation/providers/household_providers.dart';
import '../../domain/custom_category.dart';

/// Bottom sheet dialog allowing roommates to create a custom expense category
/// complete with custom icon, theme color, and initial subcategories.
class CreateCategorySheet extends ConsumerStatefulWidget {
  const CreateCategorySheet({super.key});

  /// Static helper to display the sheet.
  static Future<CustomCategory?> show(BuildContext context) {
    return showModalBottomSheet<CustomCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCategorySheet(),
    );
  }

  @override
  ConsumerState<CreateCategorySheet> createState() =>
      _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  final _nameController = TextEditingController();
  final _subcatController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  IconData _selectedIcon = Icons.sports_esports_rounded;
  Color _selectedColor = const Color(0xFF6366F1); // Indigo
  final List<String> _subcategories = [];
  bool _isSaving = false;

  static const List<IconData> _availableIcons = [
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.medical_services_rounded,
    Icons.school_rounded,
    Icons.flight_takeoff_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_cafe_rounded,
    Icons.fastfood_rounded,
    Icons.shopping_bag_rounded,
    Icons.pool_rounded,
    Icons.music_note_rounded,
    Icons.local_gas_station_rounded,
    Icons.home_repair_service_rounded,
    Icons.directions_bike_rounded,
    Icons.savings_rounded,
    Icons.laptop_chromebook_rounded,
    Icons.child_care_rounded,
    Icons.camera_alt_rounded,
    Icons.book_rounded,
    Icons.spa_rounded,
    Icons.local_laundry_service_rounded,
    Icons.celebration_rounded,
    Icons.category_rounded,
  ];

  static const List<Color> _availableColors = [
    Color(0xFF6366F1), // Royal Indigo
    Color(0xFF10B981), // Emerald Mint
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFFEF4444), // Crimson Coral
    Color(0xFF06B6D4), // Electric Cyan
    Color(0xFFA855F7), // Neon Violet
    Color(0xFFF97316), // Vivid Orange
    Color(0xFF84CC16), // Lime Green
    Color(0xFF3B82F6), // Sky Blue
    Color(0xFFEC4899), // Pink Rose
    Color(0xFF14B8A6), // Deep Teal
    Color(0xFF94A3B8), // Platinum Slate
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _subcatController.dispose();
    super.dispose();
  }

  void _addSubcategory() {
    final text = _subcatController.text.trim();
    if (text.isEmpty) return;
    if (_subcategories.any((s) => s.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory already added.')),
      );
      return;
    }
    setState(() {
      _subcategories.add(text);
      _subcatController.clear();
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active flat found to save category.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final catId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final customCategory = CustomCategory(
      id: catId,
      label: _nameController.text.trim(),
      iconCodePoint: _selectedIcon.codePoint,
      colorValue: _selectedColor.toARGB32(),
      subcategories: List.unmodifiable(_subcategories),
    );

    try {
      await ref.read(householdActionsProvider.notifier).addCustomCategory(
            householdId: household.id,
            category: customCategory,
          );
      if (mounted) {
        Navigator.of(context).pop(customCategory);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(_selectedIcon, color: _selectedColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Category',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Add a custom category for your flat',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Name
              Text(
                'CATEGORY NAME',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Gym & Fitness, Gaming, Pets',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Choose Color
              Text(
                'COLOR ACCENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedColor = color);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Choose Icon
              Text(
                'CHOOSE ICON',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIcon = icon);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: _selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: isSelected
                              ? _selectedColor
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Subcategories
              Text(
                'SUBCATEGORIES (OPTIONAL)',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Group specific expenses under this category',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),

              // Input row to add a subcategory
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subcatController,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addSubcategory(),
                      decoration: InputDecoration(
                        hintText: 'e.g. Monthly Fee, Supplements',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: scheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _addSubcategory,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18),
                        SizedBox(width: 4),
                        Text('Add'),
                      ],
                    ),
                  ),
                ],
              ),
              if (_subcategories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subcategories.map((subcat) {
                    return Chip(
                      label: Text(subcat),
                      backgroundColor: _selectedColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: _selectedColor.withValues(alpha: 0.4),
                      ),
                      deleteIcon:
                          const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        setState(() => _subcategories.remove(subcat));
                        HapticFeedback.selectionClick();
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 28),

              // Create button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
