import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// A rotary knob widget mimicking hardware studio gear.
class StudioKnob extends StatefulWidget {
  final double value;         // 0.0 – 1.0
  final ValueChanged<double> onChanged;
  final Color color;
  final String label;
  final String? valueLabel;
  final double size;

  const StudioKnob({
    super.key,
    required this.value,
    required this.onChanged,
    this.color = AppColors.neonBlue,
    this.label = '',
    this.valueLabel,
    this.size = 52,
  });

  @override
  State<StudioKnob> createState() => _StudioKnobState();
}

class _StudioKnobState extends State<StudioKnob> {
  static const double _minAngle = -140 * math.pi / 180;
  static const double _maxAngle =  140 * math.pi / 180;
  static const double _dragSensitivity = 0.005;

  double _startValue = 0;
  double _startDy    = 0;

  double get _angle =>
      _minAngle + (_maxAngle - _minAngle) * widget.value;

  void _onPanStart(DragStartDetails d) {
    _startValue = widget.value;
    _startDy    = d.localPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final delta = (_startDy - d.localPosition.dy) * _dragSensitivity;
    final next  = (_startValue + delta).clamp(0.0, 1.0);
    if (next != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _KnobPainter(
                angle: _angle,
                color: widget.color,
                value: widget.value,
              ),
            ),
          ),
        ),
        if (widget.valueLabel != null || widget.label.isNotEmpty) ...[
          const SizedBox(height: 3),
          if (widget.valueLabel != null)
            Text(
              widget.valueLabel!,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 9,
                color: widget.color,
                letterSpacing: 0.8,
              ),
            ),
          if (widget.label.isNotEmpty)
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
        ],
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double angle;
  final Color color;
  final double value;

  const _KnobPainter({
    required this.angle,
    required this.color,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 3;

    // ─── Arc track ──────────────────────────────────────────────────────────
    const startAngle = -140 * math.pi / 180;
    const sweepAngle =  280 * math.pi / 180;
    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - 2),
      startAngle + math.pi / 2,
      sweepAngle,
      false,
      trackPaint,
    );

    // ─── Value arc ──────────────────────────────────────────────────────────
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - 2),
      startAngle + math.pi / 2,
      sweepAngle * value,
      false,
      valuePaint,
    );

    // ─── Knob body ──────────────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.surfaceLight, AppColors.surfaceDark],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r - 6));
    canvas.drawCircle(Offset(cx, cy), r - 6, bodyPaint);

    // ─── Border ─────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r - 6,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ─── Indicator line ─────────────────────────────────────────────────────
    final actualAngle = angle + math.pi / 2;
    final innerR = r - 12;
    final outerR = r - 7;
    final ix = cx + innerR * math.cos(actualAngle);
    final iy = cy + innerR * math.sin(actualAngle);
    final ox = cx + outerR * math.cos(actualAngle);
    final oy = cy + outerR * math.sin(actualAngle);

    canvas.drawLine(
      Offset(ix, iy),
      Offset(ox, oy),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      old.angle != angle || old.color != color || old.value != value;
}
