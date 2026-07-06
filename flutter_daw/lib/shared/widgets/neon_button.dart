import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// A tactile, neon-glow button that matches the retro DAW aesthetic.
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final double? width;
  final double height;
  final double fontSize;
  final bool active;
  final IconData? icon;
  final bool mini;

  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.neonBlue,
    this.textColor,
    this.width,
    this.height = 36,
    this.fontSize = 11,
    this.active = false,
    this.icon,
    this.mini = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel()           => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isEnabled  = widget.onPressed != null;
    final accentColor = isEnabled ? widget.color : AppColors.textMuted;
    final bgColor     = widget.active
        ? accentColor.withOpacity(0.18)
        : AppColors.surfaceDark;

    return GestureDetector(
      onTapDown: isEnabled ? _onTapDown : null,
      onTapUp: isEnabled ? _onTapUp : null,
      onTapCancel: isEnabled ? _onTapCancel : null,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.mini ? 28 : widget.height,
          padding: EdgeInsets.symmetric(
            horizontal: widget.mini ? 8 : 12,
            vertical: 0,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: widget.active
                  ? accentColor
                  : accentColor.withOpacity(0.4),
              width: widget.active ? 1.5 : 1,
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: widget.mini ? 12 : 14,
                  color: widget.active
                      ? accentColor
                      : (widget.textColor ?? accentColor.withOpacity(0.8)),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: widget.mini ? 9 : widget.fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: widget.active
                      ? accentColor
                      : (widget.textColor ?? accentColor.withOpacity(0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular icon button with neon glow.
class NeonIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool active;
  final double size;
  final String? tooltip;

  const NeonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = AppColors.neonBlue,
    this.active = false,
    this.size = 36,
    this.tooltip,
  });

  @override
  State<NeonIconButton> createState() => _NeonIconButtonState();
}

class _NeonIconButtonState extends State<NeonIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.onPressed != null ? widget.color : AppColors.textMuted;
    Widget btn = GestureDetector(
      onTapDown: (_) { _ctrl.forward(); HapticFeedback.selectionClick(); },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.08,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.active ? color.withOpacity(0.15) : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(widget.size / 2),
            border: Border.all(
              color: widget.active ? color : color.withOpacity(0.35),
              width: widget.active ? 1.5 : 1,
            ),
            boxShadow: widget.active
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                : [],
          ),
          child: Icon(widget.icon, color: color, size: widget.size * 0.48),
        ),
      ),
    );
    if (widget.tooltip != null) {
      btn = Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
