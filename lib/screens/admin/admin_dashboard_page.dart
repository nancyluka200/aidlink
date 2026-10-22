import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/screens/admin/admin_programs_page.dart';
import 'package:aidlinkapp/screens/admin/admin_users_page.dart';
import 'package:aidlinkapp/screens/admin/admin_stats_page.dart';
import 'package:aidlinkapp/screens/admin/admin_pwd_verification_page.dart';
import 'package:aidlinkapp/dialogs/sign_out_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aidlinkapp/utilities/base_url.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final auth = Get.find<AuthController>();
  bool _loading = true;
  String? _errorMessage;

  // Stats from backend
  int totalUsers          = 0;
  int profilesCompleted   = 0;
  int totalPrograms       = 0;
  int pwdVerified         = 0;
  int pwdPending          = 0;
  int pwdRejected         = 0;
  int selfApplicants      = 0;
  int caretakerApplicants = 0;
  int ncpwdRegistered     = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading      = true;
      _errorMessage = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/stats'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          totalUsers          = data['totalUsers']          ?? 0;
          profilesCompleted   = data['profilesCompleted']   ?? 0;
          totalPrograms       = data['totalPrograms']        ?? 0;
          pwdVerified         = data['pwdVerified']          ?? 0;
          pwdPending          = data['pwdPending']           ?? 0;
          pwdRejected         = data['pwdRejected']          ?? 0;
          selfApplicants      = data['selfApplicants']       ?? 0;
          caretakerApplicants = data['caretakerApplicants']  ?? 0;
          ncpwdRegistered     = data['ncpwdRegistered']      ?? 0;
        });
      } else {
        setState(() => _errorMessage =
            'Could not load stats (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error. Check your connection.');
      debugPrint('Error loading admin stats: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Add Program Dialog ─────────────────────────────────────────────────────
  void _showAddProgramDialog() {
    final nameController       = TextEditingController();
    final orgController        = TextEditingController();
    final descController       = TextEditingController();
    final websiteController    = TextEditingController();
    final contactController    = TextEditingController();
    final howToApplyController = TextEditingController();
    final deadlineController   = TextEditingController();
    String selectedCategory    = 'Cash Transfer';
    bool hasOnline             = true;
    final docsController       = TextEditingController();
    final locationsController  = TextEditingController();

    final categories = [
      'Cash Transfer', 'Assistive Devices', 'Education',
      'Healthcare', 'Employment', 'Legal',
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xff0A3080),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Add New Program',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ),

                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _formField('Program Name *', nameController,
                            hint: 'e.g. NCPWD Cash Transfer Program'),
                        const SizedBox(height: 12),
                        _formField('Organization / Provider *', orgController,
                            hint: 'e.g. National Council for Persons with Disabilities'),
                        const SizedBox(height: 12),
                        const Text('Category *',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), isDense: true),
                          items: categories
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedCategory = v!),
                        ),
                        const SizedBox(height: 12),
                        _formField('Description *', descController,
                            hint: 'Brief description of what this program provides',
                            maxLines: 3),
                        const SizedBox(height: 12),
                        _formField('Official Website URL', websiteController,
                            hint: 'https://ncpwd.go.ke'),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Expanded(
                            child: Text('Has Online Application?',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Switch(
                            value: hasOnline,
                            activeThumbColor: const Color(0xff164EB0),
                            onChanged: (v) =>
                                setDialogState(() => hasOnline = v),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _formField('Required Documents *', docsController,
                            hint:
                                'Enter each document on a new line:\nNational ID\nPWD Card',
                            maxLines: 5),
                        const SizedBox(height: 4),
                        Text('One document per line',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 12),
                        _formField('Physical Locations *', locationsController,
                            hint:
                                'Enter each location on a new line:\nNCPWD Headquarters — Waiyaki Way, Nairobi',
                            maxLines: 4),
                        const SizedBox(height: 4),
                        Text('One location per line',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 12),
                        _formField('How to Apply *', howToApplyController,
                            hint: 'Step-by-step application instructions',
                            maxLines: 3),
                        const SizedBox(height: 12),
                        _formField('Deadline', deadlineController,
                            hint:
                                'e.g. Applications accepted throughout the year'),
                        const SizedBox(height: 12),
                        _formField('Contact Information', contactController,
                            hint:
                                'e.g. Tel: +254 20 3554248 | Email: info@ncpwd.go.ke'),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    border:
                        Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0A3080),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Save Program'),
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              orgController.text.isEmpty ||
                              descController.text.isEmpty ||
                              docsController.text.isEmpty ||
                              locationsController.text.isEmpty ||
                              howToApplyController.text.isEmpty) {
                            Get.snackbar('Missing Fields',
                                'Please fill in all required fields marked with *',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white);
                            return;
                          }

                          final docs = docsController.text
                              .split('\n')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final locations = locationsController.text
                              .split('\n')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final newProgram = {
                            'name':                 nameController.text.trim(),
                            'organization':         orgController.text.trim(),
                            'category':             selectedCategory,
                            'description':          descController.text.trim(),
                            'website':              websiteController.text.trim(),
                            'hasOnlineApplication': hasOnline,
                            'requiredDocuments':    docs,
                            'physicalLocations':    locations,
                            'howToApply':           howToApplyController.text.trim(),
                            'deadline': deadlineController.text.trim().isNotEmpty
                                ? deadlineController.text.trim()
                                : 'Check official website for dates',
                            'contact': contactController.text.trim(),
                            'isActive': true,
                          };

                          try {
                            final res = await http.post(
                              Uri.parse('$baseUrl/api/admin/programs'),
                              headers: {
                                'x-auth-token': auth.token.value,
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode(newProgram),
                            );

                            Get.back();
                            if (res.statusCode == 201 ||
                                res.statusCode == 200) {
                              setState(() => totalPrograms++);
                              Get.snackbar('Program Added ✓',
                                  '${newProgram['name']} has been added.',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3));
                            } else {
                              Get.snackbar('Error',
                                  'Failed to save program. Try again.',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white);
                            }
                          } catch (e) {
                            Get.back();
                            Get.snackbar('Error',
                                'Network error. Could not save program.',
                                backgroundColor: Colors.red,
                                colorText: Colors.white);
                          }
                        },
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController controller,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(fontSize: 12, color: Colors.grey[400]),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileRate = totalUsers > 0
        ? ((profilesCompleted / totalUsers) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xfff0f2f8),
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Aid',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          const Text('Link Admin',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
        ]),
        backgroundColor: const Color(0xff0A3080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
                context: context,
                builder: (_) => const SignOutDialog()),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProgramDialog,
        backgroundColor: const Color(0xff164EB0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Program',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Error banner ───────────────────────────────────────
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: _loadStats,
                          child: const Text('Retry'),
                        ),
                      ]),
                    ),

                  // ── Hero header ────────────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff0A3080), Color(0xff164EB0)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Hello, ${auth.fullName.split(' ').first}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const Text('Admin Panel — AidLink',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 22),
                        Row(children: [
                          _heroStat('$totalUsers', 'Total\nUsers',
                              Icons.people_outline, Colors.white),
                          const SizedBox(width: 10),
                          _heroStat(
                              '$profilesCompleted',
                              'Profiles\nComplete',
                              Icons.check_circle_outline,
                              Colors.greenAccent),
                          const SizedBox(width: 10),
                          _heroStat('$pwdPending', 'PWD\nPending',
                              Icons.pending_outlined, Colors.amber),
                        ]),
                        const SizedBox(height: 16),

                        // Profile completion bar
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Text('Profile Completion Rate',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                                const Spacer(),
                                Text('$profileRate%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ]),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: profileRate / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      AlwaysStoppedAnimation(
                                    profileRate >= 70
                                        ? Colors.greenAccent
                                        : profileRate >= 40
                                            ? Colors.amber
                                            : Colors.redAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$profilesCompleted of $totalUsers users have completed their profile',
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Applicant type breakdown ───────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Applicant Type',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        Row(children: [
                          _applicantTypeCard(
                            '$selfApplicants',
                            'Self\nApplicants',
                            Icons.person_outline,
                            Colors.teal,
                          ),
                          const SizedBox(width: 10),
                          _applicantTypeCard(
                            '$caretakerApplicants',
                            'Caretaker\nApplicants',
                            Icons.people_outline,
                            Colors.purple,
                          ),
                          const SizedBox(width: 10),
                          _applicantTypeCard(
                            '$ncpwdRegistered',
                            'NCPWD\nRegistered',
                            Icons.verified_outlined,
                            Colors.green,
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── PWD Card stats ─────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PWD Card Verification',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        Row(children: [
                          _miniStatCard('$pwdVerified', 'Verified',
                              Icons.check_circle_outline,
                              Colors.green),
                          const SizedBox(width: 10),
                          _miniStatCard('$pwdPending', 'Pending',
                              Icons.pending_outlined, Colors.orange),
                          const SizedBox(width: 10),
                          _miniStatCard('$pwdRejected', 'Rejected',
                              Icons.cancel_outlined, Colors.red),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Management tiles ───────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Management Tools',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      _menuTile(
                        icon: Icons.verified_user_outlined,
                        color: Colors.orange,
                        title: 'PWD Verification',
                        subtitle:
                            'Review and verify pending PWD card submissions',
                        badge: '$pwdPending pending',
                        badgeColor: Colors.orange,
                        onTap: () => Get.to(
                            () => const AdminPwdVerificationPage()),
                      ),
                      const SizedBox(height: 10),
                      _menuTile(
                        icon: Icons.list_alt,
                        color: const Color(0xff164EB0),
                        title: 'Manage Programs',
                        subtitle:
                            'View all $totalPrograms disability programs',
                        badge: '$totalPrograms programs',
                        badgeColor: const Color(0xff164EB0),
                        onTap: () =>
                            Get.to(() => const AdminProgramsPage()),
                      ),
                      const SizedBox(height: 10),
                      _menuTile(
                        icon: Icons.people,
                        color: Colors.teal,
                        title: 'View & Search Users',
                        subtitle:
                            'Browse registered users and application status',
                        badge: '$totalUsers users',
                        badgeColor: Colors.teal,
                        onTap: () =>
                            Get.to(() => const AdminUsersPage()),
                      ),
                      const SizedBox(height: 10),
                      _menuTile(
                        icon: Icons.bar_chart,
                        color: Colors.deepPurple,
                        title: 'Usage Statistics',
                        subtitle:
                            'Monitor trends, disability types, county breakdown',
                        badge: 'Live data',
                        badgeColor: Colors.deepPurple,
                        onTap: () =>
                            Get.to(() => const AdminStatsPage()),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _heroStat(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _miniStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _applicantTypeCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge,
                          style: TextStyle(
                              fontSize: 10,
                              color: badgeColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ]),
          ),
          Icon(Icons.arrow_forward_ios,
              color: Colors.grey[400], size: 14),
        ]),
      ),
    );
  }
}