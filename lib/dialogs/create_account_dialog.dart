import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/screens/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class CreateAccountDialog extends StatefulWidget {
  const CreateAccountDialog({super.key});

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  RxString status = 'enter_details'.obs;

  final firstNameController   = TextEditingController();
  final lastNameController    = TextEditingController();
  final emailController       = TextEditingController();
  final phoneController       = TextEditingController();
  final passwordController    = TextEditingController();
  final confirmPassController = TextEditingController();

  bool _obscure        = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms  = false;

  String _firstNameError   = '';
  String _lastNameError    = '';
  String _emailError       = '';
  String _phoneError       = '';
  String _passwordError    = '';
  String _confirmPassError = '';
  String _termsError       = '';

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  bool get _isAdminEmail =>
      emailController.text.trim().toLowerCase().contains('admin');

  int get _passwordStrength {
    final p = passwordController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8)  score++;
    if (p.length >= 12) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 1) return Colors.red;
    if (s <= 2) return Colors.orange;
    if (s <= 3) return Colors.amber;
    return Colors.green;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s <= 1) return 'Weak';
    if (s <= 2) return 'Fair';
    if (s <= 3) return 'Good';
    return 'Strong';
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      // First name
      if (firstNameController.text.trim().isEmpty) {
        _firstNameError = 'First name is required';
        valid = false;
      } else if (firstNameController.text.trim().length < 2) {
        _firstNameError = 'Must be at least 2 characters';
        valid = false;
      } else {
        _firstNameError = '';
      }

      // Last name
      if (lastNameController.text.trim().isEmpty) {
        _lastNameError = 'Last name is required';
        valid = false;
      } else if (lastNameController.text.trim().length < 2) {
        _lastNameError = 'Must be at least 2 characters';
        valid = false;
      } else {
        _lastNameError = '';
      }

      // Email
      if (emailController.text.trim().isEmpty) {
        _emailError = 'Email is required';
        valid = false;
      } else if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
          .hasMatch(emailController.text.trim())) {
        _emailError = 'Enter a valid email address';
        valid = false;
      } else if (_isAdminEmail) {
        _emailError =
            'Admin accounts cannot be created here. Use the Admin Portal.';
        valid = false;
      } else {
        _emailError = '';
      }

      // Phone (optional but validated if filled)
      final phone = phoneController.text.trim();
      if (phone.isNotEmpty) {
        if (!RegExp(r'^\+?[\d\s\-]{9,15}$').hasMatch(phone)) {
          _phoneError = 'Enter a valid phone number';
          valid = false;
        } else {
          _phoneError = '';
        }
      } else {
        _phoneError = '';
      }

      // Password
      if (passwordController.text.isEmpty) {
        _passwordError = 'Password is required';
        valid = false;
      } else if (passwordController.text.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      } else {
        _passwordError = '';
      }

      // Confirm password
      if (confirmPassController.text.isEmpty) {
        _confirmPassError = 'Please confirm your password';
        valid = false;
      } else if (confirmPassController.text != passwordController.text) {
        _confirmPassError = 'Passwords do not match';
        valid = false;
      } else {
        _confirmPassError = '';
      }

      // Terms
      if (!_agreedToTerms) {
        _termsError = 'You must agree to the terms to continue';
        valid = false;
      } else {
        _termsError = '';
      }
    });
    return valid;
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'firstName':   _firstNameError   = ''; break;
        case 'lastName':    _lastNameError    = ''; break;
        case 'email':       _emailError       = ''; break;
        case 'phone':       _phoneError       = ''; break;
        case 'password':    _passwordError    = ''; break;
        case 'confirmPass': _confirmPassError = ''; break;
      }
    });
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('Terms of Service',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'By creating an AidLink account, you agree to:\n\n'
            '1. Provide accurate and truthful information about yourself and your disability status.\n\n'
            '2. Use AidLink solely to find and apply for legitimate government disability support programs.\n\n'
            '3. Not misrepresent your disability status or eligibility criteria.\n\n'
            '4. Keep your account credentials secure and not share them with others.\n\n'
            '5. Accept that AidLink is a matching tool and does not guarantee program approval.\n\n'
            '6. Comply with all applicable Kenyan laws, including the Persons with Disabilities Act No. 14 of 2003.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff164EB0),
                foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _agreedToTerms = true;
                _termsError    = '';
              });
              Get.back();
            },
            child: const Text('I Agree'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text('Privacy Policy',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'AidLink Privacy Policy\n\n'
            'We collect the following information:\n'
            '• Name, email, and phone number for account creation\n'
            '• Disability type, age, location, and income for program matching\n'
            '• PWD card details for verification purposes\n\n'
            'How we use your data:\n'
            '• To match you to relevant government disability programs\n'
            '• To verify your PWD card status with the AidLink admin team\n'
            '• We do NOT sell your data to third parties\n'
            '• We do NOT share your data with advertisers\n\n'
            'Data security:\n'
            '• Your password is encrypted and never stored in plain text\n'
            '• Your data is stored securely and only accessible to authorised AidLink administrators\n\n'
            'You may request deletion of your account and data at any time by contacting aidlinkassist@gmail.com.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff164EB0),
                foregroundColor: Colors.white),
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String error,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, color: error.isNotEmpty ? Colors.red : null),
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: error.isNotEmpty ? error : null,
          errorMaxLines: 2,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: error.isNotEmpty
                  ? Colors.red.shade400
                  : Colors.grey.shade400,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: error.isNotEmpty
                  ? Colors.red.shade600
                  : const Color(0xff164EB0),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsWidget() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.assist_walker,
              size: 50, color: Color(0xff164EB0)),
          const SizedBox(height: 10),
          const Text('Create AidLink Account',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Join our social assistance network',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),

          // First Name
          _buildField(
            label: 'First Name *',
            controller: firstNameController,
            icon: Icons.person_outline,
            error: _firstNameError,
            onChanged: (_) => _clearError('firstName'),
          ),
          const SizedBox(height: 12),

          // Last Name
          _buildField(
            label: 'Last Name *',
            controller: lastNameController,
            icon: Icons.person_outline,
            error: _lastNameError,
            onChanged: (_) => _clearError('lastName'),
          ),
          const SizedBox(height: 12),

          // Email
          _buildField(
            label: 'Email *',
            controller: emailController,
            icon: Icons.email_outlined,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _clearError('email'),
          ),
          const SizedBox(height: 12),

          // Phone (optional)
          _buildField(
            label: 'Phone Number (optional)',
            controller: phoneController,
            icon: Icons.phone_outlined,
            error: _phoneError,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _clearError('phone'),
          ),
          const SizedBox(height: 12),

          // Password
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: _obscure,
                  onChanged: (_) {
                    _clearError('password');
                    if (_confirmPassError.isNotEmpty) {
                      setState(() => _confirmPassError = '');
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: _passwordError.isNotEmpty
                            ? Colors.red
                            : null),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _passwordError.isNotEmpty
                        ? _passwordError
                        : null,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _passwordError.isNotEmpty
                            ? Colors.red.shade400
                            : Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _passwordError.isNotEmpty
                            ? Colors.red.shade600
                            : const Color(0xff164EB0),
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _passwordStrength / 5,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation(_strengthColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_strengthLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: _strengthColor,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    'Use 8+ characters with uppercase, numbers & symbols',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Confirm Password
          SizedBox(
            width: 300,
            child: TextField(
              controller: confirmPassController,
              obscureText: _obscureConfirm,
              onChanged: (_) => _clearError('confirmPass'),
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                prefixIcon: Icon(Icons.lock_outline,
                    color: _confirmPassError.isNotEmpty
                        ? Colors.red
                        : null),
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _confirmPassError.isNotEmpty
                    ? _confirmPassError
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _confirmPassError.isNotEmpty
                        ? Colors.red.shade400
                        : Colors.grey.shade400,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _confirmPassError.isNotEmpty
                        ? Colors.red.shade600
                        : const Color(0xff164EB0),
                    width: 2,
                  ),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (confirmPassController.text.isNotEmpty &&
                        passwordController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          confirmPassController.text ==
                                  passwordController.text
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: confirmPassController.text ==
                                  passwordController.text
                              ? Colors.green
                              : Colors.red,
                          size: 18,
                        ),
                      ),
                    IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Terms & Conditions
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: const Color(0xff164EB0),
                        onChanged: (val) => setState(() {
                          _agreedToTerms = val ?? false;
                          if (_agreedToTerms) _termsError = '';
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: Color(0xff164EB0),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTermsDialog,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Color(0xff164EB0),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showPrivacyDialog,
                            ),
                            const TextSpan(
                                text:
                                    '. Your data is used only to match you to disability programs.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_termsError.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_termsError,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Create Account button
          SizedBox(
            width: 300,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff164EB0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_validate()) status.value = 'creating_account';
              },
              child: const Text('Create Account',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 300,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _creatingAccountWidget() {
    return FutureBuilder(
      future: Get.find<AuthController>().createAccount(
        firstName: firstNameController.text.trim(),
        lastName:  lastNameController.text.trim(),
        email:     emailController.text.trim(),
        password:  passwordController.text,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Creating Account...', style: TextStyle(fontSize: 16)),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          );
        }

        if (snapshot.data == 'success') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAll(() => const DashboardPage());
          });
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 56),
                SizedBox(height: 16),
                Text('Account Created!',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'A verification email has been sent to your inbox. Please verify your email to unlock all features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          );
        }

        final rawError = snapshot.data.toString();
        String friendlyError = rawError;
        if (rawError.toLowerCase().contains('already exists')) {
          friendlyError =
              'An account with this email already exists. Try signing in instead.';
        } else if (rawError.toLowerCase().contains('network')) {
          friendlyError =
              'Network error. Please check your connection and try again.';
        } else if (rawError.toLowerCase().contains('password')) {
          friendlyError = 'Password must be at least 8 characters.';
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(friendlyError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 14)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff164EB0),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => status.value = 'enter_details',
                      child: const Text('Try Again'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 680,
        child: Obx(
          () => status.value == 'enter_details'
              ? _detailsWidget()
              : status.value == 'creating_account'
                  ? _creatingAccountWidget()
                  : const SizedBox(),
        ),
      ),
    );
  }
}