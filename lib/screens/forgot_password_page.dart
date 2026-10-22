import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:aidlinkapp/utilities/base_url.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool _loading = false;
  bool _sent    = false;
  String _error = '';

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (res.statusCode == 200) {
        setState(() { _sent = true; _loading = false; });
      } else {
        setState(() {
          _error   = res.body.isNotEmpty ? res.body : 'Something went wrong. Try again.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error   = 'Network error. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bgColor    = isDark ? const Color(0xff111827) : const Color(0xfff5f7fc);
    final cardColor  = isDark ? const Color(0xff1f2937) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xff164EB0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Forgot Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _sent
                    ? _buildSuccessView(isDark)
                    : _buildFormView(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    final titleColor = isDark ? Colors.white            : const Color(0xff0A3080);
    final bodyColor  = isDark ? const Color(0xffcbd5e1) : Colors.grey[700]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff164EB0).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset_outlined,
              size: 40, color: Color(0xff164EB0)),
        ),
        const SizedBox(height: 20),
        Text('Reset Your Password',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor)),
        const SizedBox(height: 8),
        Text(
          'Enter the email address linked to your AidLink account and we\'ll send you a reset link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: bodyColor, height: 1.5),
        ),
        const SizedBox(height: 28),

        // ── Error banner ──────────────────────────────────────────────────
        if (_error.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDark ? Colors.red.shade400 : Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.error_outline,
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error,
                    style: TextStyle(
                        color: isDark
                            ? Colors.red.shade200
                            : Colors.red.shade800,
                        fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // ── Email field ───────────────────────────────────────────────────
        TextField(
          controller: emailController,
          onChanged: (_) {
            if (_error.isNotEmpty) setState(() => _error = '');
          },
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: TextStyle(
                color: isDark ? const Color(0xff94a3b8) : Colors.grey[700]),
            prefixIcon: Icon(Icons.email_outlined,
                color: isDark ? const Color(0xff94a3b8) : Colors.grey[700]),
            filled: true,
            fillColor: isDark
                ? const Color(0xff374151)
                : Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _error.isNotEmpty
                    ? Colors.red.shade400
                    : (isDark
                        ? const Color(0xff4b5563)
                        : Colors.grey.shade400),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xff164EB0), width: 2),
            ),
            isDense: true,
          ),
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _sendResetEmail(),
        ),
        const SizedBox(height: 24),

        // ── Send button ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff164EB0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _loading ? null : _sendResetEmail,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Send Reset Link',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xff94a3b8) : Colors.grey[600]),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark) {
    final titleColor = isDark ? Colors.white            : const Color(0xff0A3080);
    final bodyColor  = isDark ? const Color(0xffcbd5e1) : Colors.grey[700]!;
    final subColor   = isDark ? const Color(0xff94a3b8) : Colors.grey[600]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 48, color: Colors.green),
        ),
        const SizedBox(height: 20),
        Text('Check Your Email',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor)),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to:\n${emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: bodyColor, height: 1.6),
        ),
        const SizedBox(height: 8),
        Text(
          'The link expires in 1 hour. Check your spam folder if you don\'t see it.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: subColor),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff164EB0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(),
            child: const Text('Back to Sign In',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _sent  = false;
            _error = '';
            emailController.clear();
          }),
          style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xff94a3b8) : Colors.grey[600]),
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}