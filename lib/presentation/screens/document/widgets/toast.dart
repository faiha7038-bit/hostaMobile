// lib/features/widgets/toast.dart
import 'package:flutter/material.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void showToast(String message, {bool isError = false, bool isWarning = false}) {
  
  final context = navigatorKey.currentContext;
  if (context == null) {
   
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