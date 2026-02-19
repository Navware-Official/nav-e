import 'package:flutter/material.dart';

/// Shows a theme-consistent SnackBar. Use [isError] for error feedback
/// (uses [ColorScheme.error]); otherwise uses [ColorScheme.primary] for success/info.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  final colorScheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? colorScheme.error : colorScheme.primary,
      duration: duration,
    ),
  );
}
