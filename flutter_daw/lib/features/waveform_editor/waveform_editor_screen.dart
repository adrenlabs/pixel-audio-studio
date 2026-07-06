import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/waveform_painter.dart';
import '../../shared/providers/audio_provider.dart';

class WaveformEditorScreen extends ConsumerStatefulWidget {
  final String? filePath;
  const WaveformEditorScreen({super.key, this.filePath});

  @override
  ConsumerState<WaveformEditorScreen> createState() => _WaveformEditorScreenState();
}

class _WaveformEditorScreenState extends ConsumerState<WaveformEditorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _playAnim;

  // Simulated waveform data
  late List<double> _waveData;
  double _playheadPos  = 0.0;   // 0-1
  double? _selStart;
  double? _selEnd;
  bool   _isPlaying    = false;
  double _zoom         = 1.0;
  String _editMode     = 'SELECT';  // SELECT | TRIM | SPLIT | LOOP

  final List<_EditTool> _tools = const [
    _EditTool('SELECT', Icons.cursor_default_outline_rounded,  AppColors.neonBlue),
    _EditTool('TRIM',   Icons.content_cut,                    AppColors.neonOrange),
    _EditTool('SPLIT',  Icons.compress,                       AppColors.neonPurple),
    _EditTool('LOOP',   Icons.loop,                           AppColors.neonGreen),
  ];

  @override
  void initState() {
    super.initState();
    final seed = widget.filePath?.hashCode.toDouble() ?? 42.0;
    _waveData  = AudioUtils.fakeWaveform(300, seed: seed);

    _playAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        if (_isPlaying) setState(() => _playheadPos = _playAnim.value);
      });
  }

  @override
  void dispose() {
    _playAnim.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _playAnim.forward(from: _playheadPos);
    } else {
      _playAnim.stop();
    }
  }

  void _onWaveformTap(TapDownDetails d, double width) {
    setState(() {
      final pos  = (d.localPosition.dx / width).clamp(0.0, 1.0).toDouble();
      if (_editMode == 'SELECT') {
        _playheadPos = pos;
        _selStart = null;
        _selEnd   = null;
      }
    });
  }

  void _onWaveformDrag(DragUpdateDetails d, double width) {
    if (_editMode != 'SELECT') return;
    final pos = (d.localPosition.dx / width).clamp(0.0, 1.0).toDouble();
    setState(() {
      _selEnd = pos;
      _selStart ??= pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.filePath != null
            ? widget.filePath!.split('/').last.toUpperCase()
            : 'WAVEFORM EDITOR'),
        actions: [
          NeonIconButton(icon: Icons.zoom_out, color: AppColors.textSecondary, size: 32,
            onPressed: () => setState(() => _zoom = (_zoom - 0.5).clamp(0.5, 8.0).toDouble())),
          NeonIconButton(icon: Icons.zoom_in,  color: AppColors.textSecondary, size: 32,
            onPressed: () => setState(() => _zoom = (_zoom + 0.5).clamp(0.5, 8.0).toDouble())),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ─── Tool bar ──────────────────────────────────────────────────────
          Container(
            height: 44,
            color: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _tools.map((t) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: NeonButton(
                  label: t.label,
                  icon: t.icon,
                  color: t.color,
                  active: _editMode == t.label,
                  mini: true,
                  onPressed: () => setState(() => _editMode = t.label),
                ),
              )).toList(),
            ),
          ),
          Container(height: 1, color: AppColors.border),

          // ─── Waveform area ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * _zoom,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return GestureDetector(
                      onTapDown: (d) => _onWaveformTap(d, constraints.maxWidth),
                      onPanUpdate: (d) => _onWaveformDrag(d, constraints.maxWidth),
                      child: Container(
                        color: AppColors.surface,
                        child: Column(
                          children: [
                            // Main waveform (top half)
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: WaveformWidget(
                                  samples: _waveData,
                                  color: AppColors.neonBlue,
                                  height: double.infinity,
                                  playheadPosition: _playheadPos,
                                  selectionStart: _selStart != null
                                      ? (_selStart! < (_selEnd ?? _selStart!)) ? _selStart : _selEnd
                                      : null,
                                  selectionEnd: _selEnd != null
                                      ? (_selEnd! > (_selStart ?? _selEnd!)) ? _selEnd : _selStart
                                      : null,
                                ),
                              ),
                            ),

                            Container(height: 1, color: AppColors.border),

                            // Overview / minimap (bottom strip)
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: WaveformThumbnail(
                                  samples: _waveData,
                                  color: AppColors.waveformInactive,
                                  height: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          Container(height: 1, color: AppColors.border),

          // ─── Time info ─────────────────────────────────────────────────────
          Container(
            height: 28,
            color: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'POS  ${AudioUtils.secondsToDisplay(_playheadPos * 10)}',
                  style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.neonBlue, letterSpacing: 1.5),
                ),
                if (_selStart != null && _selEnd != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'SEL  ${AudioUtils.secondsToDisplay((_selEnd! - _selStart!).abs() * 10)}',
                    style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.neonOrange, letterSpacing: 1.5),
                  ),
                ],
                const Spacer(),
                Text('ZOOM ${_zoom.toStringAsFixed(1)}x',
                  style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
              ],
            ),
          ),

          // ─── Transport & edit actions ───────────────────────────────────────
          Container(
            height: 56,
            color: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // Playback
                NeonIconButton(
                  icon: Icons.skip_previous,
                  color: AppColors.textSecondary,
                  size: 34,
                  onPressed: () => setState(() { _playheadPos = 0; _playAnim.stop(); _isPlaying = false; }),
                ),
                const SizedBox(width: 4),
                NeonIconButton(
                  icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.neonGreen,
                  active: _isPlaying,
                  size: 40,
                  onPressed: _togglePlay,
                ),

                const SizedBox(width: 16),
                const VerticalDivider(color: AppColors.border, width: 1),
                const SizedBox(width: 16),

                // Edit actions on selection
                if (_selStart != null && _selEnd != null) ...[
                  NeonButton(label: 'CUT',    color: AppColors.neonOrange, mini: true, onPressed: _cut),
                  const SizedBox(width: 6),
                  NeonButton(label: 'COPY',   color: AppColors.neonBlue,   mini: true, onPressed: _copy),
                  const SizedBox(width: 6),
                  NeonButton(label: 'DELETE', color: AppColors.neonRed,    mini: true, onPressed: _delete),
                  const SizedBox(width: 6),
                  NeonButton(label: 'LOOP',   color: AppColors.neonGreen,  mini: true, onPressed: _loop),
                ] else ...[
                  Text('DOUBLE-TAP TO SELECT REGION',
                    style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
                ],

                const Spacer(),

                // Fade handles (stub)
                NeonButton(label: 'FADE IN',  color: AppColors.neonPurple, mini: true, onPressed: () {}),
                const SizedBox(width: 4),
                NeonButton(label: 'FADE OUT', color: AppColors.neonPurple, mini: true, onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cut()    => _showEditSnack('CUT — TODO: real audio engine');
  void _copy()   => _showEditSnack('COPY — TODO: clipboard buffer');
  void _delete() {
    setState(() { _selStart = null; _selEnd = null; });
    _showEditSnack('DELETE — TODO: silence region');
  }
  void _loop()   => _showEditSnack('LOOP region set — TODO: engine loop points');

  void _showEditSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(msg, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.neonOrange)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _EditTool {
  final String label;
  final IconData icon;
  final Color color;
  const _EditTool(this.label, this.icon, this.color);
}
