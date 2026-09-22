import 'package:flutter/material.dart';

/// Primary call-to-action button with a built-in loading state.
///
/// The button is disabled while [isLoading] is true or when [onPressed] is
/// null, so a form can keep it disabled until it becomes valid.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final canTap = onPressed != null && !isLoading;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canTap ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.onPrimary,
                ),
              )
            : icon == null
                ? Text(label)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
      ),
    );
  }
}
