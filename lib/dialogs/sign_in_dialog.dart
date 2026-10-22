import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/screens/dashboard_page.dart';
import 'package:aidlinkapp/screens/admin/admin_dashboard_page.dart';
import 'package:aidlinkapp/screens/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInDialog extends StatefulWidget {
  const SignInDialog({super.key});
  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final _formKey         = GlobalKey<FormState>();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscure    = true;
  bool _rememberMe = false;
  bool _loading    = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs      = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email')    ?? '';
    final savedPass  = prefs.getString('saved_password') ?? '';
    final remember   = prefs.getBool('remember_me')      ?? false;
    if (remember && savedEmail.isNotEmpty) {
      setState(() {
        emailController.text    = savedEmail;
        passwordController.text = savedPass;
        _rememberMe             = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email',    emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final auth   = Get.find<AuthController>();
    final result = await auth.signIn(
      emailController.text.trim(),
      passwordController.text,
    );

    if (result == 'success') {
      // Tells Google Password Manager to save these credentials
      TextInput.finishAutofillContext(shouldSave: true);
      await _saveCredentials();
      if (auth.signedEmail.value.toLowerCase().contains('admin') ||
          auth.isAdmin.value) {
        Get.offAll(() => const AdminDashboardPage());
      } else {
        Get.offAll(() => const DashboardPage());
      }
    } else {
      TextInput.finishAutofillContext(shouldSave: false);
      setState(() => _loading = false);
      Get.snackbar('Sign In Failed', result,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          // ── AutofillGroup tells Flutter this is a login form ──────────────
          // Google Password Manager detects it and offers to fill/save
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Semantics(
                      button: true,
                      label: 'Close sign in dialog',
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Icon(Icons.assist_walker,
                      size: 50, color: Color(0xff164EB0)),
                  const SizedBox(height: 12),
                  const Text('Sign In to AidLink',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Access your disability assistance matches',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 28),

                  // Email — autofillHints enables Google Password Manager
                  Semantics(
                    label: 'Email address field',
                    textField: true,
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Please enter a valid email address';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password — autofillHints enables Google Password Manager
                  Semantics(
                    label: 'Password field',
                    textField: true,
                    obscured: true,
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Semantics(
                          button: true,
                          label: _obscure ? 'Show password' : 'Hide password',
                          child: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your password';
                        return null;
                      },
                      onFieldSubmitted: (_) => _signIn(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Remember Me + Forgot Password row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Semantics(
                          label: 'Remember my login info. ${_rememberMe ? 'Checked' : 'Unchecked'}',
                          child: SizedBox(
                            width: 24, height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xff164EB0),
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val ?? false),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember me',
                            style: TextStyle(fontSize: 13, color: Colors.black87)),
                      ]),
                      Semantics(
                        button: true,
                        label: 'Forgot your password? Go to password reset page.',
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Get.to(() => const ForgotPasswordPage());
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xff164EB0),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 44),
                          ),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign In button
                  Semantics(
                    button: true,
                    label: 'Sign in to AidLink',
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff164EB0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Sign In',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Semantics(
                    button: true,
                    label: 'Cancel and close this dialog',
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}