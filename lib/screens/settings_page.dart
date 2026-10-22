import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/dialogs/sign_out_dialog.dart';
import 'package:aidlinkapp/screens/forgot_password_page.dart';

// ── Theme controller — persists across sessions ───────────────────────────────
class ThemeController extends GetxController {
  static const _key = 'theme_mode';
  final RxString mode = 'system'.obs; // 'light' | 'dark' | 'system'

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = prefs.getString(_key) ?? 'system';
  }

  Future<void> setMode(String m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, m);
    // Apply theme immediately
    switch (m) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        Get.changeThemeMode(ThemeMode.system);
    }
  }

  ThemeMode get themeMode {
    switch (mode.value) {
      case 'light':  return ThemeMode.light;
      case 'dark':   return ThemeMode.dark;
      default:       return ThemeMode.system;
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final auth = Get.find<AuthController>();
  late ThemeController theme;

  bool _notifyEmail   = true;
  bool _notifyPwd     = true;
  bool _notifyProgram = false;
  bool _voiceNav      = false;
  bool _highContrast  = false;
  bool _largeText     = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController());
    }
    theme = Get.find<ThemeController>();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyEmail   = prefs.getBool('notify_email')   ?? true;
      _notifyPwd     = prefs.getBool('notify_pwd')     ?? true;
      _notifyProgram = prefs.getBool('notify_program') ?? false;
      _voiceNav      = prefs.getBool('voice_nav')      ?? false;
      _highContrast  = prefs.getBool('high_contrast')  ?? false;
      _largeText     = prefs.getBool('large_text')     ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? const Color(0xff111827) : const Color(0xfff8f9fc);
    final card = isDark ? const Color(0xff1f2937) : Colors.white;
    final txt  = isDark ? Colors.white : const Color(0xff111827);
    final sub  = isDark ? const Color(0xffb0b8c8) : const Color(0xff374151);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff0A3080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Profile summary ─────────────────────────────────────────────
          Semantics(
            label: 'Signed in as ${auth.fullName}, ${auth.signedEmail.value}',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff0A3080),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    auth.firstName.value.isNotEmpty
                        ? auth.firstName.value[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(auth.signedEmail.value,
                        style: const TextStyle(
                            color: Color(0xffCBD5E1), fontSize: 12)),
                  ],
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // ── Appearance ──────────────────────────────────────────────────
          _sectionTitle('Appearance', Icons.palette_outlined),
          _card(card, [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App Theme',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: txt)),
                  const SizedBox(height: 4),
                  Text('Choose how AidLink looks on your device',
                      style: TextStyle(fontSize: 12, color: sub)),
                  const SizedBox(height: 14),
                  Obx(() => Row(children: [
                    _themeOption('Light', Icons.wb_sunny_outlined,
                        'light', card, txt),
                    const SizedBox(width: 8),
                    _themeOption('Dark', Icons.nightlight_outlined,
                        'dark', card, txt),
                    const SizedBox(width: 8),
                    _themeOption('System', Icons.phone_android_outlined,
                        'system', card, txt),
                  ])),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Accessibility ───────────────────────────────────────────────
          _sectionTitle('Accessibility', Icons.accessibility_new),
          _card(card, [
            _switch(
              label: 'Voice Navigation',
              sublabel: 'Enable screen reader support and spoken feedback',
              icon: Icons.record_voice_over_outlined,
              value: _voiceNav,
              color: const Color(0xff7c3aed),
              txt: txt, sub: sub,
              onChanged: (v) {
                setState(() => _voiceNav = v);
                _savePref('voice_nav', v);
                Get.snackbar(
                  v ? 'Voice Navigation On' : 'Voice Navigation Off',
                  v
                      ? 'Screen reader labels are now active. Use TalkBack or VoiceOver.'
                      : 'Voice navigation disabled.',
                  backgroundColor: const Color(0xff7c3aed),
                  colorText: Colors.white,
                );
              },
            ),
            _divider(),
            _switch(
              label: 'High Contrast Mode',
              sublabel: 'Increases text and border contrast for low vision users',
              icon: Icons.contrast,
              value: _highContrast,
              color: const Color(0xff0d9488),
              txt: txt, sub: sub,
              onChanged: (v) {
                setState(() => _highContrast = v);
                _savePref('high_contrast', v);
              },
            ),
            _divider(),
            _switch(
              label: 'Larger Text',
              sublabel: 'Increases font size across the app',
              icon: Icons.text_fields,
              value: _largeText,
              color: const Color(0xff1A56C4),
              txt: txt, sub: sub,
              onChanged: (v) {
                setState(() => _largeText = v);
                _savePref('large_text', v);
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── Notifications ───────────────────────────────────────────────
          _sectionTitle('Notifications', Icons.notifications_outlined),
          _card(card, [
            _switch(
              label: 'Email Verification Reminders',
              sublabel: 'Remind me to verify my email address',
              icon: Icons.email_outlined,
              value: _notifyEmail,
              color: const Color(0xff1A56C4),
              txt: txt, sub: sub,
              onChanged: (v) {
                setState(() => _notifyEmail = v);
                _savePref('notify_email', v);
              },
            ),
            _divider(),
            _switch(
              label: 'PWD Card Status Updates',
              sublabel: 'Notify me when my card is verified or rejected',
              icon: Icons.credit_card_outlined,
              value: _notifyPwd,
              color: const Color(0xff0d9488),
              txt: txt, sub: sub,
              onChanged: (v) {
                setState(() => _notifyPwd = v);
                _savePref('notify_pwd', v);
              },
            ),
            _divider(),
            _switch(
              label: 'New Program Alerts',
              sublabel: 'Notify me when new programs are added',
              icon: Icons.campaign_outlined,
              value: _notifyProgram,
              color: const Color(0xff7c3aed),
              txt: txt, sub: sub,
              onChanged: (v) {
                setState(() => _notifyProgram = v);
                _savePref('notify_program', v);
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── Account ─────────────────────────────────────────────────────
          _sectionTitle('Account', Icons.manage_accounts_outlined),
          _card(card, [
            _tile(
              label: 'Change Password',
              sublabel: 'Send a password reset link to your email',
              icon: Icons.lock_reset_outlined,
              color: const Color(0xff1A56C4),
              txt: txt, sub: sub,
              onTap: () => Get.to(() => const ForgotPasswordPage()),
            ),
            _divider(),
            _tile(
              label: 'Saved Login Info',
              sublabel: 'Clear your remembered email and password',
              icon: Icons.password_outlined,
              color: const Color(0xff0d9488),
              txt: txt, sub: sub,
              onTap: () => _showClearDialog(context),
            ),
            _divider(),
            _tile(
              label: 'Privacy Policy',
              sublabel: 'How AidLink uses and protects your data',
              icon: Icons.privacy_tip_outlined,
              color: const Color(0xff374151),
              txt: txt, sub: sub,
              onTap: () => _showPolicy(context),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Sign Out ────────────────────────────────────────────────────
          Semantics(
            button: true,
            label: 'Sign out of AidLink',
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SignOutDialog(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text('AidLink v1.0.0 · University of Nairobi',
                style: TextStyle(fontSize: 11, color: sub)),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _themeOption(String label, IconData icon, String value,
      Color card, Color txt) {
    final selected = theme.mode.value == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label theme${selected ? ', currently selected' : ''}',
        child: GestureDetector(
          onTap: () => theme.setMode(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xff0A3080) : card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xff0A3080)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(children: [
              Icon(icon,
                  size: 22,
                  color: selected ? Colors.white : Colors.grey),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: const Color(0xff6b7280)),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xff6b7280),
                letterSpacing: 0.8)),
      ]),
    );
  }

  Widget _card(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.withValues(alpha: 0.15));

  Widget _switch({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool value,
    required Color color,
    required Color txt,
    required Color sub,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      label: '$label. $sublabel. Currently ${value ? 'on' : 'off'}.',
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: txt)),
        subtitle: Text(sublabel,
            style: TextStyle(fontSize: 11, color: sub)),
        value: value,
        activeThumbColor: color,
        onChanged: onChanged,
      ),
    );
  }

  Widget _tile({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required Color txt,
    required Color sub,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label. $sublabel',
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: txt)),
        subtitle: Text(sublabel,
            style: TextStyle(fontSize: 11, color: sub)),
        trailing: Icon(Icons.chevron_right,
            color: Colors.grey.withValues(alpha: 0.5)),
        onTap: onTap,
        minVerticalPadding: 12,
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Saved Login Info'),
        content: const Text(
          'Your email and password are currently saved for quick sign-in.\n\n'
          'Would you like to clear this saved information?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_email');
              await prefs.remove('saved_password');
              await prefs.setBool('remember_me', false);
              if (context.mounted) Navigator.pop(context);
              Get.snackbar('Cleared',
                  'Saved login info has been removed.',
                  backgroundColor: Colors.green,
                  colorText: Colors.white);
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'AidLink collects personal information including your name, email, '
            'disability type, income, and location to match you to relevant '
            'government support programs in Kenya.\n\n'
            'Your data is stored securely and is never sold to third parties. '
            'Only authorised AidLink administrators can view your profile for '
            'the purpose of verifying your PWD card.\n\n'
            'You may request deletion of your account and data at any time '
            'by contacting AidLink support.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A3080)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}