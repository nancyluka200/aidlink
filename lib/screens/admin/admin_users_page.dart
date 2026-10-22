import 'dart:convert';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  final auth = Get.find<AuthController>();
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _filterStatus = 'All';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // admin.js returns plain array OR { users: [...] } — handle both
        final usersList = data is List ? data : (data['users'] ?? []);
        setState(() {
          allUsers = usersList;
          _applyFilter();
        });
      } else {
        Get.snackbar('Error', 'Could not load users (${res.statusCode})',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((u) {
        final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final matchesSearch = query.isEmpty || name.contains(query) || email.contains(query);
        final profileDone = u['profileCompleted'] == true;
        final matchesStatus = _filterStatus == 'All'
            ? true
            : _filterStatus == 'Complete' ? profileDone : !profileDone;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  List<dynamic> get _pendingPwdUsers =>
      allUsers.where((u) => u['pwdCardVerificationStatus'] == 'pending').toList();

  // ── PWD Card Verification Dialog ──────────────────────────────────────────
  void _showPwdVerificationDialog(dynamic user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
    final pwdNumber = user['pwdCardNumber'] ?? '';
    final pwdImageUrl = user['pwdCardImageUrl'] ?? '';
    final rejectionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    const Icon(Icons.credit_card, color: Color(0xff164EB0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Review PWD Card — $name',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ]),
                  const Divider(),
                  const SizedBox(height: 8),

                  // PWD Card Number
                  _detailRow('Card Number', pwdNumber.isNotEmpty ? pwdNumber : 'Not provided'),
                  _detailRow('Email', user['email'] ?? ''),
                  _detailRow('Disability Type', user['disabilityType'] ?? ''),
                  const SizedBox(height: 12),

                  // PWD Card Image
                  const Text('PWD Card Photo:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (pwdImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        pwdImageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: Colors.grey[100],
                          child: const Center(
                            child: Text('Could not load image',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('No card photo uploaded',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Rejection reason field
                  const Text('Rejection reason (required if rejecting):',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: rejectionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Card number format is incorrect — should be NCPWD/P/XXXXXX',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Reject Card'),
                        onPressed: () => _verifyPwdCard(
                          user['_id'], 'rejected',
                          rejectionController.text.trim(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 16),
                        label: const Text('Verify Card'),
                        onPressed: () => _verifyPwdCard(user['_id'], 'verified', ''),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPwdCard(String userId, String decision, String reason) async {
    if (decision == 'rejected' && reason.isEmpty) {
      Get.snackbar('Required', 'Please enter a rejection reason',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    try {
      // ── Use correct existing endpoints: verify-pwd or reject-pwd ──────────
      final url = decision == 'verified'
          ? '$baseUrl/api/admin/verify-pwd/$userId'
          : '$baseUrl/api/admin/reject-pwd/$userId';

      final body = decision == 'rejected'
          ? jsonEncode({'reason': reason})
          : '{}';

      final res = await http.put(
        Uri.parse(url),
        headers: {
          'x-auth-token': auth.token.value,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (res.statusCode == 200) {
        Get.back();
        Get.snackbar(
          decision == 'verified' ? 'Card Verified ✓' : 'Card Rejected',
          decision == 'verified'
              ? 'PWD card has been verified successfully'
              : 'User must re-upload a valid card',
          backgroundColor: decision == 'verified' ? Colors.green : Colors.orange,
          colorText: Colors.white,
        );
        _loadUsers();
      } else {
        Get.snackbar('Error', res.body,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text('$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  void _showUserDetail(dynamic user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
    final email = user['email'] ?? '-';
    final profileDone = user['profileCompleted'] == true;
    final apps = List<dynamic>.from(user['applications'] ?? []);
    final pwdStatus = user['pwdCardVerificationStatus'] ?? 'unverified';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // User header
              Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xff164EB0).withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Color(0xff164EB0)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(email,
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _statusPill(profileDone ? 'Complete' : 'Incomplete',
                      profileDone ? Colors.green : Colors.orange),
                  const SizedBox(height: 4),
                  _statusPill(
                    pwdStatus == 'verified'
                        ? 'Card Verified'
                        : pwdStatus == 'pending'
                            ? 'Card Pending'
                            : pwdStatus == 'rejected'
                                ? 'Card Rejected'
                                : 'No Card',
                    pwdStatus == 'verified'
                        ? Colors.green
                        : pwdStatus == 'pending'
                            ? Colors.orange
                            : Colors.grey,
                  ),
                ]),
              ]),
              const SizedBox(height: 16),

              // PWD card review button if pending
              if (pwdStatus == 'pending') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.pending_actions, color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('PWD Card awaiting verification',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Get.back();
                        _showPwdVerificationDialog(user);
                      },
                      child: const Text('Review', style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Profile details
              _sectionLabel('Profile Details'),
              _detailRow('Applicant Type', user['applicantType'] ?? '-'),
              _detailRow('Age', user['age']?.toString() ?? '-'),
              _detailRow('County', user['location'] ?? '-'),
              _detailRow('Disability Type', user['disabilityType'] ?? '-'),
              _detailRow('PWD Card No.', user['pwdCardNumber'] ?? '-'),
              _detailRow('Monthly Income',
                  user['income'] != null ? 'KES ${user['income']}' : '-'),
              const SizedBox(height: 12),

              // Applications
              _sectionLabel('Applications (${apps.length})'),
              if (apps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No applications yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                )
              else
                ...apps.map((a) {
                  final programName = a['programName'] ?? a['programId'] ?? 'Unknown';
                  final status = a['status'] ?? 'Pending';
                  final statusColor = status == 'Approved'
                      ? Colors.green
                      : status == 'Rejected'
                          ? Colors.red
                          : status == 'Under Review'
                              ? Colors.orange
                              : const Color(0xff164EB0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(programName,
                              style: const TextStyle(fontSize: 13))),
                      _statusPill(status, statusColor),
                    ]),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold,
                color: Color(0xff164EB0), letterSpacing: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
              color: const Color(0xff164EB0).withValues(alpha: 0.2), thickness: 1),
        ),
      ]),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingPwdUsers.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Users (${allUsers.length})'),
        backgroundColor: const Color(0xff0A3080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(text: 'All Users'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('PWD Verification'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$pendingCount',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildPwdVerificationTab(),
        ],
      ),
    );
  }

  // ── All Users Tab ──────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search + Filter
        Container(
          color: const Color(0xff0A3080),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['All', 'Complete', 'Incomplete'].map((f) {
                  final selected = _filterStatus == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _filterStatus = f);
                        _applyFilter();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? const Color(0xff0A3080)
                                    : Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Users list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            allUsers.isEmpty
                                ? 'No users registered yet'
                                : 'No users match your search',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, i) {
                          final user = filteredUsers[i];
                          final name =
                              '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
                          final email = user['email'] ?? '';
                          final profileDone = user['profileCompleted'] == true;
                          final apps = List<dynamic>.from(user['applications'] ?? []);
                          final pwdStatus = user['pwdCardVerificationStatus'] ?? 'unverified';
                          final disability = user['disabilityType'] ?? '';
                          final location = user['location'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: pwdStatus == 'pending'
                                    ? Colors.orange.withValues(alpha: 0.4)
                                    : Colors.grey.withValues(alpha: 0.15),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xff164EB0).withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff164EB0)),
                                ),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    if (disability.isNotEmpty) ...[
                                      Icon(Icons.accessible_outlined,
                                          size: 11, color: Colors.grey[400]),
                                      const SizedBox(width: 3),
                                      Text(disability,
                                          style: TextStyle(
                                              fontSize: 11, color: Colors.grey[500])),
                                      const SizedBox(width: 8),
                                    ],
                                    if (location.isNotEmpty) ...[
                                      Icon(Icons.location_on_outlined,
                                          size: 11, color: Colors.grey[400]),
                                      const SizedBox(width: 3),
                                      Text(location,
                                          style: TextStyle(
                                              fontSize: 11, color: Colors.grey[500])),
                                    ],
                                  ]),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _statusPill(
                                    profileDone ? 'Complete' : 'Incomplete',
                                    profileDone ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(height: 3),
                                  if (pwdStatus == 'pending')
                                    _statusPill('Card Pending', Colors.orange)
                                  else if (pwdStatus == 'verified')
                                    _statusPill('Card Verified', Colors.green)
                                  else
                                    Text('${apps.length} app${apps.length == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              onTap: () => _showUserDetail(user),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ── PWD Verification Tab ───────────────────────────────────────────────────
  Widget _buildPwdVerificationTab() {
    final pending = _pendingPwdUsers;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No pending verifications',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 6),
            Text('All PWD cards have been reviewed',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pending.length,
      itemBuilder: (context, i) {
        final user = pending[i];
        final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
        final pwdNumber = user['pwdCardNumber'] ?? 'Not provided';
        final hasImage = (user['pwdCardImageUrl'] ?? '').isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.withValues(alpha: 0.4)),
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
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pending_actions,
                        color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(user['email'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ),
                  _statusPill('Pending Review', Colors.orange),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.credit_card_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Card No: $pwdNumber',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  Icon(hasImage ? Icons.image : Icons.image_not_supported,
                      size: 14,
                      color: hasImage ? Colors.green : Colors.grey),
                  const SizedBox(width: 4),
                  Text(hasImage ? 'Photo uploaded' : 'No photo',
                      style: TextStyle(
                          fontSize: 12,
                          color: hasImage ? Colors.green : Colors.grey)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff164EB0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.rate_review_outlined, size: 16),
                    label: const Text('Review PWD Card'),
                    onPressed: () => _showPwdVerificationDialog(user),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}