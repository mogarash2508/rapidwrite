import 'dart:math' as math;
import 'dart:ui';

import '../models/evaluation_result.dart';
import '../models/stroke_model.dart';

/// Independent Writing Speed Calculator.
///
/// Measures physical writing kinematics strictly between:
/// - `startTime`: The exact millisecond the first active stylus `PointerDown` is registered.
/// - `endTime`: The exact millisecond the user taps the "Submit / Analyze" button.
///
/// Calculations are 100% independent of target sentence accuracy or OCR text matching.
class SpeedCalculatorService {
  /// Standard logical-pixel-to-millimeter conversion factor (~160 logical DPI = 6.299 px/mm).
  static const double _logicalPixelsPerMillimeter = 6.2992;

  DateTime? _startTime;
  DateTime? _endTime;

  /// Timestamp of the first active stylus stroke, if started.
  DateTime? get startTime => _startTime;

  /// Timestamp when Submit was pressed, if stopped.
  DateTime? get endTime => _endTime;

  /// Whether the session timer has been triggered by an initial stylus stroke.
  bool get isRunning => _startTime != null && _endTime == null;

  /// Registers the exact millisecond of the first active stylus `PointerDownEvent`.
  /// Subsequent strokes in the same session do not overwrite `_startTime`.
  void onFirstStylusStrokeDown([DateTime? timestamp]) {
    _startTime ??= timestamp ?? DateTime.now();
    _endTime = null;
  }

  /// Stops the writing speed timer when the user taps "Submit / Analyze".
  DateTime stopOnSubmit([DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now();
    _startTime ??= now;
    _endTime = now;
    return now;
  }

  /// Resets the speed calculator for a new sentence or cleared canvas.
  void reset() {
    _startTime = null;
    _endTime = null;
  }

  /// Computes physical writing speed metrics and multi-factor speed score
  /// from the captured stylus strokes and the [`startTime`, `endTime`] window.
  WritingSpeedMetrics computeMetrics(
    List<StylusStroke> strokes, {
    int targetCharCount = 45,
    int targetWordCount = 9,
    int? writtenCharsCount,
    double benchmarkCpm = 100.0,
  }) {
    final effectiveStart = _startTime ?? DateTime.now();
    final effectiveEnd = _endTime ?? DateTime.now();

    final elapsedMs = math.max(
      1,
      effectiveEnd.difference(effectiveStart).inMilliseconds,
    );
    final totalElapsedSeconds = elapsedMs / 1000.0;

    if (strokes.isEmpty) {
      return WritingSpeedMetrics(
        startTime: effectiveStart,
        endTime: effectiveEnd,
        lastStrokeTime: effectiveEnd,
        writingDurationSeconds: totalElapsedSeconds,
        totalElapsedSeconds: totalElapsedSeconds,
        activePenDownSeconds: 0.0,
        totalPathLengthPx: 0.0,
        totalPathLengthMm: 0.0,
        overallVelocityPxPerSec: 0.0,
        activeStrokeVelocityPxPerSec: 0.0,
        velocityMmPerSec: 0.0,
        spatialCoveragePx2PerSec: 0.0,
        strokeCount: 0,
        strokesPerSecond: 0.0,
        cpm: 0.0,
        wpm: 0.0,
        completionRatio: 0.0,
        benchmarkCpm: benchmarkCpm,
        writtenCharsCount: 0,
        targetCharCount: targetCharCount,
        speedScore: 0.0,
        cpmScore: 0.0,
        velocityScore: 0.0,
        fluencyScore: 0.0,
        speedGradeLabel: 'No Strokes Recorded',
      );
    }

    // Formula: Writing Duration = T_last stroke - T_first stroke
    final tFirstStroke = effectiveStart;
    final lastStroke = strokes.last;
    final tLastStroke = DateTime.fromMillisecondsSinceEpoch(lastStroke.endTimeMs);
    final writingDurationMs = math.max(1, tLastStroke.difference(tFirstStroke).inMilliseconds);
    final writingDurationSeconds = writingDurationMs / 1000.0;

    double totalPathPx = 0.0;
    int totalPenDownMs = 0;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      totalPathPx += stroke.lengthInPixels;
      totalPenDownMs += stroke.durationMs;

      final box = stroke.boundingBox;
      if (!box.isEmpty) {
        if (box.left < minX) minX = box.left;
        if (box.right > maxX) maxX = box.right;
        if (box.top < minY) minY = box.top;
        if (box.bottom > maxY) maxY = box.bottom;
      }
    }

    final activePenDownSeconds = math.max(0.01, totalPenDownMs / 1000.0);
    final totalPathMm = totalPathPx / _logicalPixelsPerMillimeter;

    // Stroke velocity computed strictly from the actual Writing Duration (T_last - T_first)
    final overallVelocityPxPerSec = totalPathPx / writingDurationSeconds;
    final activeStrokeVelocityPxPerSec = totalPathPx / activePenDownSeconds;
    final velocityMmPerSec = totalPathMm / writingDurationSeconds;
    final activeTipVelMmPerSec = totalPathMm / activePenDownSeconds;

    // Spatial coverage area rate (bounding box of written ink per second)
    double boundingAreaPx2 = 0.0;
    if (minX.isFinite && maxX.isFinite && minY.isFinite && maxY.isFinite) {
      final width = math.max(1.0, maxX - minX);
      final height = math.max(1.0, maxY - minY);
      boundingAreaPx2 = width * height;
    }
    final spatialCoveragePx2PerSec = boundingAreaPx2 / writingDurationSeconds;

    // Actual written character count & completion ratio
    final validWrittenCount = writtenCharsCount ?? math.min(targetCharCount, (strokes.length * 0.75).round());
    final completionRatio = (validWrittenCount / math.max(1, targetCharCount)).clamp(0.0, 1.0);

    // Production rates based on actual text written
    final actualCpm = (validWrittenCount / writingDurationSeconds) * 60.0;
    final actualWpm = actualCpm / 5.0;
    final penDownRatio = (activePenDownSeconds / writingDurationSeconds * 100.0).clamp(0.0, 100.0);

    // Pacing against difficulty benchmark
    final pacingRatio = actualCpm / math.max(1.0, benchmarkCpm);
    final pacingScore = pacingRatio >= 1.0
        ? math.min(100.0, 85.0 + math.min(15.0, (pacingRatio - 1.0) * 45.0))
        : math.max(5.0, pacingRatio * 85.0);

    // Physical Tip Velocity Score (Proficient standard is 34-38 mm/s)
    final velocityScore = (activeTipVelMmPerSec / 36.0 * 90.0).clamp(10.0, 100.0);

    // Rhythm & Pause Fluency Score (Ideal pen-down ratio is 62-75%)
    final fluencyPenalty = (penDownRatio - 68.0).abs() * 1.8;
    final fluencyScore = (100.0 - fluencyPenalty).clamp(10.0, 100.0);

    // Composite raw score
    final rawSpeedScore = (pacingScore * 0.50) + (velocityScore * 0.30) + (fluencyScore * 0.20);

    // CRITICAL: Scale speed score by task completion so incomplete writing is NOT rewarded!
    final speedScore = (rawSpeedScore * math.pow(completionRatio, 1.25)).clamp(0.0, 100.0);

    String speedGradeLabel = 'Fluent & Efficient Pace';
    if (speedScore >= 90) {
      speedGradeLabel = 'Exceptional / Rapid Fluidity';
    } else if (speedScore >= 78) {
      speedGradeLabel = 'Fluent & Efficient Pace';
    } else if (speedScore >= 65) {
      speedGradeLabel = 'Steady & Consistent Pace';
    } else if (speedScore >= 45) {
      speedGradeLabel = 'Moderate / Developing Pace';
    } else {
      speedGradeLabel = 'Incomplete / Needs Pacing Practice';
    }

    return WritingSpeedMetrics(
      startTime: tFirstStroke,
      endTime: effectiveEnd,
      lastStrokeTime: tLastStroke,
      writingDurationSeconds: writingDurationSeconds,
      totalElapsedSeconds: totalElapsedSeconds,
      activePenDownSeconds: activePenDownSeconds,
      totalPathLengthPx: totalPathPx,
      totalPathLengthMm: totalPathMm,
      overallVelocityPxPerSec: overallVelocityPxPerSec,
      activeStrokeVelocityPxPerSec: activeStrokeVelocityPxPerSec,
      velocityMmPerSec: velocityMmPerSec,
      spatialCoveragePx2PerSec: spatialCoveragePx2PerSec,
      strokeCount: strokes.length,
      strokesPerSecond: strokes.length / writingDurationSeconds,
      cpm: actualCpm,
      wpm: actualWpm,
      completionRatio: completionRatio,
      benchmarkCpm: benchmarkCpm,
      writtenCharsCount: validWrittenCount,
      targetCharCount: targetCharCount,
      speedScore: speedScore,
      cpmScore: pacingScore,
      velocityScore: velocityScore,
      fluencyScore: fluencyScore,
      speedGradeLabel: speedGradeLabel,
    );
  }
}
