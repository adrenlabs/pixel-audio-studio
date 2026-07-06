import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/track.dart';
import '../../shared/providers/project_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/studio_slider.dart';
import '../../shared/widgets/studio_knob.dart';
import '../../shared/widgets/level_meter.dart';
import '../../shared/widgets/transport_bar.dart';
import '../../core/utils/audio_utils.dart';

// ─── Local mixer channel state ─────────────────────────────────────────────────
class _MixerChannel {
  final String id;
  final String name;
  final Color color;
  double volume;
  double pan;
  bool muted;
  bool soloed;
  List<EffectSlot> effects;

  _MixerChannel({
    required this.id,
    required this.name,
    required this.color,
    this.volume = 0.8,
    this.pan = 0.0,
    this.muted = false,
    this.soloed = false,
    required this.effects,
  });
}

class MixerScreen extends ConsumerStatefulWidget {
  const MixerScreen({super.key});

  @override
  ConsumerState<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends ConsumerState<MixerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedChannelId;

  // Separate "master" channel
  double _masterVolume = 0.85;
  double _masterPan    = 0.0;

  List<_MixerChannel> _localChannels = [];

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

  List<_MixerChannel> _buildChannels(ProjectState state) {
    if (state.currentProject == null) return [];
    return state.currentProject!.tracks.map((t) => _MixerChannel(
      id: t.id,
      name: t.name,
      color: t.color,
      volume: t.volume,
      pan: t.pan,
      muted: t.muted,
      soloed: t.soloed,
      effects: t.effects,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(projectProvider);
    final channels = _buildChannels(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MIXER'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, letterSpacing: 1.5),
          labelColor: AppColors.neonBlue,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.neonBlue,
          tabs: const [Tab(text: 'CHANNELS'), Tab(text: 'FX CHAIN')],
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
                // ─── Channels ─────────────────────────────────────────────────
                channels.isEmpty
                    ? _buildNoProject()
                    : _buildChannelStrip(channels, state),

                // ─── FX Chain ─────────────────────────────────────────────────
                _selectedChannelId != null
                    ? _buildFxChain(channels, state)
                    : const Center(
                        child: Text('SELECT A CHANNEL',
                          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textMuted, letterSpacing: 2))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProject() {
    return const Center(
      child: Text('OPEN A PROJECT TO USE THE MIXER',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textMuted, letterSpacing: 2)),
    );
  }

  Widget _buildChannelStrip(List<_MixerChannel> channels, ProjectState state) {
    return Row(
      children: [
        // Scrollable channels
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...channels.map((ch) => _ChannelStrip(
                  channel: ch,
                  isSelected: _selectedChannelId == ch.id,
                  onSelect: () => setState(() => _selectedChannelId = ch.id),
                  onVolumeChanged: (v) => _updateChannelVolume(ch.id, v, state),
                  onPanChanged: (v)    => _updateChannelPan(ch.id, v, state),
                  onMuteToggle: ()     => _toggleMute(ch.id, state),
                  onSoloToggle: ()     => _toggleSolo(ch.id, state),
                )),
                // Master channel
                _MasterChannel(
                  volume: _masterVolume,
                  pan: _masterPan,
                  onVolumeChanged: (v) => setState(() => _masterVolume = v),
                  onPanChanged: (v)    => setState(() => _masterPan = v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFxChain(List<_MixerChannel> channels, ProjectState state) {
    if (channels.isEmpty) {
      return const Center(
        child: Text('NO CHANNELS', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textMuted, letterSpacing: 2)),
      );
    }
    final ch = channels.firstWhere(
      (c) => c.id == _selectedChannelId,
      orElse: () => channels.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel info
          DawPanel(
            child: Row(
              children: [
                Container(width: 3, height: 18, color: ch.color),
                const SizedBox(width: 8),
                Text(ch.name,
                  style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 14, color: AppColors.textPrimary, letterSpacing: 1)),
                const Spacer(),
                Text('FX CHAIN', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: ch.color, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // FX slots
          DawPanel(
            title: 'EFFECTS',
            actions: [
              NeonIconButton(
                icon: Icons.add,
                color: AppColors.neonBlue,
                size: 28,
                onPressed: () => _showAddFxSheet(ch.id, state),
              ),
            ],
            child: Column(
              children: [
                if (ch.effects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('NO EFFECTS — TAP + TO ADD',
                      style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1.5)),
                  )
                else
                  ...ch.effects.asMap().entries.map((e) => _FxSlotRow(
                    slot: e.value,
                    index: e.key,
                    onToggle: () => _toggleFx(ch.id, e.key, state),
                    onRemove: () => _removeFx(ch.id, e.key, state),
                  )),

                // Empty slots placeholder
                ...List.generate(
                  (AppConstants.maxFxSlots - ch.effects.length).clamp(0, AppConstants.maxFxSlots).toInt(),
                  (i) => _EmptyFxSlot(onAdd: () => _showAddFxSheet(ch.id, state)),
                ).take(4),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // EQ stub
          DawPanel(
            title: 'EQ PREVIEW',
            child: SizedBox(
              height: 80,
              child: CustomPaint(
                painter: _EqCurvePainter(color: ch.color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Channel update helpers ────────────────────────────────────────────────

  void _updateChannelVolume(String id, double v, ProjectState state) {
    final project = state.currentProject;
    if (project == null) return;
    final track = project.tracks.firstWhere((t) => t.id == id);
    ref.read(projectProvider.notifier).updateTrack(track.copyWith(volume: v));
  }

  void _updateChannelPan(String id, double v, ProjectState state) {
    final project = state.currentProject;
    if (project == null) return;
    final track = project.tracks.firstWhere((t) => t.id == id);
    ref.read(projectProvider.notifier).updateTrack(track.copyWith(pan: v));
  }

  void _toggleMute(String id, ProjectState state) {
    final project = state.currentProject;
    if (project == null) return;
    final track = project.tracks.firstWhere((t) => t.id == id);
    ref.read(projectProvider.notifier).updateTrack(track.copyWith(muted: !track.muted));
  }

  void _toggleSolo(String id, ProjectState state) {
    final project = state.currentProject;
    if (project == null) return;
    final track = project.tracks.firstWhere((t) => t.id == id);
    ref.read(projectProvider.notifier).updateTrack(track.copyWith(soloed: !track.soloed));
  }

  void _toggleFx(String channelId, int fxIndex, ProjectState state) {
    final project = state.currentProject;
    if (project == null) return;
    final track = project.tracks.firstWhere((t) => t.id == channelId);
    final fx = [...track.effects];
    fx[fxIndex] = fx[fxIndex].copyWith(enabled: !fx[fxIndex].enabled);
    ref.read(projectProvider.notifier).updateTrack(track.copyWith(effects: fx));
  }

  void _removeFx(String channelId, int fxIndex, ProjectState state) {
    final project = state.currentProject;
    if (project == null) return;
    final track = project.tracks.firstWhere((t) => t.id == channelId);
    final fx = [...track.effects]..removeAt(fxIndex);
    ref.read(projectProvider.notifier).updateTrack(track.copyWith(effects: fx));
  }

  void _showAddFxSheet(String channelId, ProjectState state) {
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
            child: Text('ADD EFFECT',
              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.neonBlue, letterSpacing: 2)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...AppConstants.effectNames.map((name) => ListTile(
            title: Text(name,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.textPrimary, letterSpacing: 1.5)),
            onTap: () {
              Navigator.pop(context);
              final project = state.currentProject;
              if (project == null) return;
              final track = project.tracks.firstWhere((t) => t.id == channelId);
              final updated = track.copyWith(
                effects: [...track.effects, EffectSlot.create(name)],
              );
              ref.read(projectProvider.notifier).updateTrack(updated);
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Channel Strip Widget ──────────────────────────────────────────────────────

class _ChannelStrip extends StatelessWidget {
  final _MixerChannel channel;
  final bool isSelected;
  final VoidCallback onSelect;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onPanChanged;
  final VoidCallback onMuteToggle;
  final VoidCallback onSoloToggle;

  const _ChannelStrip({
    required this.channel,
    required this.isSelected,
    required this.onSelect,
    required this.onVolumeChanged,
    required this.onPanChanged,
    required this.onMuteToggle,
    required this.onSoloToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: AppConstants.channelWidth,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? channel.color.withOpacity(0.07) : AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? channel.color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Channel name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: channel.color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              child: Text(
                channel.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: channel.color,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Level meter
            AnimatingLevelMeter(
              active: !channel.muted,
              width: 8,
              height: 80,
              stereo: true,
            ),

            const SizedBox(height: 8),

            // Pan knob
            StudioKnob(
              value: (channel.pan + 1) / 2,
              onChanged: (v) => onPanChanged(v * 2 - 1),
              color: AppColors.neonPurple,
              label: 'PAN',
              valueLabel: AudioUtils.panLabel(channel.pan),
              size: 36,
            ),

            const SizedBox(height: 4),

            // Volume fader
            VerticalFader(
              value: channel.volume,
              onChanged: onVolumeChanged,
              color: channel.color,
              height: AppConstants.faderHeight,
              width: 18,
            ),

            // Volume label
            Text(
              '${(channel.volume * 100).round()}',
              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: channel.color),
            ),

            const SizedBox(height: 8),

            // Mute / Solo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SmallPad(
                  label: 'M',
                  color: AppColors.neonOrange,
                  active: channel.muted,
                  onTap: onMuteToggle,
                ),
                _SmallPad(
                  label: 'S',
                  color: AppColors.neonYellow,
                  active: channel.soloed,
                  onTap: onSoloToggle,
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SmallPad extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _SmallPad({required this.label, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 22,
        height: 18,
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.3) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, fontWeight: FontWeight.bold, color: active ? color : AppColors.textMuted)),
        ),
      ),
    );
  }
}

class _MasterChannel extends StatelessWidget {
  final double volume;
  final double pan;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onPanChanged;

  const _MasterChannel({
    required this.volume,
    required this.pan,
    required this.onVolumeChanged,
    required this.onPanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.channelWidth + 8,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: const Text('MASTER',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, fontWeight: FontWeight.bold,
                color: AppColors.neonGreen, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 6),
          AnimatingLevelMeter(active: true, width: 10, height: 80, stereo: true),
          const SizedBox(height: 8),
          StudioKnob(value: (pan + 1) / 2, onChanged: (v) => onPanChanged(v * 2 - 1),
            color: AppColors.neonGreen, label: 'PAN', size: 36),
          const SizedBox(height: 4),
          VerticalFader(value: volume, onChanged: onVolumeChanged,
            color: AppColors.neonGreen, height: AppConstants.faderHeight, width: 20),
          Text('${(volume * 100).round()}',
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.neonGreen)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FxSlotRow extends StatelessWidget {
  final EffectSlot slot;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _FxSlotRow({required this.slot, required this.index, required this.onToggle, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: slot.enabled ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: slot.enabled ? AppColors.neonBlue.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          Text('${index + 1}',
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(slot.effectName,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                color: slot.enabled ? AppColors.textPrimary : AppColors.textMuted,
                letterSpacing: 1,
              )),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28, height: 16,
              decoration: BoxDecoration(
                color: slot.enabled ? AppColors.neonBlue.withOpacity(0.2) : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: slot.enabled ? AppColors.neonBlue : AppColors.border),
              ),
              child: Center(
                child: Text(slot.enabled ? 'ON' : 'OFF',
                  style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 6, color: slot.enabled ? AppColors.neonBlue : AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: AppColors.textMuted, size: 14),
          ),
        ],
      ),
    );
  }
}

class _EmptyFxSlot extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyFxSlot({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.border.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: const Center(
          child: Text('+ ADD FX', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted, letterSpacing: 2)),
        ),
      ),
    );
  }
}

class _EqCurvePainter extends CustomPainter {
  final Color color;
  const _EqCurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      Offset(0, size.height * 0.5),
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.3, size.height * 0.45),
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.85, size.height * 0.55),
      Offset(size.width, size.height * 0.5),
    ];

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final cp = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, cp.dx, cp.dy);
    }

    // Centre reference line
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      Paint()..color = AppColors.border..strokeWidth = 0.5,
    );

    // Frequency markers
    for (final f in ['63', '250', '1K', '4K', '16K']) {
      final i  = ['63', '250', '1K', '4K', '16K'].indexOf(f);
      final x  = size.width * (i + 1) / 6;
      final tp = TextPainter(
        text: TextSpan(text: f, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 12));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
