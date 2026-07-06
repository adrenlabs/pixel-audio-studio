import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Vertical LED-style level meter for mixer channels.
class LevelMeter extends StatelessWidget {
  final double level;     // 0.0 – 1.0 (linear amplitude)
  final double peak;      // 0.0 – 1.0
  final double width;
  final double height;
  final bool stereo;
  final double levelR;    // only used when stereo == true
  final double peakR;

  const LevelMeter({
    super.key,
    required this.level,
    this.peak = 0,
    this.width = 12,
    this.height = 100,
    this.stereo = false,
    this.levelR = 0,
    this.peakR = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (stereo) {
      return SizedBox(
        width: width * 2 + 2,
        height: height,
        child: Row(
          children: [
            _SingleMeter(level: level, peak: peak, width: width, height: height),
            const SizedBox(width: 2),
            _SingleMeter(level: levelR, peak: peakR, width: width, height: height),
          ],
        ),
      );
    }
    return _SingleMeter(level: level, peak: peak, width: width, height: height);
  }
}

class _SingleMeter extends StatelessWidget {
  final double level;
  final double peak;
  final double width;
  final double height;

  const _SingleMeter({
    required this.level,
    required this.peak,
    required this.width,
    required this.height,
  });

  Color _colorForLevel(double l) {
    if (l > 0.88) return AppColors.meterHigh;
    if (l > 0.70) return AppColors.meterMid;
    return AppColors.meterLow;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MeterPainter(
        level: level,
        peak: peak,
        colorFor: _colorForLevel,
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double level;
  final double peak;
  final Color Function(double) colorFor;

  static const int _segments = 20;

  const _MeterPainter({
    required this.level,
    required this.peak,
    required this.colorFor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final segH = size.height / _segments;
    final gap  = segH * 0.12;
    final bkg  = Paint()..color = AppColors.surfaceDark;

    for (int i = 0; i < _segments; i++) {
      final t      = 1.0 - i / _segments; // top = loudest
      final top    = i * segH;
      final rect   = Rect.fromLTWH(0, top, size.width, segH - gap);
      final active = level >= t;
      final isPeak = (peak - t).abs() < 1.0 / _segments;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        bkg,
      );

      if (active || isPeak) {
        final c = isPeak ? Colors.white : colorFor(t);
        final paint = Paint()
          ..color = isPeak ? c.withOpacity(0.9) : c
          ..maskFilter = active
              ? MaskFilter.blur(BlurStyle.normal, 1.5)
              : null;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.level != level || old.peak != peak;
}

/// Animating level meter that simulates a bouncing signal.
class AnimatingLevelMeter extends StatefulWidget {
  final bool active;
  final double width;
  final double height;
  final bool stereo;

  const AnimatingLevelMeter({
    super.key,
    this.active = true,
    this.width = 12,
    this.height = 100,
    this.stereo = false,
  });

  @override
  State<AnimatingLevelMeter> createState() => _AnimatingLevelMeterState();
}

class _AnimatingLevelMeterState extends State<AnimatingLevelMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _level  = 0;
  double _levelR = 0;
  double _peak   = 0;
  double _peakR  = 0;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))
      ..addListener(_tick)
      ..repeat();
  }

  void _tick() {
    if (!widget.active || !mounted) return;
    setState(() {
      _level  = (_level  * 0.7 + _rng.nextDouble() * 0.65).clamp(0.0, 1.0);
      _levelR = (_levelR * 0.7 + _rng.nextDouble() * 0.65).clamp(0.0, 1.0);
      if (_level  > _peak)  _peak  = _level;
      if (_levelR > _peakR) _peakR = _levelR;
      _peak  = math.max(0, _peak  - 0.005);
      _peakR = math.max(0, _peakR - 0.005);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LevelMeter(
      level: widget.active ? _level : 0,
      peak:  widget.active ? _peak  : 0,
      levelR: widget.active ? _levelR : 0,
      peakR:  widget.active ? _peakR  : 0,
      width: widget.width,
      height: widget.height,
      stereo: widget.stereo,
    );
  }
}
