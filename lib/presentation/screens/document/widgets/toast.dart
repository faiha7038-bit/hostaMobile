// lib/features/widgets/toast.dart
import 'package:flutter/material.dart';

// Define a global navigator key (must be initialized in main.dart)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void showToast(String message, {bool isError = false, bool isWarning = false}) {
  // Use the global navigator key to get current context
  final context = navigatorKey.currentContext;
  if (context == null) {
    // Fallback: print to console if no context available
    debugPrint('Toast: $message');
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : (isWarning ? Colors.orange : Colors.green),
      behavior: SnackBarBehavior.floating,
    ),
  );
}