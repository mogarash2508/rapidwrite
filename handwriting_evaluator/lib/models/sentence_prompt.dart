/// Difficulty tier for a handwriting copy prompt.
///
/// Each difficulty level defines a default fixed time limit (in seconds)
/// after which the prompt sentence automatically disappears from the top banner,
/// independent of how fast or slow the student writes.
enum SentenceDifficulty {
  easy(label: 'Easy', defaultTimeLimitSeconds: 12, benchmarkCpm: 70.0),
  medium(label: 'Medium', defaultTimeLimitSeconds: 20, benchmarkCpm: 100.0),
  hard(label: 'Hard', defaultTimeLimitSeconds: 30, benchmarkCpm: 130.0);

  final String label;
  final int defaultTimeLimitSeconds;
  final double benchmarkCpm;

  const SentenceDifficulty({
    required this.label,
    required this.defaultTimeLimitSeconds,
    required this.benchmarkCpm,
  });
}

/// Represents a target sentence with a fixed time limit based on its difficulty.
class SentencePrompt {
  final String id;
  final String text;
  final SentenceDifficulty difficulty;

  /// Fixed duration allocated to view this sentence after the first stylus stroke.
  /// Remains strictly constant for the sentence and never adapts to student speed.
  final Duration fixedTimeLimit;

  const SentencePrompt({
    required this.id,
    required this.text,
    required this.difficulty,
    Duration? customTimeLimit,
  }) : fixedTimeLimit = customTimeLimit ??
            Duration(
              seconds: difficulty == SentenceDifficulty.easy
                  ? 12
                  : difficulty == SentenceDifficulty.medium
                      ? 20
                      : 30,
            );

  /// Built-in curriculum of tablet handwriting evaluation prompts across difficulties.
  static const List<SentencePrompt> defaultPrompts = [
    SentencePrompt(
      id: 'easy_1',
      text: 'Bright stars shine softly in the clear night sky.',
      difficulty: SentenceDifficulty.easy,
      customTimeLimit: Duration(seconds: 10),
    ),
    SentencePrompt(
      id: 'easy_2',
      text: 'Warm gentle rain falls quietly on green leaves.',
      difficulty: SentenceDifficulty.easy,
      customTimeLimit: Duration(seconds: 12),
    ),
    SentencePrompt(
      id: 'medium_1',
      text: 'The quick brown fox jumps over the lazy dog.',
      difficulty: SentenceDifficulty.medium,
      customTimeLimit: Duration(seconds: 18),
    ),
    SentencePrompt(
      id: 'medium_2',
      text: 'Pack my box with five dozen liquor jugs before noon.',
      difficulty: SentenceDifficulty.medium,
      customTimeLimit: Duration(seconds: 22),
    ),
    SentencePrompt(
      id: 'hard_1',
      text: 'Sphinx of black quartz, judge my vow with steady precision and grace.',
      difficulty: SentenceDifficulty.hard,
      customTimeLimit: Duration(seconds: 28),
    ),
    SentencePrompt(
      id: 'hard_2',
      text: 'Consistent baseline alignment and uniform letter spacing improve legibility.',
      difficulty: SentenceDifficulty.hard,
      customTimeLimit: Duration(seconds: 32),
    ),
  ];
}
