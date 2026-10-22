import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.orange),
          SizedBox(width: 10),
          Text('Sign Out'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to sign out?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'You will need to sign in again to access your assistance programs.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // ── Navigate FIRST, then clear session ──────────────────
                  // Clearing session before navigation causes the dashboard
                  // to rebuild with empty state for a brief flash.
                  Get.offAll(() => const HomePage());
                  Get.find<AuthController>().clearSession();
                  Get.snackbar(
                    'Signed Out',
                    'You have been successfully signed out',
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}