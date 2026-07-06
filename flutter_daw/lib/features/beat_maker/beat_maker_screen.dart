import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/providers/audio_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/transport_bar.dart';
import '../../shared/widgets/studio_slider.dart';

class BeatMakerScreen extends ConsumerStatefulWidget {
  const BeatMakerScreen({super.key});

  @override
  ConsumerState<BeatMakerScreen> createState() => _BeatMakerScreenState();
}

class _BeatMakerScreenState extends ConsumerState<BeatMakerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  // Per-pad press animation
  final List<bool> _padPressed = List.filled(16, false);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pattern  = ref.watch(beatPatternProvider);
    final audio    = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('BEAT MAKER'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, letterSpacing: 1.5),
          labelColor: AppColors.neonBlue,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.neonBlue,
          tabs: const [Tab(text: 'STEP SEQ'), Tab(text: 'DRUM PADS')],
        ),
      ),
      body: Column(
        children: [
          const TransportBar(),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _StepSequencerTab(pattern: pattern),
                _DrumPadTab(padPressed: _padPressed, onPadTap: _onPadTap),
              ],
            ),
          ),
          _BottomControls(pattern: pattern),
        ],
      ),
    );
  }

  void _onPadTap(int index) {
    HapticFeedback.heavyImpact();
    setState(() => _padPressed[index] = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _padPressed[index] = false);
    });
    // TODO: trigger pad sample at index
  }
}

// ─── Step Sequencer Tab ────────────────────────────────────────────────────────

class _StepSequencerTab extends ConsumerWidget {
  final dynamic pattern;
  const _StepSequencerTab({required this.pattern});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(beatPatternProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Controls row
          DawPanel(
            child: Row(
              children: [
                Expanded(
                  child: Text('${pattern.name}',
                    style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.textPrimary, letterSpacing: 1)),
                ),
                NeonButton(label: 'CLEAR', color: AppColors.neonOrange, mini: true, onPressed: () => notifier.clearAll()),
                const SizedBox(width: 6),
                NeonButton(label: 'RANDOM', color: AppColors.neonPurple, mini: true, onPressed: () => notifier.randomize()),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Beat number header
          _StepHeader(stepCount: pattern.stepCount, beatsPerBar: 4),
          const SizedBox(height: 4),

          // Rows
          ...pattern.rows.asMap().entries.map((e) {
            return _StepRow(
              row: e.value,
              rowIndex: e.key,
              currentStep: pattern.currentStep,
              onToggle: (si) => notifier.toggleStep(e.key, si),
              onVolumeChanged: (v) => notifier.setRowVolume(e.key, v),
            );
          }),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int stepCount;
  final int beatsPerBar;
  const _StepHeader({required this.stepCount, required this.beatsPerBar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 76), // pad for label
        Expanded(
          child: Row(
            children: List.generate(stepCount, (i) {
              final isBeat  = i % 4 == 0;
              final beatNum = i ~/ 4 + 1;
              return Expanded(
                child: Container(
                  height: 16,
                  alignment: Alignment.center,
                  child: isBeat
                      ? Text('$beatNum',
                          style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted))
                      : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 36), // pad for vol
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final dynamic row;
  final int rowIndex;
  final int currentStep;
  final ValueChanged<int> onToggle;
  final ValueChanged<double> onVolumeChanged;

  const _StepRow({
    required this.row,
    required this.rowIndex,
    required this.currentStep,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  Color get _rowColor {
    final colors = [
      AppColors.neonBlue,
      AppColors.neonPurple,
      AppColors.neonGreen,
      AppColors.neonOrange,
      AppColors.neonPink,
      AppColors.neonYellow,
    ];
    return colors[rowIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Pad name
          SizedBox(
            width: 72,
            child: Text(
              row.padName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                color: _rowColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Step buttons
          Expanded(
            child: Row(
              children: List.generate(row.steps.length, (si) {
                final isOn      = row.steps[si] as bool;
                final isCurrent = si == currentStep;
                final isBar     = si % 4 == 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggle(si);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 60),
                      margin: EdgeInsets.symmetric(
                        horizontal: 1.5,
                        vertical: isBar ? 0 : 2,
                      ),
                      height: isBar ? 28 : 24,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.white.withOpacity(0.25)
                            : isOn
                                ? _rowColor.withOpacity(0.85)
                                : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: isOn
                              ? _rowColor
                              : isCurrent
                                  ? Colors.white.withOpacity(0.3)
                                  : AppColors.border.withOpacity(0.5),
                          width: 0.8,
                        ),
                        boxShadow: isOn
                            ? [BoxShadow(color: _rowColor.withOpacity(0.3), blurRadius: 4)]
                            : [],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Volume
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: _TinyVolumeBar(
              value: row.volume as double,
              color: _rowColor,
              onChanged: onVolumeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyVolumeBar extends StatelessWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _TinyVolumeBar({required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        final delta = -d.delta.dy / 80;
        onChanged((value + delta).clamp(0.0, 1.0));
      },
      child: Container(
        width: 8,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: value,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Drum Pads Tab ─────────────────────────────────────────────────────────────

class _DrumPadTab extends StatelessWidget {
  final List<bool> padPressed;
  final ValueChanged<int> onPadTap;

  const _DrumPadTab({required this.padPressed, required this.onPadTap});

  @override
  Widget build(BuildContext context) {
    final padColors = [
      AppColors.neonBlue,   AppColors.neonPurple, AppColors.neonGreen,  AppColors.neonOrange,
      AppColors.neonPink,   AppColors.neonBlue,   AppColors.neonYellow, AppColors.neonGreen,
      AppColors.neonOrange, AppColors.neonPurple, AppColors.neonBlue,   AppColors.neonPink,
      AppColors.neonGreen,  AppColors.neonOrange, AppColors.neonYellow, AppColors.neonBlue,
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: AppConstants.totalPads,
        itemBuilder: (_, i) {
          return _DrumPad(
            label: AppConstants.drumPadLabels[i],
            color: padColors[i],
            isPressed: padPressed[i],
            onTap: () => onPadTap(i),
          );
        },
      ),
    );
  }
}

class _DrumPad extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPressed;
  final VoidCallback onTap;

  const _DrumPad({
    required this.label,
    required this.color,
    required this.isPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: isPressed ? color.withOpacity(0.35) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPressed ? color : color.withOpacity(0.35),
            width: isPressed ? 2 : 1,
          ),
          boxShadow: isPressed
              ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pixel-art inner decoration
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPressed ? color.withOpacity(0.2) : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color.withOpacity(0.4), width: 0.5),
              ),
              child: Icon(Icons.graphic_eq, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isPressed ? color : color.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Controls ───────────────────────────────────────────────────────────

class _BottomControls extends ConsumerWidget {
  final dynamic pattern;
  const _BottomControls({required this.pattern});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(beatPatternProvider.notifier);
    final audio    = ref.watch(audioProvider);
    final aNot     = ref.read(audioProvider.notifier);

    return Container(
      height: 52,
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // BPM
          GestureDetector(
            onVerticalDragUpdate: (d) {
              final delta = (-d.delta.dy / 2).round();
              final newBpm = (pattern.bpm + delta).clamp(20, 300);
              notifier.setBpm(newBpm);
              aNot.setBpm(newBpm);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${pattern.bpm}',
                  style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 20, fontWeight: FontWeight.bold,
                    color: AppColors.neonYellow, letterSpacing: 2)),
                const Text('BPM', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Steps selector
          Row(
            children: [16, 32].map((n) {
              final active = pattern.stepCount == n;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: NeonButton(
                  label: '${n}S',
                  color: AppColors.neonPurple,
                  active: active,
                  mini: true,
                  onPressed: () {},
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Swing
          const Text('SWING', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted, letterSpacing: 1.5)),
          SizedBox(
            width: 80,
            child: Slider(
              value: 0.5,
              onChanged: (_) {},
              activeColor: AppColors.neonPink,
              inactiveColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
