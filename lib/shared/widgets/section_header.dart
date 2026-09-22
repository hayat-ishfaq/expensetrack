import 'package:flutter/material.dart';

/// Consistent heading for dashboard/section blocks, with an optional
/// trailing action (e.g. "View all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 12, 12),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final action = onAction;
    final label = actionLabel;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
          if (action != null && label != null)
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
