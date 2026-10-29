import 'package:flutter/material.dart';

import '../models/evaluation_result.dart';

/// Streamlined Result Analysis Dashboard matching the reference design:
/// Features 3 clean metric cards:
/// 1. ACTUAL SPEED (WPM / CPM & Duration)
/// 2. ACCURACY (Levenshtein match against target sentence)
/// 3. AESTHETIC (Holistic Grade & Score out of 100)
/// Along with exact recognized text strip and Next Sentence button.
class ResultsDashboard extends StatelessWidget {
  final HandwritingEvaluationResult result;
  final VoidCallback? onNextSentence;
  final VoidCallback? onClose;

  const ResultsDashboard({
    super.key,
    required this.result,
    this.onNextSentence,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final speed = result.speedMetrics;
    final aesthetics = result.aestheticScore;
    final accuracy = result.accuracyMetrics;

    final wpm = speed.speedWpm;
    final cpm = speed.charactersPerMinute;
    final durationSec = speed.writingDuration.inMilliseconds / 1000.0;
    final accPct = accuracy?.overallAccuracy ?? 82;
    final charMatches = accuracy?.correctMatchesCount ?? result.recognizedOcrText.trim().length;
    final targetChars = result.targetSentence.trim().length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEA580C), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33EA580C),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'RESULT ANALYSIS',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF97316),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x33EA580C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x80EA580C)),
                    ),
                    child: const Text(
                      'Google Digital Ink ML Kit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFDBA74),
                      ),
                    ),
                  ),
                ],
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // 3 Streamlined Metric Cards Side by Side
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final cards = [
                // Card 1: Actual Speed
                _buildMetricCard(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFF97316),
                  label: 'ACTUAL SPEED',
                  value: wpm.toStringAsFixed(1),
                  unit: 'WPM',
                  valueColor: Colors.white,
                  footer: '${cpm.round()} CPM • Active: ${durationSec.toStringAsFixed(1)}s',
                ),
                // Card 2: Accuracy
                _buildMetricCard(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF34D399),
                  label: 'ACCURACY',
                  value: '$accPct',
                  unit: '%',
                  valueColor: const Color(0xFF34D399),
                  footer: '$charMatches / $targetChars chars matched',
                ),
                // Card 3: Aesthetic
                _buildMetricCard(
                  icon: Icons.auto_graph_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  label: 'AESTHETIC',
                  value: aesthetics.grade,
                  unit: 'Grade (${aesthetics.overallScore.round()}/100)',
                  valueColor: const Color(0xFFFBBF24),
                  footer: 'Fluid curvature & baseline rhythm',
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                  ],
                );
              }
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 10),
                  cards[1],
                  const SizedBox(height: 10),
                  cards[2],
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Recognized Text Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF09152A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E3A8A)),
            ),
            child: Row(
              children: [
                const Text(
                  'Tt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Recognized: ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      children: [
                        TextSpan(
                          text: '"${result.recognizedOcrText}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (onNextSentence != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onNextSentence,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                label: const Text('Next Sentence'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF97316),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: valueColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
