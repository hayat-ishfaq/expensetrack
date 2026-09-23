import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';

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
    return CoSpendPrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      isFullWidth: true,
      height: 52.0,
    );
  }
}
