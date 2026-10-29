import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../models/evaluation_result.dart';
import '../models/sentence_prompt.dart';
import '../models/stroke_model.dart';
import '../services/aesthetic_evaluation_service.dart';
import '../services/ink_recognition_service.dart';
import '../services/speed_calculator_service.dart';
import '../widgets/results_dashboard.dart';
import '../widgets/sentence_prompt_banner.dart';
import '../widgets/stylus_canvas.dart';

/// Main Tablet-Optimized Screen for Stylus Handwriting Analysis & Evaluation.
/// 
/// Fulfills all 5 Architectural Requirements:
/// 1. UI Matching Reference: Dark sleek theme, Aurora Ink styling, modern cards.
/// 2. Google Digital Ink ML Kit: High-fidelity recognition on tablet.
/// 3. Reposition Menu & Timer Controls: Both placed at the TOP; no start menu at bottom!
/// 4. Streamlined Dashboard: 3 clean cards (Speed, Accuracy, Aesthetic) + recognized text.
/// 5. Stylus Writing segregated from Touch Scrolling: Finger gestures vertically scroll.
class HandwritingEvaluatorScreen extends StatefulWidget {
  const HandwritingEvaluatorScreen({super.key});

  @override
  State<HandwritingEvaluatorScreen> createState() =>
      _HandwritingEvaluatorScreenState();
}

class _HandwritingEvaluatorScreenState
    extends State<HandwritingEvaluatorScreen> {
  final List<SentencePrompt> _prompts = SentencePrompt.defaultPrompts;
  late SentencePrompt _activePrompt;

  final ScreenshotController _screenshotController = ScreenshotController();
  final SpeedCalculatorService _speedCalculator = SpeedCalculatorService();
  final InkRecognitionService _inkRecognitionService = InkRecognitionService();
  final AestheticEvaluationService _aestheticService =
      const AestheticEvaluationService();

  final List<StylusStroke> _strokes = [];
  Size _canvasSize = const Size(1024, 600);

  // Timer State
  Timer? _sentenceVisibilityTimer;
  Timer? _liveElapsedTimer;
  late Duration _remainingSentenceTime;
  Duration _elapsedTime = Duration.zero;
  DateTime? _firstStrokeTime;

  bool _isSessionArmed = true; // Always armed and ready for instant writing
  bool _hasFirstStrokeStarted = false;
  bool _isSentenceExpired = false;

  // Palm rejection & UI controls
  int _rejectedPalmTouches = 0;
  bool _strictStylusOnly = true;
  bool _showRuledLines = true;
  bool _isSubmitting = false;

  // Results Dashboard State
  HandwritingEvaluationResult? _evaluationResult;
  bool _isResultsVisible = false;

  @override
  void initState() {
    super.initState();
    _activePrompt = _prompts.first;
    _remainingSentenceTime = _activePrompt.fixedTimeLimit;

    // Warm up Google ML Kit Digital Ink Recognition model
    _inkRecognitionService.initializeModel().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sentenceVisibilityTimer?.cancel();
    _liveElapsedTimer?.cancel();
    _inkRecognitionService.dispose();
    super.dispose();
  }

  /// Step 2 & 3: Triggered on first stylus stroke down.
  /// Timer starts automatically when student's first pen stroke is detected.
  void _onFirstStylusStrokeRegistered() {
    if (_hasFirstStrokeStarted) return;

    final firstStrokeTime = DateTime.now();
    _firstStrokeTime = firstStrokeTime;

    _speedCalculator.onFirstStylusStrokeDown(firstStrokeTime);

    setState(() {
      _hasFirstStrokeStarted = true;
      _isSentenceExpired = false;
      _remainingSentenceTime = _activePrompt.fixedTimeLimit;
    });

    // 1. Live elapsed timer at top
    _liveElapsedTimer?.cancel();
    _liveElapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(firstStrokeTime);
        });
      }
    });

    // 2. Fixed countdown timer for sentence auto-disappearance
    final totalAllocatedMs = _activePrompt.fixedTimeLimit.inMilliseconds;
    _sentenceVisibilityTimer?.cancel();
    _sentenceVisibilityTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        final elapsedMs =
            DateTime.now().difference(firstStrokeTime).inMilliseconds;
        final remainingMs = totalAllocatedMs - elapsedMs;

        if (remainingMs <= 0) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _remainingSentenceTime = Duration.zero;
              _isSentenceExpired = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _remainingSentenceTime = Duration(milliseconds: remainingMs);
            });
          }
        }
      },
    );
  }

  void _selectSentencePrompt(SentencePrompt newPrompt) {
    _sentenceVisibilityTimer?.cancel();
    _liveElapsedTimer?.cancel();
    _speedCalculator.reset();
    setState(() {
      _activePrompt = newPrompt;
      _remainingSentenceTime = newPrompt.fixedTimeLimit;
      _hasFirstStrokeStarted = false;
      _isSentenceExpired = false;
      _strokes.clear();
      _rejectedPalmTouches = 0;
      _evaluationResult = null;
      _isResultsVisible = false;
      _elapsedTime = Duration.zero;
      _firstStrokeTime = null;
    });
  }

  void _clearCanvas() {
    _sentenceVisibilityTimer?.cancel();
    _liveElapsedTimer?.cancel();
    _speedCalculator.reset();
    setState(() {
      _strokes.clear();
      _hasFirstStrokeStarted = false;
      _isSentenceExpired = false;
      _remainingSentenceTime = _activePrompt.fixedTimeLimit;
      _rejectedPalmTouches = 0;
      _evaluationResult = null;
      _isResultsVisible = false;
      _elapsedTime = Duration.zero;
      _firstStrokeTime = null;
    });
  }

  Future<void> _submitAndAnalyze() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write on the canvas with your stylus before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _sentenceVisibilityTimer?.cancel();
    _liveElapsedTimer?.cancel();
    _speedCalculator.stopOnSubmit(DateTime.now());

    setState(() {
      _isSubmitting = true;
    });

    try {
      Uint8List? snapshotPng;
      try {
        snapshotPng = await _screenshotController.capture(
          pixelRatio: 2.5,
          delay: const Duration(milliseconds: 20),
        );
      } catch (e) {
        debugPrint('Snapshot capture notice: $e');
      }

      // Google ML Kit Digital Ink Recognition
      final recognizedText = await _inkRecognitionService.recognizeHandwriting(
        _strokes,
        canvasWidth: _canvasSize.width,
        canvasHeight: _canvasSize.height,
      );

      final accuracyMetrics = _inkRecognitionService.computeTextAccuracy(
        targetSentence: _activePrompt.text,
        recognizedText: recognizedText,
      );

      final speedMetrics = _speedCalculator.computeMetrics(
        _strokes,
        targetCharCount: _activePrompt.text.trim().length,
        targetWordCount: _activePrompt.text.trim().split(RegExp(r'\s+')).length,
        writtenCharsCount: recognizedText.trim().length,
        benchmarkCpm: _activePrompt.difficulty.benchmarkCpm,
      );

      final aestheticScore = await _aestheticService.evaluateHandwritingAesthetics(
        canvasPngBytes: snapshotPng,
        strokes: _strokes,
        recognizedText: recognizedText,
        targetSentence: _activePrompt.text,
        canvasSize: _canvasSize,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isResultsVisible = true;
        _evaluationResult = HandwritingEvaluationResult(
          targetSentence: _activePrompt.text,
          recognizedOcrText: recognizedText,
          didSentenceAutoDisappear: _isSentenceExpired,
          allocatedSentenceTime: _activePrompt.fixedTimeLimit,
          speedMetrics: speedMetrics,
          aestheticScore: aestheticScore,
          accuracyMetrics: accuracyMetrics,
          canvasSnapshotPng: snapshotPng,
          rejectedPalmTouches: _rejectedPalmTouches,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis error: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _cycleToNextPrompt() {
    final currentIndex =
        _prompts.indexWhere((element) => element.id == _activePrompt.id);
    final nextIndex = (currentIndex + 1) % _prompts.length;
    _selectSentencePrompt(_prompts[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final timerText = _hasFirstStrokeStarted
        ? '${(_elapsedTime.inMilliseconds / 1000.0).toStringAsFixed(1)}s'
        : '00:00.0';

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Text('✦', style: TextStyle(fontSize: 12, color: Colors.white)),
                  SizedBox(width: 4),
                  Text(
                    'Aurora Ink',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stylus Handwriting Evaluator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Tablet-optimized calligraphy & kinematics assessment',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Live Countdown / Elapsed Timer placed at TOP RIGHT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1F10B981),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF34D399), size: 16),
                const SizedBox(width: 6),
                Text(
                  timerText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF34D399),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() => _showRuledLines = !_showRuledLines);
            },
            icon: Icon(
              Icons.view_headline_rounded,
              color: _showRuledLines ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
            ),
            tooltip: 'Toggle Ruled Lines',
          ),
          const SizedBox(width: 16),
        ],
      ),
      // SingleChildScrollView allows natural vertical touch scrolling!
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP PROMPT BANNER
              SentencePromptBanner(
                prompts: _prompts,
                activePrompt: _activePrompt,
                hasTimerStarted: _hasFirstStrokeStarted,
                isSentenceExpired: _isSentenceExpired,
                remainingTime: _remainingSentenceTime,
                onSelectPrompt: _selectSentencePrompt,
              ),

              const SizedBox(height: 12),

              // 2. STREAMLINED RESULT ANALYSIS DASHBOARD (When Submitted)
              if (_isResultsVisible && _evaluationResult != null) ...[
                ResultsDashboard(
                  result: _evaluationResult!,
                  onNextSentence: _cycleToNextPrompt,
                  onClose: () => setState(() => _isResultsVisible = false),
                ),
                const SizedBox(height: 12),
              ],

              // 3. TOP ACTION BAR (Positioned ABOVE Canvas - No menu at bottom!)
              _buildTopActionBar(),

              const SizedBox(height: 12),

              // 4. NOTEPAD CANVAS (Clean writing area, no menu at bottom)
              SizedBox(
                height: 560,
                child: StylusCanvas(
                  screenshotController: _screenshotController,
                  strokes: _strokes,
                  strictStylusOnly: _strictStylusOnly,
                  showRuledLines: _showRuledLines,
                  onFirstStylusStroke: _onFirstStylusStrokeRegistered,
                  onStrokeCompleted: (stroke) {
                    setState(() {
                      _strokes.add(stroke);
                    });
                  },
                  onPalmTouchRejected: () {
                    setState(() {
                      _rejectedPalmTouches++;
                    });
                  },
                  onCanvasSizeChanged: (size) {
                    _canvasSize = size;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Action Bar (Placed ABOVE the notepad canvas)
  Widget _buildTopActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _clearCanvas,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Clear Canvas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFCA5A5),
                  side: const BorderSide(color: Color(0x66EF4444)),
                  backgroundColor: const Color(0x1FEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_strokes.length} strokes • ${(_elapsedTime.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            children: [
              if (_evaluationResult != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isResultsVisible = !_isResultsVisible);
                  },
                  icon: Icon(
                    _isResultsVisible ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(_isResultsVisible ? 'Hide Results' : 'Show Results'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCBD5E1),
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitAndAnalyze,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rocket_launch_rounded, size: 16),
                label: Text(_isSubmitting ? 'Analyzing...' : 'Submit & Analyze'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
