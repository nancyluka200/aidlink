import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:get/get.dart';
import 'package:aidlinkapp/screens/complete_profile_page.dart';

class MemoPage extends StatelessWidget {
  const MemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth    = Get.find<AuthController>();
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff111827) : const Color(0xfff5f7fc);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff164EB0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: 'Read my profile aloud using screen reader',
            child: SizedBox(
              width: 44, height: 44,
              child: IconButton(
                icon: const Icon(Icons.record_voice_over_outlined),
                tooltip: 'Read profile aloud',
                onPressed: () {
                  final summary = auth.profileCompleted.value
                      ? 'Profile for ${auth.fullName}. '
                        'Age ${auth.age.value} years. '
                        'Located in ${auth.location.value}. '
                        'Disability type: ${auth.disabilityType.value}. '
                        'Employment: ${auth.employmentStatus.value}. '
                        'PWD card verification status: ${auth.pwdCardVerificationStatus.value}.'
                      : 'Your profile is incomplete. Please complete your profile to get matched to programs.';
                  SemanticsService.announce(summary, TextDirection.ltr);
                  Get.snackbar(
                    '🔊 Reading Profile',
                    'Profile is being read aloud by your screen reader.',
                    backgroundColor: const Color(0xff0A3080),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Open settings',
            child: SizedBox(
              width: 44, height: 44,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Get.to(() => const SettingsPage()),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => auth.profileCompleted.value
            ? _buildProfileView(context, auth)
            : _buildIncompleteView(context)),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, AuthController auth) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bodyColor  = isDark ? const Color(0xffcbd5e1) : const Color(0xff374151);
    final labelColor = isDark ? const Color(0xff94a3b8) : const Color(0xff6b7280);
    final valueColor = isDark ? Colors.white             : Colors.black87;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile header ───────────────────────────────────────────────
          Semantics(
            label: 'Profile for ${auth.fullName}. Email: ${auth.signedEmail.value}.',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff164EB0), Color(0xff0A3080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    auth.firstName.value.isNotEmpty
                        ? auth.firstName.value[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(auth.signedEmail.value,
                          style: const TextStyle(
                              color: Color(0xffCBD5E1), fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── PWD Card Verification Status Banner ──────────────────────────
          Obx(() {
            if (!auth.pwdCardStatus.value) return const SizedBox.shrink();
            final status = auth.pwdCardVerificationStatus.value;
            if (status == 'verified') {
              return _statusBanner(
                context: context,
                icon: Icons.verified_outlined,
                title: 'NCPWD Card Verified',
                message: 'Your National Council for Persons with Disabilities (NCPWD) card has been verified. You now have access to all PWD-eligible programs.',
                color: Colors.green,
              );
            } else if (status == 'pending') {
              return _statusBanner(
                context: context,
                icon: Icons.pending_outlined,
                title: 'NCPWD Card Under Review',
                message: 'Your card is being reviewed by the AidLink team. This usually takes 1–2 business days.',
                color: Colors.orange,
              );
            } else if (status == 'rejected') {
              return _statusBanner(
                context: context,
                icon: Icons.credit_card_off_outlined,
                title: 'NCPWD Card Rejected',
                message: auth.pwdCardRejectionReason.value.isNotEmpty
                    ? auth.pwdCardRejectionReason.value
                    : 'Your card could not be verified. Please re-upload a valid card.',
                color: Colors.red,
                actionLabel: 'Update Card',
                onAction: () => Get.to(() => const CompleteProfilePage()),
              );
            } else {
              return _statusBanner(
                context: context,
                icon: Icons.upload_outlined,
                title: 'NCPWD Card Not Yet Submitted',
                message: 'You indicated you have a card. Please complete your profile to submit it for verification.',
                color: Colors.grey,
                actionLabel: 'Submit Now',
                onAction: () => Get.to(() => const CompleteProfilePage()),
              );
            }
          }),

          const SizedBox(height: 16),

          // ── Applicant Type ───────────────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.people_outline,
            title: 'Application Type',
            color: Colors.orange,
            semanticLabel: 'Application type information',
            children: [
              _infoRow(auth.applicantType.value.isNotEmpty ? auth.applicantType.value : '—',
                  'Applicant', labelColor, valueColor),
              if (auth.isCaretakerApplication) ...[
                _infoRow(auth.caretakerName.value, 'Caretaker Name', labelColor, valueColor),
                _infoRow(auth.caretakerRelationship.value, 'Relationship', labelColor, valueColor),
                _infoRow(auth.caretakerPhone.value, 'Caretaker Phone', labelColor, valueColor),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Personal Info ────────────────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.person_outline,
            title: 'Personal Information',
            color: const Color(0xff164EB0),
            semanticLabel: 'Personal information',
            children: [
              _infoRow(auth.fullName, 'Full Name', labelColor, valueColor),
              _infoRow('${auth.age.value} years', 'Age', labelColor, valueColor),
              _infoRow(auth.location.value, 'Location', labelColor, valueColor),
              _infoRow(auth.citizenshipStatus.value, 'Citizenship', labelColor, valueColor),
              _infoRow('${auth.householdSize.value} members', 'Household Size', labelColor, valueColor),
            ],
          ),
          const SizedBox(height: 12),

          // ── Disability Info ──────────────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.accessible_outlined,
            title: 'Disability Information',
            color: Colors.teal,
            semanticLabel: 'Disability information',
            children: [
              _infoRow(auth.disabilityType.value, 'Disability Type', labelColor, valueColor),
              _infoRow(auth.disabilityStatus.value ? 'Yes' : 'No',
                  'Registered with NCPWD', labelColor, valueColor),
              _infoRow(auth.pwdCardStatus.value ? 'Yes ✓' : 'No',
                  'Has NCPWD Card', labelColor, valueColor),
              if (auth.pwdCardStatus.value && auth.pwdCardNumber.value.isNotEmpty)
                _infoRow(auth.pwdCardNumber.value, 'Card Number', labelColor, valueColor),
              if (auth.pwdCardStatus.value)
                _infoRowWidget(
                  'Verification Status',
                  _pwdStatusPill(auth.pwdCardVerificationStatus.value),
                  labelColor,
                ),
              if (auth.disabilities.isNotEmpty)
                _infoRow(auth.disabilities.join(', '), 'Other Disabilities', labelColor, valueColor),
            ],
          ),
          const SizedBox(height: 12),

          // ── Financial & Employment ───────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.work_outline,
            title: 'Financial & Employment',
            color: Colors.green,
            semanticLabel: 'Financial and employment information',
            children: [
              _infoRow(auth.employmentStatus.value, 'Employment Status', labelColor, valueColor),
              _infoRow('KES ${auth.income.value}', 'Monthly Income', labelColor, valueColor),
              _infoRow(auth.educationLevel.value, 'Education Level', labelColor, valueColor),
              _infoRow(auth.isStudent.value ? 'Yes' : 'No',
                  'Currently a Student', labelColor, valueColor),
            ],
          ),
          const SizedBox(height: 20),

          // ── Edit Profile button ──────────────────────────────────────────
          Semantics(
            button: true,
            label: 'Edit your profile information',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff164EB0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Get.to(() => const CompleteProfilePage()),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Settings shortcut ────────────────────────────────────────────
          Semantics(
            button: true,
            label: 'Open app settings including theme and accessibility',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Settings',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white70
                      : const Color(0xff164EB0),
                  side: BorderSide(
                      color: isDark
                          ? Colors.white38
                          : const Color(0xff164EB0)),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Get.to(() => const SettingsPage()),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Status Banner ── now theme-aware ─────────────────────────────────────
  Widget _statusBanner({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? const Color(0xff1f2937) : Colors.white;
    final msgColor = isDark ? const Color(0xffcbd5e1) : const Color(0xff374151);

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(message,
                      style: TextStyle(
                          color: msgColor,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: actionLabel,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(actionLabel,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pwdStatusPill(String status) {
    Color color; String label; IconData icon;
    switch (status) {
      case 'verified':
        color = Colors.green; label = 'Verified ✓'; icon = Icons.check_circle_outline; break;
      case 'pending':
        color = Colors.orange; label = 'Pending Review'; icon = Icons.pending_outlined; break;
      case 'rejected':
        color = Colors.red; label = 'Rejected'; icon = Icons.cancel_outlined; break;
      default:
        color = Colors.grey; label = 'Unverified'; icon = Icons.help_outline;
    }
    return Semantics(
      label: 'Card status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildIncompleteView(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white            : Colors.black87;
    final subColor   = isDark ? const Color(0xff94a3b8) : Colors.grey[600]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xff164EB0).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_outlined,
                size: 56, color: Color(0xff164EB0)),
          ),
          const SizedBox(height: 20),
          Text('Profile Incomplete',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor)),
          const SizedBox(height: 8),
          Text(
            'Complete your profile so AidLink can match you\nto the right programs.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subColor),
          ),
          const SizedBox(height: 28),
          Semantics(
            button: true,
            label: 'Complete my profile',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Complete My Profile',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff164EB0),
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Get.to(() => const CompleteProfilePage()),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: 'Open settings',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? Colors.white70
                    : const Color(0xff164EB0),
                side: BorderSide(
                    color: isDark
                        ? Colors.white38
                        : const Color(0xff164EB0)),
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Get.to(() => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Card ── theme-aware ───────────────────────────────────────────
  Widget _sectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required String semanticLabel,
    required List<Widget> children,
  }) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final cardBg   = isDark ? const Color(0xff1f2937) : Colors.white;
    final borderColor = isDark
        ? const Color(0xff374151)
        : Colors.grey.shade200;

    return Semantics(
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
              ),
              child: Row(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String value, String label, Color labelColor, Color valueColor) {
    return Semantics(
      label: '$label: ${value.isNotEmpty ? value : "not set"}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: TextStyle(color: labelColor, fontSize: 13)),
            ),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : '—',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: valueColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRowWidget(String label, Widget valueWidget, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: TextStyle(color: labelColor, fontSize: 13)),
          ),
          valueWidget,
        ],
      ),
    );
  }
}