import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Vertical fader-style slider used in the mixer.
class VerticalFader extends StatelessWidget {
  final double value;           // 0.0 – 1.0
  final ValueChanged<double> onChanged;
  final Color color;
  final double height;
  final double width;
  final String? label;

  const VerticalFader({
    super.key,
    required this.value,
    required this.onChanged,
    this.color = AppColors.neonBlue,
    this.height = 140,
    this.width = 24,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: AppColors.border,
                thumbColor: color,
                overlayColor: color.withOpacity(0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
              ),
            ),
          ),
        ),
        if (label != null)
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 8,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }
}

/// Thin horizontal pan slider (center = 0).
class PanSlider extends StatelessWidget {
  final double value;    // -1.0 to +1.0
  final ValueChanged<double> onChanged;
  final Color color;
  final double width;

  const PanSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.color = AppColors.neonPurple,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value + 1) / 2; // map -1..1 → 0..1
    return SizedBox(
      width: width,
      height: 28,
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color,
          inactiveTrackColor: AppColors.border,
          thumbColor: color,
          overlayColor: color.withOpacity(0.15),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          trackHeight: 2,
        ),
        child: Slider(
          value: normalized.clamp(0.0, 1.0),
          onChanged: (v) {
            final pan = (v * 2 - 1).clamp(-1.0, 1.0);
            onChanged(pan);
          },
        ),
      ),
    );
  }
}

/// Thin labeled horizontal slider used in effect params, automation, etc.
class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color color;
  final String Function(double)? valueFormatter;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.color = AppColors.neonBlue,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final display = valueFormatter != null
        ? valueFormatter!(value)
        : value.toStringAsFixed(2);

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.border,
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              trackHeight: 2,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 9,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
