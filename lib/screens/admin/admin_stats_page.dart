import 'dart:convert';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  final auth = Get.find<AuthController>();
  bool _loading = true;
  String? _errorMessage;

  int totalUsers = 0;
  int profilesCompleted = 0;
  int totalApplications = 0;
  int approvedApplications = 0;
  int pendingApplications = 0;
  int underReviewApplications = 0;
  int rejectedApplications = 0;
  int usersWithPwdCard = 0;
  int usersRegisteredNCPWD = 0;
  int selfApplicants = 0;
  int caretakerApplicants = 0;
  int pwdPending = 0;
  int pwdVerified = 0;
  int pwdRejected = 0;

  Map<String, int> disabilityBreakdown = {};
  Map<String, int> countyBreakdown = {};
  Map<String, int> programCounts = {};

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
          totalUsers              = data['totalUsers']              ?? 0;
          profilesCompleted       = data['profilesCompleted']       ?? 0;
          totalApplications       = data['totalApplications']       ?? 0;
          approvedApplications    = data['approvedApplications']    ?? 0;
          pendingApplications     = data['pendingApplications']     ?? 0;
          underReviewApplications = data['underReviewApplications'] ?? 0;
          rejectedApplications    = data['rejectedApplications']    ?? 0;
          usersWithPwdCard        = data['usersWithPwdCard']        ?? 0;
          usersRegisteredNCPWD    = data['ncpwdRegistered']         ?? 0;
          selfApplicants          = data['selfApplicants']          ?? 0;
          caretakerApplicants     = data['caretakerApplicants']     ?? 0;
          pwdPending              = data['pwdPending']              ?? 0;
          pwdVerified             = data['pwdVerified']             ?? 0;
          pwdRejected             = data['pwdRejected']             ?? 0;

          if (data['disabilityBreakdown'] != null) {
            disabilityBreakdown =
                Map<String, int>.from(data['disabilityBreakdown']);
          }
          if (data['countyBreakdown'] != null) {
            countyBreakdown =
                Map<String, int>.from(data['countyBreakdown']);
          }
          if (data['programCounts'] != null) {
            programCounts =
                Map<String, int>.from(data['programCounts']);
          }
        });
      } else {
        setState(() => _errorMessage =
            'Could not load statistics (${res.statusCode})');
      }
    } catch (e) {
      setState(() =>
          _errorMessage = 'Network error. Check your connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileRate = totalUsers > 0
        ? ((profilesCompleted / totalUsers) * 100).toStringAsFixed(0)
        : '0';
    final approvalRate = totalApplications > 0
        ? ((approvedApplications / totalApplications) * 100)
            .toStringAsFixed(0)
        : '0';

    final sortedDisability = disabilityBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedCounty = countyBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedPrograms = programCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Usage Statistics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff0A3080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: _buildContent(
                    profileRate: profileRate,
                    approvalRate: approvalRate,
                    sortedDisability: sortedDisability,
                    sortedCounty: sortedCounty,
                    sortedPrograms: sortedPrograms,
                  ),
                ),
    );
  }

  // ── Loading Skeleton ───────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skeletonLabel(),
        const SizedBox(height: 10),
        Row(children: [
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
        ]),
        const SizedBox(height: 24),
        _skeletonLabel(),
        const SizedBox(height: 10),
        Row(children: [
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
        ]),
        const SizedBox(height: 24),
        _skeletonLabel(),
        const SizedBox(height: 10),
        ...[1, 2, 3, 4].map((_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _skeletonBar(),
            )),
        const SizedBox(height: 24),
        _skeletonLabel(),
        const SizedBox(height: 10),
        Row(children: [
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
          const SizedBox(width: 10),
          _skeletonCard(),
        ]),
      ],
    );
  }

  Widget _skeletonLabel() {
    return _shimmer(
      child: Container(
        height: 16,
        width: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _skeletonCard() {
    return Expanded(
      child: _shimmer(
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _skeletonBar() {
    return _shimmer(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _shimmer({required Widget child}) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.grey.shade300,
          Colors.grey.shade100,
          Colors.grey.shade300,
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: child,
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(_errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStats,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A3080),
                foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent({
    required String profileRate,
    required String approvalRate,
    required List<MapEntry<String, int>> sortedDisability,
    required List<MapEntry<String, int>> sortedCounty,
    required List<MapEntry<String, int>> sortedPrograms,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overview ───────────────────────────────────────────────────────
        _sectionTitle('System Overview'),
        const SizedBox(height: 10),
        Row(children: [
          _statCard('$totalUsers', 'Total Users',
              Icons.people_outline, Colors.blue),
          const SizedBox(width: 10),
          _statCard('$profilesCompleted', 'Profiles Done',
              Icons.check_circle_outline, Colors.green),
          const SizedBox(width: 10),
          _statCard('$totalApplications', 'Applications',
              Icons.assignment_outlined, Colors.purple),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard('$profileRate%', 'Profile Rate',
              Icons.trending_up, Colors.teal),
          const SizedBox(width: 10),
          _statCard('$approvalRate%', 'Approval Rate',
              Icons.thumb_up_outlined, Colors.orange),
          const SizedBox(width: 10),
          _statCard('$usersWithPwdCard', 'Have PWD Card',
              Icons.credit_card_outlined, const Color(0xff164EB0)),
        ]),
        const SizedBox(height: 20),

        // ── PWD Card Verification ──────────────────────────────────────────
        _sectionTitle('PWD Card Verification Status'),
        const SizedBox(height: 10),
        Row(children: [
          _statCard('$pwdPending', 'Pending\nReview',
              Icons.pending_outlined, Colors.orange),
          const SizedBox(width: 10),
          _statCard('$pwdVerified', 'Verified',
              Icons.verified_outlined, Colors.green),
          const SizedBox(width: 10),
          _statCard('$pwdRejected', 'Rejected',
              Icons.cancel_outlined, Colors.red),
        ]),
        const SizedBox(height: 20),

        // ── Application Status ─────────────────────────────────────────────
        _sectionTitle('Application Status Breakdown'),
        const SizedBox(height: 10),
        _statusBar(
            label: 'Approved',
            value: approvedApplications,
            total: totalApplications,
            color: Colors.green,
            icon: Icons.check_circle_outline),
        _statusBar(
            label: 'Under Review',
            value: underReviewApplications,
            total: totalApplications,
            color: Colors.orange,
            icon: Icons.hourglass_top),
        _statusBar(
            label: 'Pending',
            value: pendingApplications,
            total: totalApplications,
            color: const Color(0xff164EB0),
            icon: Icons.schedule),
        _statusBar(
            label: 'Rejected',
            value: rejectedApplications,
            total: totalApplications,
            color: Colors.red,
            icon: Icons.cancel_outlined),
        const SizedBox(height: 20),

        // ── Applicant Type ─────────────────────────────────────────────────
        _sectionTitle('Applicant Type'),
        const SizedBox(height: 10),
        Row(children: [
          _statCard('$selfApplicants', 'Self\nApplicants',
              Icons.person_outline, Colors.teal),
          const SizedBox(width: 10),
          _statCard('$caretakerApplicants', 'Caretaker\nApplicants',
              Icons.people_outline, Colors.purple),
          const SizedBox(width: 10),
          _statCard('$usersRegisteredNCPWD', 'NCPWD\nRegistered',
              Icons.verified_outlined, Colors.green),
        ]),
        const SizedBox(height: 20),

        // ── Most Applied Programs ──────────────────────────────────────────
        if (sortedPrograms.isNotEmpty) ...[
          _sectionTitle('Most Applied Programs'),
          const SizedBox(height: 10),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: sortedPrograms.take(9).map((e) {
                final friendlyNames = {
                  'ncpwd_cash_transfer':    'NCPWD Cash Transfer',
                  'ncpwd_assistive_devices':'NCPWD Assistive Devices',
                  'ncpwd_education':        'NCPWD Education Bursary',
                  'nsnp_pwsd_ct':           'PWSD Cash Transfer',
                  'nfdk_tools':             'NFDK Tools of Trade',
                  'ncpwd_employment':       'NCPWD Employment',
                  'ncpwd_legal':            'NCPWD Legal Services',
                  'county_bursary':         'County Bursary',
                  'nhif_disability':        'SHA Enhanced Benefits',
                };
                final name = friendlyNames[e.key] ?? e.key;
                final pct  = totalApplications > 0
                    ? e.value / totalApplications
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Text('${e.value}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff164EB0))),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xff164EB0)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Disability Breakdown ───────────────────────────────────────────
        if (sortedDisability.isNotEmpty) ...[
          _sectionTitle('Users by Disability Type'),
          const SizedBox(height: 10),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: sortedDisability.map((e) {
                final pct = profilesCompleted > 0
                    ? e.value / profilesCompleted
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(e.key,
                            style: const TextStyle(fontSize: 13))),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                              Colors.teal.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── County Breakdown ───────────────────────────────────────────────
        if (sortedCounty.isNotEmpty) ...[
          _sectionTitle('Top Counties by Users'),
          const SizedBox(height: 10),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: sortedCounty.take(10).map((e) {
                final pct =
                    totalUsers > 0 ? e.value / totalUsers : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(e.key,
                            style: const TextStyle(fontSize: 13))),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                              Colors.orange.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _statusBar({
    required String label,
    required int value,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final pct    = total > 0 ? value / total : 0.0;
    final pctStr = '${(pct * 100).toStringAsFixed(0)}%';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('$value  ($pctStr)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}