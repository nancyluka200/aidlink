import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class SavedProgramsPage extends StatefulWidget {
  const SavedProgramsPage({super.key});

  @override
  State<SavedProgramsPage> createState() => _SavedProgramsPageState();
}

class _SavedProgramsPageState extends State<SavedProgramsPage>
    with SingleTickerProviderStateMixin {
  final auth = Get.find<AuthController>();
  late TabController _tabController;
  List<dynamic> savedPrograms = [];
  List<dynamic> applications  = [];
  bool _loading = true;

  static const Map<String, String> _programNames = {
    'ncpwd_cash_transfer':     'NCPWD Cash Transfer Program',
    'ncpwd_assistive_devices': 'NCPWD Assistive Devices Program',
    'ncpwd_education':         'NCPWD Education Bursary & Scholarships',
    'nsnp_pwsd_ct':            'Persons with Severe Disabilities Cash Transfer (PWSD-CT)',
    'nfdk_tools':              'NFDK Tools of Trade & Assistive Devices',
    'ncpwd_employment':        'NCPWD Employment & Vocational Training',
    'ncpwd_legal':             'NCPWD Legal Advisory Services',
    'county_bursary':          'County Government Disability Bursary',
    'nhif_disability':         'SHA Enhanced Benefits for PWDs',
  };

  static const Map<String, String> _programCategories = {
    'ncpwd_cash_transfer':     'Cash Transfer',
    'ncpwd_assistive_devices': 'Assistive Devices',
    'ncpwd_education':         'Education',
    'nsnp_pwsd_ct':            'Cash Transfer',
    'nfdk_tools':              'Assistive Devices',
    'ncpwd_employment':        'Employment',
    'ncpwd_legal':             'Legal',
    'county_bursary':          'Education',
    'nhif_disability':         'Healthcare',
  };

  static const Map<String, String> _programWebsites = {
    'ncpwd_cash_transfer':     'https://ncpwd.ecitizen.go.ke',
    'ncpwd_assistive_devices': 'https://ncpwd.go.ke/ndfpwd-application-forms/',
    'ncpwd_education':         'https://ncpwd.go.ke/ndfpwd-application-forms/',
    'nsnp_pwsd_ct':            'https://www.labour.go.ke',
    'nfdk_tools':              'https://nfdk.or.ke',
    'ncpwd_employment':        'https://placement.ncpwd.go.ke/public/',
    'ncpwd_legal':             'https://ncpwd.go.ke',
    'county_bursary':          '',
    'nhif_disability':         'https://www.sha.go.ke',
  };

  String _resolveName(dynamic programId, dynamic programName) {
    final name = programName?.toString() ?? '';
    if (name.isNotEmpty && !name.contains('_')) return name;
    final id = programId?.toString() ?? '';
    return _programNames[id] ?? (name.isNotEmpty ? name : id);
  }

  String _resolveCategory(dynamic programId) =>
      _programCategories[programId?.toString() ?? ''] ?? '';

  String _resolveWebsite(dynamic programId) =>
      _programWebsites[programId?.toString() ?? ''] ?? '';

  Color _categoryColor(String category) {
    switch (category) {
      case 'Cash Transfer':     return Colors.green;
      case 'Assistive Devices': return Colors.blue;
      case 'Education':         return Colors.purple;
      case 'Healthcare':        return Colors.red;
      case 'Employment':        return Colors.teal;
      case 'Legal':             return Colors.orange;
      default:                  return const Color(0xff164EB0);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Cash Transfer':     return Icons.payments_outlined;
      case 'Assistive Devices': return Icons.accessible_outlined;
      case 'Education':         return Icons.school_outlined;
      case 'Healthcare':        return Icons.local_hospital_outlined;
      case 'Employment':        return Icons.work_outline;
      case 'Legal':             return Icons.gavel_outlined;
      default:                  return Icons.list_alt;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null && args['tab'] == 1) _tabController.animateTo(1);
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/users/saved-programs'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          savedPrograms = data['savedPrograms'] ?? [];
          applications  = data['applications']  ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading saved programs: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _unsaveProgram(String programId, String programName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Saved Program'),
        content: Text('Remove "$programName" from your saved programs?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final res = await http.delete(
          Uri.parse('$baseUrl/api/users/saved-program/$programId'),
          headers: {'x-auth-token': auth.token.value},
        );
        if (res.statusCode == 200) {
          Get.snackbar('Removed', '$programName removed from saved programs',
              backgroundColor: Colors.orange, colorText: Colors.white);
          _loadData();
        }
      } catch (e) {
        Get.snackbar('Error', 'Could not remove program',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':     return Colors.green;
      case 'Rejected':     return Colors.red;
      case 'Completed':    return Colors.blue;
      case 'Under Review': return Colors.orange;
      default:             return const Color(0xff164EB0);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Approved':     return Icons.check_circle_outline;
      case 'Rejected':     return Icons.cancel_outlined;
      case 'Completed':    return Icons.task_alt;
      case 'Under Review': return Icons.hourglass_top;
      default:             return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xff111827) : const Color(0xfff5f7fc);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('My Programs'),
        backgroundColor: const Color(0xff164EB0),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.bookmark_outline, size: 18),
                const SizedBox(width: 6),
                Text('Saved (${savedPrograms.length})'),
              ]),
            ),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.assignment_outlined, size: 18),
                const SizedBox(width: 6),
                Text('Applications (${applications.length})'),
              ]),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSavedTab(isDark),
                _buildApplicationsTab(isDark),
              ],
            ),
    );
  }

  // ── Saved Programs Tab ────────────────────────────────────────────────────
  Widget _buildSavedTab(bool isDark) {
    final cardBg     = isDark ? const Color(0xff1f2937) : Colors.white;
    final titleColor = isDark ? Colors.white            : Colors.black87;
    final subColor   = isDark ? const Color(0xff94a3b8) : Colors.grey[700]!;
    final emptyColor = isDark ? Colors.grey[500]!       : Colors.grey[400]!;
    final emptyTextColor = isDark ? Colors.grey[300]!   : Colors.grey[700]!;

    if (savedPrograms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 70, color: emptyColor),
            const SizedBox(height: 16),
            Text('No saved programs yet',
                style: TextStyle(fontSize: 18, color: emptyTextColor)),
            const SizedBox(height: 8),
            Text('Tap the bookmark icon on any program to save it',
                style: TextStyle(color: subColor, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff164EB0),
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.search),
              label: const Text('Browse Programs'),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: savedPrograms.length,
        itemBuilder: (context, i) {
          final p           = savedPrograms[i];
          final programId   = p['_id']?.toString() ?? '';
          final displayName = _resolveName(programId, p['name']);
          final category    = _resolveCategory(programId);
          final website     = _resolveWebsite(programId);
          final catColor    = _categoryColor(category);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: catColor.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_categoryIcon(category),
                          color: catColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: titleColor)),
                          if (category.isNotEmpty)
                            Text(category,
                                style: TextStyle(
                                    color: catColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark,
                          color: Color(0xff164EB0)),
                      onPressed: () => _unsaveProgram(programId, displayName),
                      tooltip: 'Remove from saved',
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(category,
                            style: TextStyle(fontSize: 11, color: catColor)),
                      ),
                    const Spacer(),
                    if (website.isNotEmpty)
                      TextButton.icon(
                        icon: Icon(Icons.open_in_browser,
                            size: 14,
                            color: isDark
                                ? Colors.lightBlueAccent
                                : const Color(0xff164EB0)),
                        label: Text('Visit Website',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.lightBlueAccent
                                    : const Color(0xff164EB0))),
                        onPressed: () => _launchUrl(website),
                      ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Applications Tab ──────────────────────────────────────────────────────
  Widget _buildApplicationsTab(bool isDark) {
    final cardBg         = isDark ? const Color(0xff1f2937) : Colors.white;
    final titleColor     = isDark ? Colors.white            : Colors.black87;
    final emptyColor     = isDark ? Colors.grey[500]!       : Colors.grey[400]!;
    final emptyTextColor = isDark ? Colors.grey[300]!       : Colors.grey[700]!;
    final emptySubColor  = isDark ? Colors.grey[400]!       : Colors.grey[600]!;

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 70, color: emptyColor),
            const SizedBox(height: 16),
            Text('No applications yet',
                style: TextStyle(fontSize: 18, color: emptyTextColor)),
            const SizedBox(height: 8),
            Text(
                'Track your program applications here once you start applying',
                style: TextStyle(color: emptySubColor, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: applications.length,
        itemBuilder: (context, i) {
          final app         = applications[i];
          final programId   = app['programId']?.toString() ?? '';
          final programName = _resolveName(programId, app['programName']);
          final status      = app['status'] ?? 'Pending';
          final appliedAt   = app['appliedAt'] != null
              ? DateTime.tryParse(app['appliedAt'])
              : null;
          final dateColor   = isDark ? const Color(0xff94a3b8) : Colors.grey[600]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: _statusColor(status).withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon(status),
                          color: _statusColor(status), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(programName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: titleColor)),
                          if (appliedAt != null)
                            Text(
                              'Applied: ${appliedAt.day}/${appliedAt.month}/${appliedAt.year}',
                              style: TextStyle(color: dateColor, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Progress stepper
                  Row(
                    children:
                        ['Pending', 'Under Review', 'Approved'].map((s) {
                      final steps = ['Pending', 'Under Review', 'Approved'];
                      final currentIndex = steps.indexOf(
                          status == 'Completed' ? 'Approved' : status);
                      final stepIndex  = steps.indexOf(s);
                      final isDone     = currentIndex >= stepIndex &&
                          status != 'Rejected';
                      final isRejected = status == 'Rejected';
                      final isLast     = s == 'Approved';
                      final stepLabelColor = isDone && !isRejected
                          ? _statusColor(status)
                          : (isDark ? Colors.grey[400]! : Colors.grey[600]!);

                      return Expanded(
                        child: Row(children: [
                          Expanded(
                            child: Column(children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isRejected
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : isDone
                                        ? _statusColor(status)
                                        : (isDark
                                            ? const Color(0xff374151)
                                            : Colors.grey[200]),
                                child: Icon(
                                  isRejected
                                      ? Icons.close
                                      : isDone
                                          ? Icons.check
                                          : Icons.circle,
                                  size: 12,
                                  color: isRejected
                                      ? Colors.red
                                      : isDone
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(s,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: stepLabelColor)),
                            ]),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Divider(
                                color: isDone && stepIndex < currentIndex
                                    ? _statusColor(status)
                                    : (isDark
                                        ? const Color(0xff374151)
                                        : Colors.grey[300]),
                                thickness: 2,
                              ),
                            ),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}