import 'dart:math' as math;
import 'dart:ui';

/// A single high-precision sample point captured from an active stylus event.
class StylusPoint {
  /// Canvas-local X coordinate in logical pixels.
  final double x;

  /// Canvas-local Y coordinate in logical pixels.
  final double y;

  /// Epoch timestamp in milliseconds when this sample was recorded.
  final int timestampMs;

  /// Normalized stylus pressure in range [0.0, 1.0].
  final double pressure;

  /// Stylus tilt angle in radians [0.0, pi/2].
  final double tilt;

  /// Stylus azimuthal orientation in radians.
  final double orientation;

  const StylusPoint({
    required this.x,
    required this.y,
    required this.timestampMs,
    this.pressure = 0.5,
    this.tilt = 0.0,
    this.orientation = 0.0,
  });

  Offset get offset => Offset(x, y);

  /// Euclidean distance in logical pixels to another [StylusPoint].
  double distanceTo(StylusPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// A continuous stylus stroke from [PointerDownEvent] to [PointerUpEvent].
class StylusStroke {
  final int pointerId;
  final List<StylusPoint> points;
  final int startTimeMs;
  int endTimeMs;

  StylusStroke({
    required this.pointerId,
    required List<StylusPoint> initialPoints,
    required this.startTimeMs,
    required this.endTimeMs,
  }) : points = List<StylusPoint>.from(initialPoints);

  /// Total physical length of this stroke in logical pixels.
  double get lengthInPixels {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += points[i - 1].distanceTo(points[i]);
    }
    return total;
  }

  /// Duration of this individual stroke in milliseconds.
  int get durationMs => math.max(1, endTimeMs - startTimeMs);

  /// Bounding box enclosing all points in this stroke.
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
