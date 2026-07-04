import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';

Future<bool?> showLoginRequiredDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Login Required"),
        content: const Text(
          "You need to login to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Signin(),
                ),
              );
            },
            child: const Text("Login"),
          ),
        ],
      );
    },
  );
}
