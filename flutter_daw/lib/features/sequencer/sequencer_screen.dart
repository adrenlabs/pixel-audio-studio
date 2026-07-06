import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/track.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/providers/project_provider.dart';
import '../../shared/providers/audio_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/transport_bar.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/waveform_painter.dart';

class SequencerScreen extends ConsumerStatefulWidget {
  const SequencerScreen({super.key});

  @override
  ConsumerState<SequencerScreen> createState() => _SequencerScreenState();
}

class _SequencerScreenState extends ConsumerState<SequencerScreen> {
  static const double _trackHeaderW = 100.0;
  static const double _trackH       = 56.0;
  static const double _cellW        = 48.0;  // pixels per beat
  static const double _timeRulerH   = 28.0;

  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  String? _selectedTrackId;

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(projectProvider);
    final audio   = ref.watch(audioProvider);
    final project = state.currentProject;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project?.name ?? 'SEQUENCER'),
        actions: [
          NeonButton(
            label: '+ TRACK',
            color: AppColors.neonBlue,
            mini: true,
            onPressed: () => _showAddTrackSheet(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          const TransportBar(),
          Container(height: 1, color: AppColors.border),
          Expanded(child: _buildTimeline(project, audio)),
        ],
      ),
    );
  }

  Widget _buildTimeline(project, AudioState audio) {
    if (project == null) {
      return const Center(
        child: Text('OPEN A PROJECT FIRST',
          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textMuted, letterSpacing: 2)),
      );
    }

    final totalBeats  = (project.bars * project.beatsPerBar).toDouble();
    final timelineW   = totalBeats * _cellW;
    final playheadX   = audio.playheadBeat * _cellW;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Track headers ───────────────────────────────────────────────────
        SizedBox(
          width: _trackHeaderW,
          child: Column(
            children: [
              Container(
                height: _timeRulerH,
                color: AppColors.surfaceDark,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('TRACKS', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted, letterSpacing: 1.5)),
                ),
              ),
              Container(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: _vScroll,
                  children: project.tracks.isEmpty
                      ? [_buildEmptyTracksHint()]
                      : project.tracks.map<Widget>((t) => _TrackHeader(
                            track: t,
                            isSelected: _selectedTrackId == t.id,
                            onTap: () => setState(() => _selectedTrackId = t.id),
                            onRemove: () => ref.read(projectProvider.notifier).removeTrack(t.id),
                          )).toList(),
                ),
              ),
            ],
          ),
        ),

        Container(width: 1, color: AppColors.border),

        // ─── Timeline area ───────────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              // Time ruler
              Container(
                height: _timeRulerH,
                color: AppColors.surfaceDark,
                child: SingleChildScrollView(
                  controller: _hScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: timelineW,
                    child: CustomPaint(
                      painter: _TimeRulerPainter(
                        totalBeats: totalBeats.toInt(),
                        cellW: _cellW,
                        beatsPerBar: project.beatsPerBar,
                        playheadX: playheadX,
                      ),
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: AppColors.border),

              // Track clips area
              Expanded(
                child: GestureDetector(
                  onTapDown: (d) => _onTimelineTab(d, totalBeats),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _hScroll,
                    child: SizedBox(
                      width: timelineW,
                      child: PixelGrid(
                        cellWidth: _cellW,
                        cellHeight: _trackH,
                        child: Stack(
                          children: [
                            // Track clip rows
                            SingleChildScrollView(
                              controller: _vScroll,
                              child: Column(
                                children: project.tracks.isEmpty
                                    ? [SizedBox(height: 200)]
                                    : project.tracks.map<Widget>((t) {
                                        return _ClipRow(
                                          track: t,
                                          cellW: _cellW,
                                          trackH: _trackH,
                                          totalBeats: totalBeats,
                                          isSelected: _selectedTrackId == t.id,
                                          onAddClip: (beat) => _addClip(t, beat),
                                        );
                                      }).toList(),
                              ),
                            ),

                            // Playhead
                            Positioned(
                              left: playheadX - 1,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: AppColors.playhead,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onTimelineTab(TapDownDetails d, double totalBeats) {
    final beat = (d.localPosition.dx / _cellW).clamp(0, totalBeats - 1);
    ref.read(audioProvider.notifier).setPlayhead(beat);
  }

  void _addClip(Track track, double startBeat) {
    final clip = TrackClip.create(
      name: '${track.name} clip',
      startBeat: startBeat,
      durationBeats: 4,
      color: track.color,
    );
    final updated = track.copyWith(clips: [...track.clips, clip]);
    ref.read(projectProvider.notifier).updateTrack(updated);
  }

  Widget _buildEmptyTracksHint() {
    return Container(
      height: 200,
      child: const Center(
        child: Text('NO TRACKS\nTAP + TRACK',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1.5)),
      ),
    );
  }

  void _showAddTrackSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('ADD TRACK', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.neonBlue, letterSpacing: 2)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...TrackType.values.map((t) => ListTile(
            title: Text(t.name.toUpperCase(),
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textPrimary, letterSpacing: 1.5)),
            onTap: () {
              Navigator.pop(context);
              ref.read(projectProvider.notifier).addTrack(t);
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  final Track track;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _TrackHeader({
    required this.track,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? track.color.withOpacity(0.1) : AppColors.surface,
          border: Border(
            bottom: const BorderSide(color: AppColors.border, width: 0.5),
            left: BorderSide(color: isSelected ? track.color : Colors.transparent, width: 3),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textPrimary, letterSpacing: 0.8)),
                  Text(track.type.name.toUpperCase(),
                    style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted, letterSpacing: 1)),
                ],
              ),
            ),
            // Mute / Solo icons
            if (isSelected) ...[
              _TinyButton(
                icon: Icons.volume_off,
                color: track.muted ? AppColors.neonOrange : AppColors.textMuted,
                onTap: () {},
              ),
              _TinyButton(
                icon: Icons.stars,
                color: track.soloed ? AppColors.neonYellow : AppColors.textMuted,
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TinyButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 13),
      ),
    );
  }
}

class _ClipRow extends StatelessWidget {
  final Track track;
  final double cellW;
  final double trackH;
  final double totalBeats;
  final bool isSelected;
  final ValueChanged<double> onAddClip;

  const _ClipRow({
    required this.track,
    required this.cellW,
    required this.trackH,
    required this.totalBeats,
    required this.isSelected,
    required this.onAddClip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => onAddClip(d.localPosition.dx / cellW),
      child: Container(
        height: trackH,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Stack(
          children: track.clips.map((clip) {
            final left  = clip.startBeat * cellW;
            final width = clip.durationBeats * cellW;
            final color = clip.clipColor ?? track.color;
            final samples = AudioUtils.fakeWaveform(60, seed: clip.id.hashCode.toDouble());

            return Positioned(
              left: left,
              top: 3,
              width: width.clamp(4, double.infinity),
              height: trackH - 6,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: color.withOpacity(0.6), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        child: Text(clip.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: color, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        child: WaveformThumbnail(
                          samples: samples,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final int totalBeats;
  final double cellW;
  final int beatsPerBar;
  final double playheadX;

  const _TimeRulerPainter({
    required this.totalBeats,
    required this.cellW,
    required this.beatsPerBar,
    required this.playheadX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint  = Paint()..color = AppColors.textSecondary..strokeWidth = 1;
    final beatPaint = Paint()..color = AppColors.border..strokeWidth = 0.5;

    for (int b = 0; b <= totalBeats; b++) {
      final x = b * cellW;
      final isBar = b % beatsPerBar == 0;
      canvas.drawLine(
        Offset(x, isBar ? 0 : size.height * 0.5),
        Offset(x, size.height),
        isBar ? barPaint : beatPaint,
      );
      if (isBar) {
        final bar = b ~/ beatsPerBar + 1;
        final tp = TextPainter(
          text: TextSpan(
            text: '$bar',
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 2, 2));
      }
    }

    // Playhead on ruler
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()..color = AppColors.playhead..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TimeRulerPainter old) =>
      old.playheadX != playheadX || old.totalBeats != totalBeats;
}
