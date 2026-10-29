import 'package:flutter/material.dart';

import '../models/sentence_prompt.dart';

/// Top Section of the Tablet UI.
///
/// Displays:
/// - Difficulty badge (`Easy`, `Medium`, `Hard`) & fixed allocated time limit
/// - Sentence selector pills + Next Sentence button
/// - Live countdown progress bar (starts automatically on the first stylus stroke)
/// - Dynamic target sentence container that **automatically disappears** the
///   exact moment the allocated fixed time expires, regardless of whether the
///   student has completed writing it.
class SentencePromptBanner extends StatelessWidget {
  final List<SentencePrompt> prompts;
  final SentencePrompt activePrompt;
  final bool hasTimerStarted;
  final bool isSentenceExpired;
  final Duration remainingTime;
  final ValueChanged<SentencePrompt> onSelectPrompt;

  const SentencePromptBanner({
    super.key,
    required this.prompts,
    required this.activePrompt,
    required this.hasTimerStarted,
    required this.isSentenceExpired,
    required this.remainingTime,
    required this.onSelectPrompt,
  });

  Color _difficultyColor(SentenceDifficulty difficulty) {
    switch (difficulty) {
      case SentenceDifficulty.easy:
        return const Color(0xFF0D9488); // Teal
      case SentenceDifficulty.medium:
        return const Color(0xFF2563EB); // Royal Blue
      case SentenceDifficulty.hard:
        return const Color(0xFF7C3AED); // Deep Violet
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = activePrompt.fixedTimeLimit.inMilliseconds.clamp(1, 600000);
    final remMs = remainingTime.inMilliseconds.clamp(0, totalMs);
    final progress = remMs / totalMs;
    final remSecondsText = (remMs / 1000.0).toStringAsFixed(1);
    final diffColor = _difficultyColor(activePrompt.difficulty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSentenceExpired
              ? const Color(0xFFF59E0B)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top metadata row: Difficulty badge, Sentence selector, Fixed Timer Status
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: diffColor.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_graph_rounded,
                            size: 16, color: diffColor),
                        const SizedBox(width: 6),
                        Text(
                          '${activePrompt.difficulty.label} Level • Fixed ${activePrompt.fixedTimeLimit.inSeconds}s Limit',
                          style: TextStyle(
                            color: diffColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Prompt selector dropdown for tablet convenience
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButton<String>(
                        value: activePrompt.id,
                        isDense: true,
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        items: prompts.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              '${p.difficulty.label} (${p.fixedTimeLimit.inSeconds}s): ${p.text.length > 34 ? '${p.text.substring(0, 34)}...' : p.text}',
                            ),
                          );
                        }).toList(),
                        onChanged: (selectedId) {
                          if (selectedId != null) {
                            final found = prompts
                                .firstWhere((item) => item.id == selectedId);
                            onSelectPrompt(found);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Live Fixed Countdown Timer Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSentenceExpired
                      ? const Color(0xFFFEF3C7)
                      : hasTimerStarted
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSentenceExpired
                        ? const Color(0xFFF59E0B)
                        : hasTimerStarted
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSentenceExpired
                          ? Icons.visibility_off_rounded
                          : hasTimerStarted
                              ? Icons.timer_rounded
                              : Icons.touch_app_rounded,
                      size: 16,
                      color: isSentenceExpired
                          ? const Color(0xFFB45309)
                          : hasTimerStarted
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSentenceExpired
                          ? 'Time Expired (0.0s) — Sentence Hidden'
                          : hasTimerStarted
                              ? 'Prompt Disappears In: ${remSecondsText}s'
                              : 'Timer (${activePrompt.fixedTimeLimit.inSeconds}.0s) starts on first stroke',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSentenceExpired
                            ? const Color(0xFFB45309)
                            : hasTimerStarted
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar for fixed sentence visibility timer
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: isSentenceExpired ? 0.0 : progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isSentenceExpired
                    ? const Color(0xFFF59E0B)
                    : progress < 0.25
                        ? const Color(0xFFEF4444)
                        : diffColor,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Dynamic Target Sentence Box (Auto-disappears when allocated time expires)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSentenceExpired
                ? Container(
                    key: const ValueKey('expired_sentence_banner'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Allocated prompt display time has expired. Finish writing the sentence from memory on the canvas below, then tap Submit / Analyze.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: ValueKey('visible_sentence_${activePrompt.id}'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TARGET SENTENCE TO COPY:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activePrompt.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.35,
                            letterSpacing: 0.2,
                          ),
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
