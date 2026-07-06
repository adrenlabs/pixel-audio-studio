import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renders a waveform from a list of amplitude points.
class WaveformWidget extends StatelessWidget {
  final List<double> samples;   // 0.0 – 1.0 per point
  final Color color;
  final double height;
  final double playheadPosition; // 0.0 – 1.0
  final double? selectionStart;  // 0.0 – 1.0
  final double? selectionEnd;
  final bool filled;

  const WaveformWidget({
    super.key,
    required this.samples,
    this.color = AppColors.waveformActive,
    this.height = 80,
    this.playheadPosition = 0,
    this.selectionStart,
    this.selectionEnd,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _WaveformPainter(
          samples: samples,
          color: color,
          playheadPosition: playheadPosition,
          selectionStart: selectionStart,
          selectionEnd: selectionEnd,
          filled: filled,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final double playheadPosition;
  final double? selectionStart;
  final double? selectionEnd;
  final bool filled;

  const _WaveformPainter({
    required this.samples,
    required this.color,
    required this.playheadPosition,
    required this.selectionStart,
    required this.selectionEnd,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final step = size.width / samples.length;

    // ─── Selection highlight ─────────────────────────────────────────────────
    if (selectionStart != null && selectionEnd != null) {
      final sx = selectionStart! * size.width;
      final ex = selectionEnd! * size.width;
      canvas.drawRect(
        Rect.fromLTRB(sx, 0, ex, size.height),
        Paint()..color = AppColors.selectionFill,
      );
    }

    // ─── Centre line ─────────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()..color = AppColors.border..strokeWidth = 0.5,
    );

    // ─── Waveform ────────────────────────────────────────────────────────────
    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.0);

    if (filled) {
      final path = Path()..moveTo(0, cy);
      for (int i = 0; i < samples.length; i++) {
        final x  = i * step;
        final amp = samples[i].clamp(0.0, 1.0) * cy * 0.9;
        path.lineTo(x, cy - amp);
      }
      path.lineTo(size.width, cy);
      for (int i = samples.length - 1; i >= 0; i--) {
        final x   = i * step;
        final amp = samples[i].clamp(0.0, 1.0) * cy * 0.9;
        path.lineTo(x, cy + amp);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color.withOpacity(0.18));

      // Mirror outline
      final outline = Path()..moveTo(0, cy);
      for (int i = 0; i < samples.length; i++) {
        final x   = i * step;
        final amp = samples[i].clamp(0.0, 1.0) * cy * 0.9;
        if (i == 0) {
          outline.moveTo(x, cy - amp);
        } else {
          outline.lineTo(x, cy - amp);
        }
      }
      canvas.drawPath(outline, Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke);
      final outlineBot = Path();
      for (int i = 0; i < samples.length; i++) {
        final x   = i * step;
        final amp = samples[i].clamp(0.0, 1.0) * cy * 0.9;
        if (i == 0) {
          outlineBot.moveTo(x, cy + amp);
        } else {
          outlineBot.lineTo(x, cy + amp);
        }
      }
      canvas.drawPath(outlineBot, Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke);
    } else {
      final path = Path();
      for (int i = 0; i < samples.length; i++) {
        final x = i * step;
        final amp = samples[i].clamp(0.0, 1.0) * cy * 0.9;
        if (i == 0) {
          path.moveTo(x, cy - amp);
        } else {
          path.lineTo(x, cy - amp);
        }
      }
      canvas.drawPath(path, wavePaint);
    }

    // ─── Playhead ────────────────────────────────────────────────────────────
    final px = playheadPosition * size.width;
    canvas.drawLine(
      Offset(px, 0),
      Offset(px, size.height),
      Paint()
        ..color = AppColors.playhead
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Playhead triangle
    final tri = Path()
      ..moveTo(px - 5, 0)
      ..lineTo(px + 5, 0)
      ..lineTo(px, 8)
      ..close();
    canvas.drawPath(tri, Paint()..color = AppColors.playhead);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.playheadPosition != playheadPosition ||
      old.samples != samples ||
      old.selectionStart != selectionStart;
}

/// Mini waveform thumbnail for clips in the timeline.
class WaveformThumbnail extends StatelessWidget {
  final List<double> samples;
  final Color color;
  final double height;

  const WaveformThumbnail({
    super.key,
    required this.samples,
    required this.color,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _ThumbnailPainter(samples: samples, color: color),
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  const _ThumbnailPainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final cy   = size.height / 2;
    final step = size.width / samples.length;
    final path = Path()..moveTo(0, cy);
    for (int i = 0; i < samples.length; i++) {
      final x   = i * step;
      final amp = samples[i].clamp(0.0, 1.0) * cy * 0.85;
      path.lineTo(x, cy - amp);
    }
    for (int i = samples.length - 1; i >= 0; i--) {
      final x   = i * step;
      final amp = samples[i].clamp(0.0, 1.0) * cy * 0.85;
      path.lineTo(x, cy + amp);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.5));
    canvas.drawPath(
      path,
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_ThumbnailPainter old) => old.samples != samples;
}
