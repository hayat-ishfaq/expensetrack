import 'package:flutter/material.dart';

/// Consistent success/error snackbars across the app.
void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? scheme.error : null,
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 20,
              color: error ? scheme.onError : scheme.onInverseSurface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error ? scheme.onError : scheme.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
