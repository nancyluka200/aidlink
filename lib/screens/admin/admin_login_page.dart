import 'package:aidlinkapp/screens/admin/admin_dashboard_page.dart';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final auth               = Get.find<AuthController>();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  bool   _loading      = false;
  bool   _obscure      = true;
  String _errorMessage = '';

  bool _emailError    = false;
  bool _passwordError = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _setError(String message, {bool email = false, bool password = false}) {
    setState(() {
      _errorMessage  = message;
      _emailError    = email;
      _passwordError = password;
    });
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage  = '';
        _emailError    = false;
        _passwordError = false;
      });
    }
  }

  Future<void> _login() async {
    if (emailController.text.isEmpty && passwordController.text.isEmpty) {
      _setError('Please enter your email and password.',
          email: true, password: true);
      return;
    }
    if (emailController.text.isEmpty) {
      _setError('Please enter your admin email.', email: true);
      return;
    }
    if (passwordController.text.isEmpty) {
      _setError('Please enter your password.', password: true);
      return;
    }

    setState(() {
      _loading       = true;
      _errorMessage  = '';
      _emailError    = false;
      _passwordError = false;
    });

    final result = await auth.signIn(
      emailController.text.trim(),
      passwordController.text,
    );

    setState(() => _loading = false);

    if (result == 'success') {
      final isAdminUser = auth.isAdmin.value ||
          auth.signedEmail.value.toLowerCase().contains('admin');

      if (isAdminUser) {
        // Delay ensures token is fully persisted before navigating
        await Future.delayed(const Duration(milliseconds: 300));
        Get.offAll(() => const AdminDashboardPage());
      } else {
        _setError('This account does not have admin access.',
            email: true, password: false);
        auth.clearSession();
      }
    } else {
      final msg = result.toLowerCase();
      if (msg.contains('email') || msg.contains('invalid')) {
        _setError(result, email: true, password: true);
      } else if (msg.contains('password')) {
        _setError(result, password: true);
      } else {
        _setError(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    return Scaffold(
      body: isWide ? _wideLayout() : _narrowLayout(),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff050e30), Color(0xff0A3080)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15), width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      size: 72, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text('AidLink',
                    style: TextStyle(
                        color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('Admin Portal',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 15, letterSpacing: 2)),
                const SizedBox(height: 32),
                Container(width: 40, height: 2, color: Colors.white24),
                const SizedBox(height: 28),
                _infoPill(Icons.people_outline, 'Manage Users'),
                const SizedBox(height: 10),
                _infoPill(Icons.verified_outlined, 'Verify PWD Cards'),
                const SizedBox(height: 10),
                _infoPill(Icons.bar_chart, 'View Statistics'),
                const SizedBox(height: 10),
                _infoPill(Icons.list_alt_outlined, 'Manage Programs'),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[50],
            child: Center(child: _loginForm()),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff0A3080), Color(0xfff5f7fc)],
          stops: [0.0, 0.35],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _loginForm(),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _loginForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff0A3080).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_outlined,
                    size: 36, color: Color(0xff0A3080)),
              ),
              const SizedBox(height: 16),
              const Text('Administrator Sign In',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0A3080))),
              const SizedBox(height: 4),
              Text('Restricted Access – Authorised Personnel Only',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 24),

              // ── Inline error banner ──────────────────────────────────────
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Email field ──────────────────────────────────────────────
              TextField(
                controller: emailController,
                onChanged: (_) => _clearError(),
                decoration: InputDecoration(
                  labelText: 'Admin Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: _emailError ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _emailError
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                      width: _emailError ? 1.5 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _emailError
                          ? Colors.red.shade600
                          : const Color(0xff0A3080),
                      width: 2.0,
                    ),
                  ),
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 14),

              // ── Password field ───────────────────────────────────────────
              TextField(
                controller: passwordController,
                obscureText: _obscure,
                onChanged: (_) => _clearError(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: _passwordError ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _passwordError
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                      width: _passwordError ? 1.5 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _passwordError
                          ? Colors.red.shade600
                          : const Color(0xff0A3080),
                      width: 2.0,
                    ),
                  ),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),

              // ── Sign In button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A3080),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const Text('Back to main app'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}