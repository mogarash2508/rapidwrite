import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

import '../models/evaluation_result.dart';
import '../models/stroke_model.dart';

/// Service wrapping `google_mlkit_digital_ink_recognition` for on-device
/// stylus handwriting OCR.
class InkRecognitionService {
  final String languageCode;
  final mlkit.DigitalInkRecognizerModelManager _modelManager =
      mlkit.DigitalInkRecognizerModelManager();
  mlkit.DigitalInkRecognizer? _recognizer;

  bool _isModelReady = false;
  bool _isDownloading = false;
  String? _statusMessage;

  InkRecognitionService({this.languageCode = 'en-US'});

  bool get isModelReady => _isModelReady;
  bool get isDownloading => _isDownloading;
  String? get statusMessage => _statusMessage;

  /// Initializes the Digital Ink recognizer and ensures the on-device BCP-47
  /// model (`en-US`) is downloaded and ready.
  Future<bool> initializeModel() async {
    try {
      _recognizer ??= mlkit.DigitalInkRecognizer(languageCode: languageCode);
      final isDownloaded = await _modelManager.isModelDownloaded(languageCode);
      if (isDownloaded) {
        _isModelReady = true;
        _statusMessage = 'ML Kit Digital Ink model ($languageCode) ready.';
        return true;
      }

      _isDownloading = true;
      _statusMessage = 'Downloading ML Kit Digital Ink model ($languageCode)...';
      final success = await _modelManager.downloadModel(languageCode);
      _isDownloading = false;
      _isModelReady = success;
      _statusMessage = success
          ? 'ML Kit Digital Ink model ($languageCode) downloaded.'
          : 'Unable to download ML Kit model; check network connection.';
      return success;
    } catch (e) {
      _isDownloading = false;
      _isModelReady = false;
      _statusMessage = 'ML Kit initialization warning: $e';
      debugPrint('InkRecognitionService.initializeModel error: $e');
      return false;
    }
  }

  /// Converts our high-precision [StylusStroke] list into an ML Kit [Ink] object
  /// and performs on-device handwriting recognition.
  Future<String> recognizeHandwriting(
    List<StylusStroke> strokes, {
    double canvasWidth = 1024,
    double canvasHeight = 500,
    String? precomputedText,
  }) async {
    if (strokes.isEmpty) {
      return '';
    }

    try {
      if (!_isModelReady) {
        await initializeModel();
      }

      final recognizer =
          _recognizer ?? mlkit.DigitalInkRecognizer(languageCode: languageCode);
      _recognizer = recognizer;

      final ink = mlkit.Ink();
      for (final stylusStroke in strokes) {
        final mlStroke = mlkit.Stroke();
        for (final pt in stylusStroke.points) {
          mlStroke.points.add(
            mlkit.StrokePoint(
              x: pt.x,
              y: pt.y,
              t: pt.timestampMs,
            ),
          );
        }
        if (mlStroke.points.isNotEmpty) {
          ink.strokes.add(mlStroke);
        }
      }

      final context = mlkit.DigitalInkRecognitionContext(
        writingArea: mlkit.WritingArea(
          width: canvasWidth,
          height: canvasHeight,
        ),
        preContext: precomputedText ?? '',
      );

      final candidates = await recognizer.recognize(ink, context: context);
      if (candidates.isNotEmpty) {
        return candidates.first.text.trim();
      }
      return '';
    } catch (e) {
      debugPrint('InkRecognitionService.recognizeHandwriting error: $e');
      return '[On-device ML Kit recognition unavailable: $e]';
    }
  }

  /// Computes Character Accuracy, Word Accuracy, and detailed error counts
  /// (matches, deletions, substitutions, insertions) using Wagner-Fischer dynamic programming.
  TextAccuracyMetrics computeTextAccuracy({
    required String targetSentence,
    required String recognizedText,
  }) {
    final s1 = targetSentence.trim();
    final s2 = recognizedText.trim();
    final m = s1.length;
    final n = s2.length;

    if (m == 0 && n == 0) {
      return const TextAccuracyMetrics(
        overallAccuracyScore: 100.0,
        charAccuracy: 100.0,
        wordAccuracy: 100.0,
        matches: 0,
        deletions: 0,
        substitutions: 0,
        insertions: 0,
      );
    }
    if (m == 0 || n == 0) {
      return TextAccuracyMetrics(
        overallAccuracyScore: 0.0,
        charAccuracy: 0.0,
        wordAccuracy: 0.0,
        matches: 0,
        deletions: m,
        substitutions: 0,
        insertions: n,
      );
    }

    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s1[i - 1].toLowerCase() == s2[j - 1].toLowerCase() ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    int i = m;
    int j = n;
    int matches = 0;
    int substitutions = 0;
    int deletions = 0;
    int insertions = 0;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final isMatch = s1[i - 1].toLowerCase() == s2[j - 1].toLowerCase();
        final cost = isMatch ? 0 : 1;
        if (dp[i][j] == dp[i - 1][j - 1] + cost) {
          if (isMatch) {
            matches++;
          } else {
            substitutions++;
          }
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        deletions++;
        i--;
      } else if (j > 0 && dp[i][j] == dp[i][j - 1] + 1) {
        insertions++;
        j--;
      } else {
        break;
      }
    }

    final totalErrors = deletions + substitutions + (insertions * 0.5);
    final charAccuracy = (((m - totalErrors) / m) * 100.0).clamp(0.0, 100.0);

    final w1 = s1.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final w2 = s2.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final wm = w1.length;
    final wn = w2.length;
    int wordDist = 0;

    if (wm == 0 || wn == 0) {
      wordDist = wm > wn ? wm : wn;
    } else {
      final wdp = List.generate(wm + 1, (_) => List<int>.filled(wn + 1, 0));
      for (int x = 0; x <= wm; x++) {
        wdp[x][0] = x;
      }
      for (int y = 0; y <= wn; y++) {
        wdp[0][y] = y;
      }
      for (int x = 1; x <= wm; x++) {
        for (int y = 1; y <= wn; y++) {
          final wCost = w1[x - 1].toLowerCase() == w2[y - 1].toLowerCase() ? 0 : 1;
          wdp[x][y] = [
            wdp[x - 1][y] + 1,
            wdp[x][y - 1] + 1,
            wdp[x - 1][y - 1] + wCost,
          ].reduce((a, b) => a < b ? a : b);
        }
      }
      wordDist = wdp[wm][wn];
    }

    final maxWords = wm > wn ? wm : wn;
    final wordAccuracy = maxWords > 0
        ? ((1.0 - (wordDist / maxWords)) * 100.0).clamp(0.0, 100.0)
        : 0.0;
    final overallAccuracy = ((charAccuracy * 0.70) + (wordAccuracy * 0.30)).clamp(0.0, 100.0);

    return TextAccuracyMetrics(
      overallAccuracyScore: overallAccuracy,
      charAccuracy: charAccuracy,
      wordAccuracy: wordAccuracy,
      matches: matches,
      deletions: deletions,
      substitutions: substitutions,
      insertions: insertions,
    );
  }

  /// Releases native ML Kit recognizer resources.
  Future<void> dispose() async {
    try {
      await _recognizer?.close();
    } catch (e) {
      debugPrint('Error closing DigitalInkRecognizer: $e');
    }
  }
}
