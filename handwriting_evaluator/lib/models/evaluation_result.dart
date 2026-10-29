import 'dart:typed_data';

/// Physical writing speed metrics computed strictly from stylus kinematics:
/// Writing Duration = T_last stroke - T_first stroke
/// completely independent of text accuracy or target sentence length.
class WritingSpeedMetrics {
  /// Exact timestamp when the first stylus stroke touched the canvas (T_first stroke).
  final DateTime startTime;

  /// Exact timestamp when the user tapped the Stop/Submit button.
  final DateTime endTime;

  /// Exact timestamp when the final stylus stroke was lifted (T_last stroke).
  final DateTime lastStrokeTime;

  /// Actual writing duration computed via formula:
  /// Writing Duration = T_last stroke - T_first stroke
  final double writingDurationSeconds;

  /// Total elapsed wall-clock time from first stroke to submission (seconds).
  final double totalElapsedSeconds;

  /// Cumulative time the stylus tip was actively in contact with the screen (seconds).
  final double activePenDownSeconds;

  /// Total physical path distance drawn across all strokes (logical pixels).
  final double totalPathLengthPx;

  /// Estimated physical path distance in millimeters (assuming standard ~160 lpi).
  final double totalPathLengthMm;

  /// Overall stroke velocity across actual writing duration (pixels per second).
  final double overallVelocityPxPerSec;

  /// Active pen-down stroke velocity (pixels per second while moving on surface).
  final double activeStrokeVelocityPxPerSec;

  /// Physical velocity in millimeters per second.
  final double velocityMmPerSec;

  /// Spatial bounding-box coverage area rate (square pixels per second).
  final double spatialCoveragePx2PerSec;

  /// Total number of discrete stylus strokes recorded.
  final int strokeCount;

  /// Average strokes drawn per second.
  final double strokesPerSecond;

  /// Production rate in Characters Per Minute.
  final double cpm;

  /// Production rate in Words Per Minute.
  final double wpm;

  /// Task completion ratio [0.0 - 1.0] of written/recognized characters vs prompt.
  final double completionRatio;

  /// Target speed benchmark for prompt difficulty (e.g. 70 Easy, 100 Medium, 130 Hard).
  final double benchmarkCpm;

  /// Count of valid characters actually written.
  final int writtenCharsCount;

  /// Total character length of target prompt.
  final int targetCharCount;

  /// Multi-factor calibrated overall Speed Score [0.0 - 100.0] scaled by completion ratio.
  final double speedScore;

  /// Production rate score component [0.0 - 100.0] against benchmark.
  final double cpmScore;

  /// Physical velocity score component [0.0 - 100.0].
  final double velocityScore;

  /// Rhythm and pause efficiency score component [0.0 - 100.0].
  final double fluencyScore;

  /// Descriptive grade label for the speed score.
  final String speedGradeLabel;

  const WritingSpeedMetrics({
    required this.startTime,
    required this.endTime,
    required this.lastStrokeTime,
    required this.writingDurationSeconds,
    required this.totalElapsedSeconds,
    required this.activePenDownSeconds,
    required this.totalPathLengthPx,
    required this.totalPathLengthMm,
    required this.overallVelocityPxPerSec,
    required this.activeStrokeVelocityPxPerSec,
    required this.velocityMmPerSec,
    required this.spatialCoveragePx2PerSec,
    required this.strokeCount,
    required this.strokesPerSecond,
    required this.cpm,
    required this.wpm,
    required this.completionRatio,
    required this.benchmarkCpm,
    required this.writtenCharsCount,
    required this.targetCharCount,
    required this.speedScore,
    required this.cpmScore,
    required this.velocityScore,
    required this.fluencyScore,
    required this.speedGradeLabel,
  });

  /// Human-readable speed tier based on physical stylus velocity.
  String get paceClassification {
    if (velocityMmPerSec >= 38.0) return 'Rapid / Fluent';
    if (velocityMmPerSec >= 20.0) return 'Steady / Balanced';
    if (velocityMmPerSec > 0.0) return 'Deliberate / Careful';
    return 'No Strokes Recorded';
  }
}

/// Detailed text accuracy metrics comparing recognized handwriting against reference sentence.
class TextAccuracyMetrics {
  /// Overall composite accuracy score [0 - 100].
  final double overallAccuracyScore;

  /// Character-level accuracy [0 - 100].
  final double charAccuracy;

  /// Word-level accuracy [0 - 100].
  final double wordAccuracy;

  /// Exact character matches.
  final int matches;

  /// Missing characters from prompt (deletions).
  final int deletions;

  /// Incorrect characters (substitutions).
  final int substitutions;

  /// Additional characters (insertions).
  final int insertions;

  const TextAccuracyMetrics({
    required this.overallAccuracyScore,
    required this.charAccuracy,
    required this.wordAccuracy,
    required this.matches,
    required this.deletions,
    required this.substitutions,
    required this.insertions,
  });
}

/// Holistic visual and aesthetic evaluation of the handwritten canvas snapshot.
class HolisticAestheticScore {
  /// Composite aesthetic & neatness score in range [0, 100].
  final double overallScore;

  /// Baseline straightness and horizontal stability score [0, 100].
  final double baselineAlignmentScore;

  /// Consistency of stroke slant and vertical rhythm [0, 100].
  final double slantConsistencyScore;

  /// Spatial balance, margins, and inter-word/letter spacing [0, 100].
  final double spacingBalanceScore;

  /// Visual clarity, stroke pressure smoothness, and form legibility [0, 100].
  final double visualLegibilityScore;

  /// Formation smoothness score [0, 100] reflecting tremor/jerkiness.
  final double formationScore;

  /// Holistic qualitative feedback generated from the canvas image + strokes.
  final String qualitativeFeedback;

  /// Source of the aesthetic evaluation ('Vision AI Endpoint' or 'On-Device Visual & Geometric Analyzer').
  final String evaluationSource;

  const HolisticAestheticScore({
    required this.overallScore,
    required this.baselineAlignmentScore,
    required this.slantConsistencyScore,
    required this.spacingBalanceScore,
    required this.visualLegibilityScore,
    this.formationScore = 80.0,
    required this.qualitativeFeedback,
    required this.evaluationSource,
  });

  String get gradeLabel {
    if (overallScore >= 90) return 'Exemplary Calligraphic Neatness';
    if (overallScore >= 80) return 'Clean & Highly Legible';
    if (overallScore >= 70) return 'Good Structural Consistency';
    if (overallScore >= 55) return 'Developing Neatness';
    return 'Needs Baseline & Spacing Practice';
  }
}

/// Complete evaluation payload combining speed metrics, aesthetic analysis,
/// ML Kit OCR output, and canvas snapshot bytes.
class HandwritingEvaluationResult {
  final String targetSentence;
  final String recognizedOcrText;
  final bool didSentenceAutoDisappear;
  final Duration allocatedSentenceTime;
  final WritingSpeedMetrics speedMetrics;
  final HolisticAestheticScore aestheticScore;
  final TextAccuracyMetrics accuracyMetrics;
  final Uint8List? canvasSnapshotPng;
  final int rejectedPalmTouches;

  const HandwritingEvaluationResult({
    required this.targetSentence,
    required this.recognizedOcrText,
    required this.didSentenceAutoDisappear,
    required this.allocatedSentenceTime,
    required this.speedMetrics,
    required this.aestheticScore,
    required this.accuracyMetrics,
    required this.canvasSnapshotPng,
    required this.rejectedPalmTouches,
  });
}
}
