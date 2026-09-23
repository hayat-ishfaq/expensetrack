import 'package:flutter/material.dart';

/// Password input with a visibility toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.errorText,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: Semantics(
          button: true,
          label: _obscured ? 'Show password' : 'Hide password',
          child: IconButton(
            onPressed: () => setState(() => _obscured = !_obscured),
            tooltip: _obscured ? 'Show password' : 'Hide password',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              _obscured
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              semanticLabel: _obscured ? 'Show password' : 'Hide password',
            ),
          ),
        ),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onFieldSubmitted,
    );
  }
}