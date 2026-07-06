import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// Full-screen animated welcome / onboarding shown on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _scanCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _scanLine;
  int _page = 0;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      icon: Icons.piano,
      color: AppColors.neonBlue,
      title: 'PIXEL DAW',
      subtitle: 'Professional music production\nfor your pocket.',
    ),
    _OnboardPage(
      icon: Icons.grid_on,
      color: AppColors.neonPurple,
      title: 'BEAT MAKER',
      subtitle: '16-step sequencer, drum pads,\nand sample browser.',
    ),
    _OnboardPage(
      icon: Icons.tune,
      color: AppColors.neonGreen,
      title: 'STUDIO MIXER',
      subtitle: 'Multi-channel mixer,\neffects chains, and automation.',
    ),
    _OnboardPage(
      icon: Icons.file_download,
      color: AppColors.neonOrange,
      title: 'EXPORT & SHARE',
      subtitle: 'Render to WAV, MP3, or AAC.\nOffline-first, always ready.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _scanLine  = CurvedAnimation(parent: _scanCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.home);
  }

  void _nextPage() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top scan-line decoration ──────────────────────────────────
            SizedBox(
              height: 3,
              child: AnimatedBuilder(
                animation: _scanLine,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _ScanLinePainter(_scanLine.value),
                    size: Size(double.infinity, 3),
                  );
                },
              ),
            ),

            // ─── Logo area ─────────────────────────────────────────────────
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  children: [
                    // Glowing icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: page.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: page.color.withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: page.color.withOpacity(0.25), blurRadius: 20, spreadRadius: 4),
                        ],
                      ),
                      child: Icon(page.icon, color: page.color, size: 44),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      page.title,
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: page.color,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: page.color.withOpacity(0.4), blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                page.subtitle,
                key: ValueKey(_page),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                  height: 1.7,
                ),
              ),
            ),

            const Spacer(),

            // ─── Pixel art decoration ──────────────────────────────────────
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _PixelArtPainter(page.color),
                size: const Size(double.infinity, 120),
              ),
            ),

            const Spacer(),

            // ─── Dots ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final isActive = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? page.color : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isActive
                        ? [BoxShadow(color: page.color.withOpacity(0.4), blurRadius: 6)]
                        : [],
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ─── CTA Button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _nextPage();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: page.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: page.color, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: page.color.withOpacity(0.25), blurRadius: 12),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _page < _pages.length - 1 ? 'NEXT' : 'GET STARTED',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: page.color,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            if (_page < _pages.length - 1)
              TextButton(
                onPressed: _finish,
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  const _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final x = progress * size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, x, size.height),
      Paint()..color = AppColors.neonBlue,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class _PixelArtPainter extends CustomPainter {
  final Color color;
  const _PixelArtPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rng    = math.Random(color.value);
    final pixelW = 8.0;
    final cols   = (size.width  / pixelW).ceil();
    final rows   = (size.height / pixelW).ceil();

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (rng.nextDouble() < 0.07) {
          final opacity = 0.1 + rng.nextDouble() * 0.4;
          canvas.drawRect(
            Rect.fromLTWH(c * pixelW, r * pixelW, pixelW - 1, pixelW - 1),
            Paint()..color = color.withOpacity(opacity),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
