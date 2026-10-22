import 'package:aidlinkapp/services/matching_engine.dart';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProgramResultsPage extends StatefulWidget {
  const ProgramResultsPage({super.key});

  @override
  State<ProgramResultsPage> createState() => _ProgramResultsPageState();
}

class _ProgramResultsPageState extends State<ProgramResultsPage> {
  final auth = Get.find<AuthController>();

  late MatchOutput matchOutput;
  late List<MatchResult> results;

  String selectedCategory = 'All';

  final List<String> categories = [
    'All', 'Cash Transfer', 'Assistive Devices',
    'Education', 'Healthcare', 'Employment', 'Legal',
  ];

  @override
  void initState() {
    super.initState();
    matchOutput = MatchingEngine.match(auth);
    results = [matchOutput.topMatch, ...matchOutput.suggestions];
  }

  List<MatchResult> get filteredResults {
    if (selectedCategory == 'All') return results;
    return results.where((r) => r.program.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullyEligibleCount = results.where((r) => r.fullyEligible).length;
    final partialCount = results.where((r) => !r.fullyEligible).length;

    final bgColor  = isDark ? const Color(0xff111827) : const Color(0xfff5f7fc);
    final bannerBg = isDark
        ? const Color(0xff1e3a6e).withValues(alpha: 0.5)
        : const Color(0xff164EB0).withValues(alpha: 0.08);
    final chipBg   = isDark ? const Color(0xff1f2937) : Colors.white;
    final chipText = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Matched Programs'),
        backgroundColor: const Color(0xff164EB0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Summary banner ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: bannerBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${results.length} program${results.length == 1 ? '' : 's'} found for you',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text('$fullyEligibleCount fully eligible',
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  const Icon(Icons.pending_outlined, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text('$partialCount partial match${partialCount == 1 ? '' : 'es'}',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),

          // ── Category filter ────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : chipText)),
                    selected: isSelected,
                    selectedColor: const Color(0xff164EB0),
                    backgroundColor: chipBg,
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  ),
                );
              },
            ),
          ),

          // ── Results list ───────────────────────────────────────────────
          Expanded(
            child: filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 60,
                            color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No $selectedCategory programs matched',
                          style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, i) {
                      final result = filteredResults[i];
                      final isTop =
                          result.program.id == matchOutput.topMatch.program.id;
                      return _ProgramCard(result: result, isTopMatch: isTop);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Program Card ──────────────────────────────────────────────────────────────
class _ProgramCard extends StatefulWidget {
  final MatchResult result;
  final bool isTopMatch;

  const _ProgramCard({required this.result, required this.isTopMatch});

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _expanded = false;
  bool _saved    = false;
  bool _applied  = false;

  final auth = Get.find<AuthController>();

  Color get _scoreColor {
    if (widget.result.fullyEligible) {
      if (widget.result.matchScore >= 80) return Colors.green;
      return Colors.teal;
    }
    if (widget.result.matchScore >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData get _categoryIcon {
    switch (widget.result.program.category) {
      case 'Cash Transfer':     return Icons.payments_outlined;
      case 'Assistive Devices': return Icons.accessible_outlined;
      case 'Education':         return Icons.school_outlined;
      case 'Healthcare':        return Icons.local_hospital_outlined;
      case 'Employment':        return Icons.work_outline;
      case 'Legal':             return Icons.gavel_outlined;
      default:                  return Icons.info_outline;
    }
  }

  Future<void> _saveProgram(String programId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/save-program/$programId'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        setState(() => _saved = true);
        Get.snackbar('Saved!', 'Program saved successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else if (res.statusCode == 400) {
        setState(() => _saved = true);
        Get.snackbar('Already Saved', 'This program is already in your saved list',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not save program',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _trackApplication(String programId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/apply/$programId'),
        headers: {'x-auth-token': auth.token.value},
      );
      if (res.statusCode == 200) {
        setState(() => _applied = true);
        Get.snackbar('Tracked!', 'Application added to your tracking list',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else if (res.statusCode == 400) {
        setState(() => _applied = true);
        Get.snackbar('Already Tracking', 'This application is already being tracked',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not track application',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open link',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final cardBg     = isDark ? const Color(0xff1f2937) : Colors.white;
    final titleColor = isDark ? Colors.white            : Colors.black87;
    final bodyColor  = isDark ? const Color(0xffcbd5e1) : const Color(0xff374151);
    final subColor   = isDark ? const Color(0xff94a3b8) : Colors.grey[600]!;
    final iconMuted  = isDark ? const Color(0xff94a3b8) : Colors.grey[600]!;
    final divColor   = isDark ? const Color(0xff374151) : Colors.grey[200]!;
    final outlineBorderColor = isDark
        ? const Color(0xff6b7280)
        : const Color(0xff164EB0);

    final program = widget.result.program;
    final result  = widget.result;

    final borderColor = result.fullyEligible
        ? Colors.green.withValues(alpha: isDark ? 0.5 : 0.4)
        : Colors.orange.withValues(alpha: isDark ? 0.5 : 0.4);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: borderColor,
            width: widget.isTopMatch ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Badge row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.fullyEligible
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    result.fullyEligible
                        ? Icons.verified_outlined
                        : Icons.pending_outlined,
                    size: 13,
                    color: result.fullyEligible ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    result.matchLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: result.fullyEligible ? Colors.green : Colors.orange,
                    ),
                  ),
                ]),
              ),
              if (widget.isTopMatch) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff164EB0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star, size: 11, color: Color(0xff164EB0)),
                    SizedBox(width: 3),
                    Text('Top Match',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff164EB0))),
                  ]),
                ),
              ],
            ]),
          ),

          // ── Card header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff164EB0).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon,
                    color: const Color(0xff164EB0), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(program.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: titleColor)),
                  const SizedBox(height: 2),
                  Text(program.organization,
                      style: TextStyle(color: subColor, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Column(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.matchScore}%',
                    style: TextStyle(
                        color: _scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(height: 4),
                Text(result.matchLabel,
                    style: TextStyle(color: _scoreColor, fontSize: 10)),
              ]),
            ]),
          ),

          // ── Description ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(program.description,
                style: TextStyle(fontSize: 13, color: bodyColor)),
          ),

          // ── Eligibility status ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: result.fullyEligible
                ? const Row(children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text('You meet all requirements',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ])
                : result.missingRequirements.isNotEmpty
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(result.missingRequirements.first,
                              style: const TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ),
                      ])
                    : const SizedBox.shrink(),
          ),

          // ── Expand / collapse ──────────────────────────────────────────
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_expanded ? 'Show less' : 'View details',
                  style: const TextStyle(
                      color: Color(0xff164EB0), fontSize: 13)),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xff164EB0), size: 18),
            ]),
          ),

          // ── Expanded details ───────────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: divColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Why you match
                  if (result.matchReasons.isNotEmpty) ...[
                    Text('Why you match:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: titleColor)),
                    const SizedBox(height: 6),
                    ...result.matchReasons.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Icon(Icons.check,
                                color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(r,
                                    style: TextStyle(
                                        fontSize: 12, color: bodyColor))),
                          ]),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Missing requirements
                  if (result.missingRequirements.isNotEmpty) ...[
                    Text('Missing requirements:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.orange[300]! : Colors.orange[800]!)),
                    const SizedBox(height: 6),
                    ...result.missingRequirements.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Icon(Icons.close,
                                color: Colors.orange, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(r,
                                    style: TextStyle(
                                        fontSize: 12, color: bodyColor))),
                          ]),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Required documents
                  Text('Required documents:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: titleColor)),
                  const SizedBox(height: 6),
                  ...program.requiredDocuments.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Icon(Icons.description_outlined,
                              color: iconMuted, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(d,
                                  style: TextStyle(
                                      fontSize: 12, color: bodyColor))),
                        ]),
                      )),
                  const SizedBox(height: 12),

                  // Deadline
                  if (program.deadline != null) ...[
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Deadline: ${program.deadline}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // How to apply
                  Text('How to apply:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: titleColor)),
                  const SizedBox(height: 6),
                  Text(program.howToApply,
                      style: TextStyle(fontSize: 12, color: bodyColor)),
                  const SizedBox(height: 12),

                  // Contact
                  Row(children: [
                    Icon(Icons.phone_outlined, color: iconMuted, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(program.contactInfo,
                          style: TextStyle(fontSize: 12, color: bodyColor)),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // ── Action buttons ─────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff164EB0),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.open_in_browser, size: 16),
                        label: const Text('Visit Website',
                            style: TextStyle(fontSize: 13)),
                        onPressed: () => _launchUrl(program.websiteUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white70
                              : const Color(0xff164EB0),
                          side: BorderSide(color: outlineBorderColor),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Link',
                            style: TextStyle(fontSize: 13)),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: program.websiteUrl));
                          Get.snackbar('Copied!', program.websiteUrl,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2));
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _saved ? Colors.green : const Color(0xff164EB0),
                          side: BorderSide(
                              color: _saved
                                  ? Colors.green
                                  : const Color(0xff164EB0)),
                        ),
                        icon: Icon(
                            _saved ? Icons.bookmark : Icons.bookmark_border,
                            size: 16),
                        label: Text(_saved ? 'Saved' : 'Save Program',
                            style: const TextStyle(fontSize: 13)),
                        onPressed: _saved ? null : () => _saveProgram(program.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _applied
                              ? Colors.teal
                              : (isDark ? Colors.white70 : Colors.grey[700]!),
                          side: BorderSide(
                              color: _applied
                                  ? Colors.teal
                                  : (isDark
                                      ? const Color(0xff6b7280)
                                      : Colors.grey)),
                        ),
                        icon: Icon(
                            _applied
                                ? Icons.assignment_turned_in_outlined
                                : Icons.assignment_outlined,
                            size: 16),
                        label: Text(_applied ? 'Tracking' : 'Track Apply',
                            style: const TextStyle(fontSize: 13)),
                        onPressed:
                            _applied ? null : () => _trackApplication(program.id),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}