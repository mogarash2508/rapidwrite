import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../models/stroke_model.dart';

/// Center Section of the Tablet UI:
/// A large, responsive, border-framed drawing canvas dedicated to stylus input
/// with strict palm rejection and high-resolution snapshot capture.
class StylusCanvas extends StatefulWidget {
  final ScreenshotController screenshotController;
  final List<StylusStroke> strokes;
  final bool strictStylusOnly;
  final bool showRuledLines;
  final VoidCallback onFirstStylusStroke;
  final ValueChanged<StylusStroke> onStrokeCompleted;
  final VoidCallback onPalmTouchRejected;
  final ValueChanged<Size>? onCanvasSizeChanged;

  const StylusCanvas({
    super.key,
    required this.screenshotController,
    required this.strokes,
    required this.strictStylusOnly,
    required this.showRuledLines,
    required this.onFirstStylusStroke,
    required this.onStrokeCompleted,
    required this.onPalmTouchRejected,
    this.onCanvasSizeChanged,
  });

  @override
  State<StylusCanvas> createState() => _StylusCanvasState();
}

class _StylusCanvasState extends State<StylusCanvas> {
  StylusStroke? _currentActiveStroke;
  int? _activeStylusPointerId;
  Offset? _hoverPosition;

  /// Strict Palm Rejection Filter:
  /// Accepts ONLY active stylus events (`PointerDeviceKind.stylus` and
  /// `PointerDeviceKind.invertedStylus`).
  /// All finger, palm, and multi-touch resting hand inputs (`PointerDeviceKind.touch`)
  /// are completely rejected.
  bool _isAllowedStylusInput(PointerEvent event) {
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      return true;
    }
    // Optional fallback only when developer explicitly disables strictStylusOnly
    // for desktop mouse testing. Finger/palm touch (`PointerDeviceKind.touch`)
    // is ALWAYS rejected when strictStylusOnly is true.
    if (!widget.strictStylusOnly && event.kind == PointerDeviceKind.mouse) {
      return true;
    }
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isAllowedStylusInput(event)) {
      // Reject accidental palm or finger touch
      widget.onPalmTouchRejected();
      return;
    }

    // Lock to the first active stylus pointer ID to prevent any stray signal
    if (_activeStylusPointerId != null) return;

    // Trigger both the independent writing speed timer AND the sentence
    // auto-disappearance countdown timer on the very first stylus stroke!
    if (widget.strokes.isEmpty && _currentActiveStroke == null) {
      widget.onFirstStylusStroke();
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final initialPoint = StylusPoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      timestampMs: nowMs,
      pressure: event.pressure.clamp(0.1, 1.0),
      tilt: event.tilt,
      orientation: event.orientation,
    );

    setState(() {
      _activeStylusPointerId = event.pointer;
      _hoverPosition = null;
      _currentActiveStroke = StylusStroke(
        pointerId: event.pointer,
        initialPoints: [initialPoint],
        startTimeMs: nowMs,
        endTimeMs: nowMs,
      );
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isAllowedStylusInput(event)) {
      return;
    }
    if (_activeStylusPointerId != event.pointer ||
        _currentActiveStroke == null) {
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nextPoint = StylusPoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      timestampMs: nowMs,
      pressure: event.pressure.clamp(0.1, 1.0),
      tilt: event.tilt,
      orientation: event.orientation,
    );

    setState(() {
      _currentActiveStroke!.points.add(nextPoint);
      _currentActiveStroke!.endTimeMs = nowMs;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activeStylusPointerId != event.pointer ||
        _currentActiveStroke == null) {
      return;
    }

    final completedStroke = _currentActiveStroke!;
    completedStroke.endTimeMs = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _currentActiveStroke = null;
      _activeStylusPointerId = null;
    });

    widget.onStrokeCompleted(completedStroke);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activeStylusPointerId != event.pointer) return;
    setState(() {
      _currentActiveStroke = null;
      _activeStylusPointerId = null;
    });
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (_isAllowedStylusInput(event)) {
      setState(() {
        _hoverPosition = event.localPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCanvasSizeChanged?.call(canvasSize);
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _activeStylusPointerId != null
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFCBD5E1),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // High-resolution Screenshot capture wrapper around the ink surface
                Screenshot(
                  controller: widget.screenshotController,
                  child: Container(
                    color: const Color(0xFFFCFDFE),
                    child: CustomPaint(
                      painter: _HandwritingCanvasPainter(
                        completedStrokes: widget.strokes,
                        activeStroke: _currentActiveStroke,
                        showRuledLines: widget.showRuledLines,
                        hoverPosition: _hoverPosition,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // Empty-canvas watermark guidance (not included once ink starts)
                if (widget.strokes.isEmpty && _currentActiveStroke == null)
                  IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 48,
                            color: const Color(0xFF94A3B8).withOpacity(0.6),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Write the target sentence here using your Apple Pencil or Android Stylus',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Strict Palm Rejection Active — Rest your hand naturally on the screen',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Raw PointerEvent stream listener for low-latency stylus capture
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: _handlePointerUp,
                  onPointerCancel: _handlePointerCancel,
                  onPointerHover: _handlePointerHover,
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter that renders smooth quadratic Bézier curves with pressure-sensitive
/// stroke width modulation and optional tablet ruled baselines.
class _HandwritingCanvasPainter extends CustomPainter {
  final List<StylusStroke> completedStrokes;
  final StylusStroke? activeStroke;
  final bool showRuledLines;
  final Offset? hoverPosition;

  _HandwritingCanvasPainter({
    required this.completedStrokes,
    required this.activeStroke,
    required this.showRuledLines,
    required this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle ruled handwriting baselines if enabled
    if (showRuledLines) {
      final baselinePaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final dashedMidlinePaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      const double lineSpacing = 76.0;
      for (double y = 76.0; y < size.height - 24.0; y += lineSpacing) {
        // Midline (x-height guide)
        canvas.drawLine(
          Offset(28, y - 28),
          Offset(size.width - 28, y - 28),
          dashedMidlinePaint,
        );
        // Primary baseline
        canvas.drawLine(
          Offset(28, y),
          Offset(size.width - 28, y),
          baselinePaint,
        );
      }
    }

    // 2. Render all completed stylus strokes
    for (final stroke in completedStrokes) {
      _drawStylusStroke(canvas, stroke);
    }

    // 3. Render currently active stroke
    if (activeStroke != null) {
      _drawStylusStroke(canvas, activeStroke!);
    }

    // 4. Optional subtle stylus hover preview indicator
    if (hoverPosition != null && activeStroke == null) {
      final hoverPaint = Paint()
        ..color = const Color(0xFF2563EB).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(hoverPosition!, 4.0, hoverPaint);
    }
  }

  void _drawStylusStroke(Canvas canvas, StylusStroke stroke) {
    final pts = stroke.points;
    if (pts.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (pts.length == 1) {
      final p = pts.first;
      final radius = (1.6 + p.pressure * 2.2).clamp(1.5, 4.2);
      canvas.drawCircle(
        p.offset,
        radius / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Render segmented smooth curves with pressure-modulated stroke widths
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final avgPressure = (prev.pressure + curr.pressure) * 0.5;
      // Modulate width naturally between 1.8px and 4.6px based on stylus tip pressure
      paint.strokeWidth = (1.8 + avgPressure * 2.8).clamp(1.8, 4.6);

      if (i == 1) {
        final mid = Offset(
          (prev.x + curr.x) * 0.5,
          (prev.y + curr.y) * 0.5,
        );
        canvas.drawLine(prev.offset, mid, paint);
      } else {
        final prevPrev = pts[i - 2];
        final prevMid = Offset(
          (prevPrev.x + prev.x) * 0.5,
          (prevPrev.y + prev.y) * 0.5,
        );
        final currMid = Offset(
          (prev.x + curr.x) * 0.5,
          (prev.y + curr.y) * 0.5,
        );
        final path = Path()
          ..moveTo(prevMid.dx, prevMid.dy)
          ..quadraticBezierTo(prev.x, prev.y, currMid.dx, currMid.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingCanvasPainter oldDelegate) {
    return true;
  }
}
