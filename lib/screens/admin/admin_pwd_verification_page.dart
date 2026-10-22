import 'dart:convert';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AdminPwdVerificationPage extends StatefulWidget {
  const AdminPwdVerificationPage({super.key});

  @override
  State<AdminPwdVerificationPage> createState() =>
      _AdminPwdVerificationPageState();
}

class _AdminPwdVerificationPageState
    extends State<AdminPwdVerificationPage> {
  final auth = Get.find<AuthController>();
  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _loading      = true;
      _errorMessage = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/pwd-pending'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _pendingUsers =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(
            () => _errorMessage = 'Failed to load (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyCard(String userId, String userName) async {
    final confirmed = await _confirmDialog(
      title: 'Verify PWD Card',
      message: 'Confirm that $userName\'s PWD card is valid and approve it?',
      confirmLabel: 'Verify',
      confirmColor: Colors.green,
    );
    if (!confirmed) return;

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/admin/verify-pwd/$userId'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        Get.snackbar('Verified ✓', '$userName\'s PWD card has been verified.',
            backgroundColor: Colors.green, colorText: Colors.white);
        _loadPendingUsers();
      } else {
        Get.snackbar('Error', 'Could not verify. Try again.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (_) {
      Get.snackbar('Error', 'Network error.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _rejectCard(String userId, String userName) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reject PWD Card',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide a rejection reason for $userName:',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Card number does not match NCPWD records',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Get.back(result: true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/admin/reject-pwd/$userId'),
        headers: {
          'x-auth-token': auth.token.value,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : 'Card number could not be verified',
        }),
      );
      if (res.statusCode == 200) {
        Get.snackbar('Rejected', '$userName\'s PWD card has been rejected.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        _loadPendingUsers();
      } else {
        Get.snackbar('Error', 'Could not reject. Try again.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (_) {
      Get.snackbar('Error', 'Network error.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white),
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f2f8),
      appBar: AppBar(
        title: const Text('PWD Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff0A3080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingUsers,
              child: _errorMessage != null
                  ? _buildError()
                  : _pendingUsers.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
    );
  }

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
            onPressed: _loadPendingUsers,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A3080),
                foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 56, color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Text('All caught up!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          const Text('No PWD cards are pending verification.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(children: [
            Icon(Icons.pending_outlined,
                color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 10),
            Text(
              '${_pendingUsers.length} PWD card${_pendingUsers.length == 1 ? '' : 's'} awaiting review',
              style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        ..._pendingUsers.map((user) => _buildUserCard(user)),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String userId    = user['_id'] ?? '';
    final String firstName = user['firstName'] ?? '';
    final String lastName  = user['lastName'] ?? '';
    final String fullName  = '$firstName $lastName'.trim();
    final String email     = user['email'] ?? '';
    final String cardNum   = user['pwdCardNumber'] ?? '';
    final String imageUrl  = user['pwdCardImageUrl'] ?? '';
    final String location  = user['location'] ?? '';
    final String disType   = user['disabilityType'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xff0A3080).withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xff0A3080).withValues(alpha: 0.12),
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Color(0xff0A3080),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(email,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Pending',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          // ── Details ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.isNotEmpty)
                  _detailRow(Icons.location_on_outlined, 'Location', location),
                if (disType.isNotEmpty)
                  _detailRow(Icons.accessible_outlined, 'Disability Type', disType),
                if (cardNum.isNotEmpty)
                  _detailRow(Icons.credit_card_outlined, 'PWD Card Number', cardNum),

                // PWD card image
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('PWD Card Image',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showImageDialog(imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Image not available',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Tap image to enlarge',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                ] else ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Text('No card image uploaded',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Action buttons ────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _rejectCard(userId, fullName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline,
                          size: 16),
                      label: const Text('Verify',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _verifyCard(userId, fullName),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}