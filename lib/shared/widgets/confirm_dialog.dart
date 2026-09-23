import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';

/// Confirmation dialog for destructive actions (delete, leave, remove…).
/// Returns `true` only when the user explicitly confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoSpendRadii.dialog),
          side: BorderSide(
            color: isDark ? CoSpendColors.darkBorder : CoSpendColors.borderLight,
          ),
        ),
        backgroundColor: isDark ? CoSpendColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: CoSpendTypography.ofHeadline(dialogContext).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: CoSpendTypography.ofBody(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive
                  ? CoSpendColors.alertRed
                  : (isDark ? CoSpendColors.jadeGreen : CoSpendColors.prussianBlue),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
