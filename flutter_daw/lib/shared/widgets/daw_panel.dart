import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A bordered panel used as the base container for every DAW section.
class DawPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Color borderColor;
  final double padding;
  final Color? backgroundColor;
  final Widget? titleWidget;

  const DawPanel({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.borderColor = AppColors.border,
    this.padding = 8,
    this.backgroundColor,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || titleWidget != null || (actions?.isNotEmpty ?? false))
            _PanelHeader(
              title: title,
              titleWidget: titleWidget,
              actions: actions ?? [],
            ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;

  const _PanelHeader({
    this.title,
    this.titleWidget,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      child: Row(
        children: [
          // Left accent line
          Container(
            width: 2,
            height: 12,
            color: AppColors.neonBlue,
            margin: const EdgeInsets.only(right: 6),
          ),
          if (titleWidget != null) Expanded(child: titleWidget!),
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ...actions,
        ],
      ),
    );
  }
}

/// Horizontal section divider with optional label.
class DawDivider extends StatelessWidget {
  final String? label;
  final Color color;

  const DawDivider({super.key, this.label, this.color = AppColors.border});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Divider(height: 1, thickness: 1, color: color);
    }
    return Row(
      children: [
        Expanded(child: Divider(height: 1, thickness: 1, color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label!,
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 8,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(height: 1, thickness: 1, color: color)),
      ],
    );
  }
}

/// Pixel-grid background decorator used on timeline and sequencer.
class PixelGrid extends StatelessWidget {
  final Widget child;
  final double cellWidth;
  final double cellHeight;
  final Color gridColor;

  const PixelGrid({
    super.key,
    required this.child,
    this.cellWidth = 32,
    this.cellHeight = 40,
    this.gridColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        cellW: cellWidth,
        cellH: cellHeight,
        color: gridColor,
      ),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  final double cellW;
  final double cellH;
  final Color color;

  const _GridPainter({
    required this.cellW,
    required this.cellH,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += cellW) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cellH) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.cellW != cellW || old.cellH != cellH || old.color != color;
}
