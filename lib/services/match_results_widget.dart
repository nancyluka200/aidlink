import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'matching_engine.dart';

class MatchResultsWidget extends StatelessWidget {
  final MatchOutput output;

  const MatchResultsWidget({super.key, required this.output});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Best Match ──────────────────────────────────────────────────────
        const _SectionHeader(
          label: 'Best Match',
          sublabel: 'You meet all requirements for this program',
          color: Color(0xFF1A7F54),
        ),
        const SizedBox(height: 8),
        _ProgramCard(result: output.topMatch, isBestMatch: true),

        // ── Suggestions ─────────────────────────────────────────────────────
        if (output.suggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionHeader(
            label: 'You May Also Qualify',
            sublabel: 'Meet the missing requirements to unlock these programs',
            color: Color(0xFF92600A),
          ),
          const SizedBox(height: 8),
          ...output.suggestions.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProgramCard(result: r, isBestMatch: false),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Program Card ──────────────────────────────────────────────────────────────
class _ProgramCard extends StatefulWidget {
  final MatchResult result;
  final bool isBestMatch;

  const _ProgramCard({required this.result, required this.isBestMatch});

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isBest = widget.isBestMatch;

    final borderColor =
        isBest ? const Color(0xFF1A7F54) : const Color(0xFFF59E0B);
    final badgeBg =
        isBest ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final badgeText =
        isBest ? const Color(0xFF065F46) : const Color(0xFF92600A);
    final badgeLabel = isBest ? '✓  Best Match' : '◑  Partial Match';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: isBest ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge + score
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: badgeText),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CategoryChip(label: r.program.category),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Program name
                      Text(
                        r.program.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.program.organization,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Score circle
                _ScoreCircle(score: r.matchScore, isBest: isBest),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Missing Requirements (partial only) ────────────────────────────
          if (!isBest && r.missingRequirements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What you still need:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92600A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...r.missingRequirements.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: Color(0xFF92600A), fontSize: 12)),
                            Expanded(
                              child: Text(
                                m,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF92600A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Why You Match ─────────────────────────────────────────────────
          if (r.matchReasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why you match:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A7F54)),
                  ),
                  const SizedBox(height: 4),
                  ...r.matchReasons.map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✓ ',
                              style: TextStyle(
                                  color: Color(0xFF1A7F54), fontSize: 12)),
                          Expanded(
                            child: Text(reason,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF1A7F54))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Expandable Details ────────────────────────────────────────────
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    r.program.description,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),

                  // Required Documents
                  const Text(
                    'Required Documents',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  ...r.program.requiredDocuments.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📄 ',
                              style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(doc,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // How to Apply
                  const Text(
                    'How to Apply',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.program.howToApply,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),

                  // Deadline
                  if (r.program.deadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('🗓 ',
                            style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            r.program.deadline!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92600A),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Contact + Website
                  Text(
                    r.program.contactInfo,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(r.program.websiteUrl);
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                    child: Text(
                      r.program.websiteUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Expand / Collapse Button ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Hide details' : 'View details',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: const Color(0xFF1D4ED8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score Circle ──────────────────────────────────────────────────────────────
class _ScoreCircle extends StatelessWidget {
  final int score;
  final bool isBest;

  const _ScoreCircle({required this.score, required this.isBest});

  @override
  Widget build(BuildContext context) {
    final color =
        isBest ? const Color(0xFF1A7F54) : const Color(0xFFF59E0B);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            'match',
            style: TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  Color _color() {
    switch (label) {
      case 'Cash Transfer':
        return const Color(0xFF1D4ED8);
      case 'Education':
        return const Color(0xFF7C3AED);
      case 'Assistive Devices':
        return const Color(0xFF0891B2);
      case 'Healthcare':
        return const Color(0xFFDC2626);
      case 'Employment':
        return const Color(0xFF059669);
      case 'Legal':
        return const Color(0xFF92600A);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: _color()),
      ),
    );
  }
}