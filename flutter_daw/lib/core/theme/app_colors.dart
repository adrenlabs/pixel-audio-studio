import 'package:flutter/material.dart';

/// Central color palette for the retro DAW theme.
/// All neon accents are intentionally vivid for studio-display legibility.
class AppColors {
  AppColors._();

  // ─── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surfaceDark  = Color(0xFF0F0F18);
  static const Color surface      = Color(0xFF161625);
  static const Color surfaceLight = Color(0xFF1E1E32);
  static const Color panel        = Color(0xFF12121E);

  // ─── Borders / Lines ──────────────────────────────────────────────────────
  static const Color border       = Color(0xFF2A2A45);
  static const Color borderBright = Color(0xFF3A3A60);

  // ─── Neon Accents ─────────────────────────────────────────────────────────
  static const Color neonBlue   = Color(0xFF00CFFF);
  static const Color neonPurple = Color(0xFFAA44FF);
  static const Color neonGreen  = Color(0xFF00FF88);
  static const Color neonOrange = Color(0xFFFF6600);
  static const Color neonPink   = Color(0xFFFF3399);
  static const Color neonYellow = Color(0xFFFFCC00);
  static const Color neonRed    = Color(0xFFFF2244);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8E8FF);
  static const Color textSecondary = Color(0xFF9090B8);
  static const Color textMuted     = Color(0xFF555580);

  // ─── Track Colors (multi-track palette) ───────────────────────────────────
  static const List<Color> trackColors = [
    Color(0xFF00CFFF),
    Color(0xFFAA44FF),
    Color(0xFF00FF88),
    Color(0xFFFF6600),
    Color(0xFFFF3399),
    Color(0xFFFFCC00),
    Color(0xFF44AAFF),
    Color(0xFF00FFCC),
  ];

  // ─── Pad Colors ───────────────────────────────────────────────────────────
  static const List<Color> padColors = [
    Color(0xFF1A2A3A),
    Color(0xFF1A1A3A),
    Color(0xFF1A3A2A),
    Color(0xFF3A2A1A),
  ];

  // ─── Waveform ─────────────────────────────────────────────────────────────
  static const Color waveformActive   = Color(0xFF00CFFF);
  static const Color waveformInactive = Color(0xFF223344);
  static const Color playhead         = Color(0xFFFF6600);
  static const Color selectionFill    = Color(0x3300CFFF);

  // ─── Meter Colors ─────────────────────────────────────────────────────────
  static const Color meterLow    = Color(0xFF00FF88);
  static const Color meterMid    = Color(0xFFFFCC00);
  static const Color meterHigh   = Color(0xFFFF2244);

  // ─── Piano Roll ───────────────────────────────────────────────────────────
  static const Color pianoWhite  = Color(0xFFD0D0E8);
  static const Color pianoBlack  = Color(0xFF14141F);
  static const Color noteBlock   = Color(0xFF00CFFF);
  static const Color noteBlockAlt = Color(0xFFAA44FF);

  // ─── Glow helpers ─────────────────────────────────────────────────────────
  static BoxShadow glowBlue([double spread = 6]) => BoxShadow(
    color: neonBlue.withOpacity(0.35),
    blurRadius: spread * 2,
    spreadRadius: spread / 2,
  );

  static BoxShadow glowPurple([double spread = 6]) => BoxShadow(
    color: neonPurple.withOpacity(0.35),
    blurRadius: spread * 2,
    spreadRadius: spread / 2,
  );

  static BoxShadow glowGreen([double spread = 6]) => BoxShadow(
    color: neonGreen.withOpacity(0.35),
    blurRadius: spread * 2,
    spreadRadius: spread / 2,
  );

  static BoxShadow glowOrange([double spread = 6]) => BoxShadow(
    color: neonOrange.withOpacity(0.35),
    blurRadius: spread * 2,
    spreadRadius: spread / 2,
  );
}
