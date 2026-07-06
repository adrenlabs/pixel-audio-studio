import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/audio_provider.dart';
import '../providers/project_provider.dart';
import 'neon_button.dart';

/// Global transport bar: play, stop, record, BPM, loop, metronome controls.
class TransportBar extends ConsumerWidget {
  const TransportBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio   = ref.watch(audioProvider);
    final project = ref.watch(projectProvider);
    final notifier = ref.read(audioProvider.notifier);
    final projNot  = ref.read(projectProvider.notifier);

    return Container(
      height: 52,
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // ─── Project name ───────────────────────────────────────────────────
          Expanded(
            child: Text(
              project.currentProject?.name ?? 'NO PROJECT',
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),

          // ─── BPM ────────────────────────────────────────────────────────────
          _BpmWidget(
            bpm: project.currentProject?.bpm ?? audio.bpm,
            onChanged: (v) {
              notifier.setBpm(v);
              projNot.setBpm(v);
            },
          ),

          const SizedBox(width: 8),

          // ─── Transport buttons ───────────────────────────────────────────────
          NeonIconButton(
            icon: Icons.skip_previous,
            color: AppColors.textSecondary,
            size: 34,
            onPressed: () => notifier.stop(),
            tooltip: 'Stop / Rewind',
          ),
          const SizedBox(width: 4),
          NeonIconButton(
            icon: audio.isPlaying ? Icons.pause : Icons.play_arrow,
            color: AppColors.neonGreen,
            active: audio.isPlaying,
            size: 38,
            onPressed: () => notifier.togglePlay(),
            tooltip: audio.isPlaying ? 'Pause' : 'Play',
          ),
          const SizedBox(width: 4),
          NeonIconButton(
            icon: Icons.fiber_manual_record,
            color: AppColors.neonRed,
            active: audio.isRecording,
            size: 34,
            onPressed: () {
              if (audio.isRecording) {
                notifier.stopRecording();
              } else {
                notifier.startRecording();
              }
            },
            tooltip: 'Record',
          ),

          const SizedBox(width: 8),

          // ─── Loop ───────────────────────────────────────────────────────────
          NeonButton(
            label: 'LOOP',
            color: AppColors.neonPurple,
            active: audio.loopEnabled,
            mini: true,
            onPressed: () => notifier.toggleLoop(),
          ),
          const SizedBox(width: 4),

          // ─── Metronome ──────────────────────────────────────────────────────
          NeonButton(
            label: 'CLICK',
            color: AppColors.neonOrange,
            active: audio.metronomeEnabled,
            mini: true,
            onPressed: () => notifier.toggleMetronome(),
          ),

          const SizedBox(width: 8),

          // ─── Undo / Redo ────────────────────────────────────────────────────
          NeonIconButton(
            icon: Icons.undo,
            color: AppColors.textSecondary,
            size: 30,
            onPressed: projNot.canUndo ? () => projNot.undo() : null,
            tooltip: 'Undo',
          ),
          const SizedBox(width: 2),
          NeonIconButton(
            icon: Icons.redo,
            color: AppColors.textSecondary,
            size: 30,
            onPressed: projNot.canRedo ? () => projNot.redo() : null,
            tooltip: 'Redo',
          ),
        ],
      ),
    );
  }
}

class _BpmWidget extends StatefulWidget {
  final int bpm;
  final ValueChanged<int> onChanged;
  const _BpmWidget({required this.bpm, required this.onChanged});

  @override
  State<_BpmWidget> createState() => _BpmWidgetState();
}

class _BpmWidgetState extends State<_BpmWidget> {
  double _startDy = 0;
  int _startBpm   = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        _startDy  = d.localPosition.dy;
        _startBpm = widget.bpm;
      },
      onPanUpdate: (d) {
        final delta = ((_startDy - d.localPosition.dy) / 2).round();
        widget.onChanged((_startBpm + delta).clamp(20, 300));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.bpm}',
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neonYellow,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'BPM',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 7,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
