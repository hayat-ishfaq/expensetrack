import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';

/// Full-section error state with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CoSpendErrorState(
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }
}
