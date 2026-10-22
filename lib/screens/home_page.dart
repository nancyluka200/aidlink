import 'package:flutter/material.dart';
import 'package:aidlinkapp/dialogs/create_account_dialog.dart';
import 'package:aidlinkapp/dialogs/sign_in_dialog.dart';
import 'package:aidlinkapp/screens/admin/admin_login_page.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1,
                colors: [
                  Colors.white,
                  Color.fromARGB(255, 6, 84, 74),
                  Colors.white,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assist_walker,
                  size: 80,
                  color: Color(0xff164EB0),
                ),
                const SizedBox(height: 20),
                Text(
                  'AidLink',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff164EB0),
                      ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Smart Social Assistance Matching',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const SignInDialog(),
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff164EB0),
                      side: const BorderSide(color: Color(0xff164EB0)),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const CreateAccountDialog(),
                    ),
                    child: const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Connect with government and NGO assistance programs that match your profile',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 30),

                // ── Discrete admin access — small, unobtrusive ──────────────
                GestureDetector(
                  onTap: () => Get.to(() => const AdminLoginPage()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          'Sign in as Admin',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}