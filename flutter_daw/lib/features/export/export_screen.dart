import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/providers/project_provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';

// ─── Export state ─────────────────────────────────────────────────────────────
enum _ExportStatus { idle, rendering, done, error }

class _ExportState {
  final _ExportStatus status;
  final double progress;       // 0.0 – 1.0
  final String? outputPath;
  final String? errorMessage;

  const _ExportState({
    this.status = _ExportStatus.idle,
    this.progress = 0,
    this.outputPath,
    this.errorMessage,
  });

  _ExportState copyWith({
    _ExportStatus? status,
    double? progress,
    String? outputPath,
    String? errorMessage,
    bool clearOutputPath = false,
    bool clearError = false,
  }) {
    return _ExportState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputPath: clearOutputPath ? null : outputPath ?? this.outputPath,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class _ExportNotifier extends StateNotifier<_ExportState> {
  _ExportNotifier() : super(const _ExportState());

  Future<void> export({
    required String projectName,
    required String format,
    required int sampleRate,
    required int bitDepth,
  }) async {
    state = state.copyWith(status: _ExportStatus.rendering, progress: 0);

    try {
      // Simulate rendering progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(progress: i / 10);
      }

      // TODO: replace with real audio engine call
      final outputPath = await AudioUtils.exportMix(
        outputPath: '/tmp/${projectName.replaceAll(' ', '_')}.$format',
        format: format,
        sampleRate: sampleRate,
        bitDepth: bitDepth,
      );

      // Stub success path
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${projectName.replaceAll(' ', '_')}.$format';

      state = state.copyWith(
        status: _ExportStatus.done,
        progress: 1.0,
        outputPath: path,
      );
    } catch (e) {
      state = state.copyWith(
        status: _ExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const _ExportState();
}

final _exportProvider =
    StateNotifierProvider.autoDispose<_ExportNotifier, _ExportState>(
        (ref) => _ExportNotifier());

// ─── Screen ────────────────────────────────────────────────────────────────────
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _format      = 'wav';
  int    _sampleRate  = 44100;
  int    _bitDepth    = 24;
  bool   _normalize   = true;
  bool   _dither      = true;
  String _exportRange = 'ALL'; // 'ALL' | 'LOOP' | 'SELECTION'

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _format     = s.exportFormat;
    _sampleRate = s.exportSampleRate;
    _bitDepth   = s.exportBitDepth;
  }

  @override
  Widget build(BuildContext context) {
    final project  = ref.watch(projectProvider).currentProject;
    final exp      = ref.watch(_exportProvider);
    final expNot   = ref.read(_exportProvider.notifier);
    final isExporting = exp.status == _ExportStatus.rendering;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('EXPORT'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Project info
          if (project != null)
            DawPanel(
              child: Row(
                children: [
                  const Icon(Icons.folder, color: AppColors.neonBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name,
                          style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textPrimary, letterSpacing: 1)),
                        Text('${project.bpm} BPM · ${project.tracks.length} TRACKS · ${project.bars} BARS',
                          style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Format settings
          DawPanel(
            title: 'OUTPUT FORMAT',
            child: Column(
              children: [
                // Format
                _SettingRow(
                  label: 'FORMAT',
                  child: Row(
                    children: ['wav', 'mp3', 'aac'].map((f) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: NeonButton(
                        label: f.toUpperCase(),
                        color: AppColors.neonBlue,
                        active: _format == f,
                        mini: true,
                        onPressed: () => setState(() => _format = f),
                      ),
                    )).toList(),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Sample rate
                _SettingRow(
                  label: 'SAMPLE RATE',
                  child: Row(
                    children: [44100, 48000].map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: NeonButton(
                        label: r == 44100 ? '44.1K' : '48K',
                        color: AppColors.neonPurple,
                        active: _sampleRate == r,
                        mini: true,
                        onPressed: () => setState(() => _sampleRate = r),
                      ),
                    )).toList(),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Bit depth
                _SettingRow(
                  label: 'BIT DEPTH',
                  child: Row(
                    children: [16, 24, 32].map((b) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: NeonButton(
                        label: '${b}BIT',
                        color: AppColors.neonGreen,
                        active: _bitDepth == b,
                        mini: true,
                        onPressed: () => setState(() => _bitDepth = b),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Export range
          DawPanel(
            title: 'EXPORT RANGE',
            child: Column(
              children: ['ALL', 'LOOP', 'SELECTION'].map((r) => RadioListTile<String>(
                dense: true,
                title: Text(r,
                  style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textPrimary, letterSpacing: 1.5)),
                value: r,
                groupValue: _exportRange,
                activeColor: AppColors.neonBlue,
                onChanged: (v) { if (v != null) setState(() => _exportRange = v); },
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Processing options
          DawPanel(
            title: 'PROCESSING',
            child: Column(
              children: [
                _SwitchRow('NORMALIZE',  _normalize, AppColors.neonOrange, (v) => setState(() => _normalize = v)),
                const Divider(height: 1, color: AppColors.border),
                _SwitchRow('DITHER',     _dither,    AppColors.neonYellow,  (v) => setState(() => _dither = v)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Estimated size
          DawPanel(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _estimatedSize(project?.bars ?? 4, project?.bpm ?? 120),
                      style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.neonBlue, letterSpacing: 1),
                    ),
                    const Text('ESTIMATED FILE SIZE',
                      style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted, letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress / status
          if (exp.status == _ExportStatus.rendering) ...[
            DawPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.neonGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('RENDERING...',
                        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.neonGreen, letterSpacing: 2)),
                      const Spacer(),
                      Text('${(exp.progress * 100).round()}%',
                        style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.neonGreen)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: exp.progress,
                    backgroundColor: AppColors.border,
                    color: AppColors.neonGreen,
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (exp.status == _ExportStatus.done) ...[
            DawPanel(
              borderColor: AppColors.neonGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 18),
                      const SizedBox(width: 8),
                      const Text('EXPORT COMPLETE',
                        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.neonGreen, letterSpacing: 2)),
                    ],
                  ),
                  if (exp.outputPath != null) ...[
                    const SizedBox(height: 6),
                    Text(exp.outputPath!,
                      style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      NeonButton(
                        label: 'SHARE',
                        icon: Icons.share,
                        color: AppColors.neonBlue,
                        onPressed: () { /* TODO: Share.shareXFiles */ },
                      ),
                      const SizedBox(width: 8),
                      NeonButton(
                        label: 'EXPORT AGAIN',
                        color: AppColors.textSecondary,
                        onPressed: () => expNot.reset(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (exp.status == _ExportStatus.error) ...[
            DawPanel(
              borderColor: AppColors.neonRed,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.neonRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ERROR: ${exp.errorMessage}',
                      style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.neonRed)),
                  ),
                  NeonIconButton(icon: Icons.refresh, color: AppColors.neonOrange, size: 28, onPressed: expNot.reset),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Export button
          NeonButton(
            label: isExporting ? 'RENDERING...' : 'EXPORT ${_format.toUpperCase()}',
            color: isExporting ? AppColors.textMuted : AppColors.neonOrange,
            height: 52,
            onPressed: (isExporting || project == null)
                ? null
                : () => expNot.export(
                    projectName: project.name,
                    format: _format,
                    sampleRate: _sampleRate,
                    bitDepth: _bitDepth,
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _estimatedSize(int bars, int bpm) {
    final beatDuration = 60.0 / bpm;
    final totalSeconds = bars * 4 * beatDuration;
    final bytesPerSec  = _sampleRate * (_bitDepth ~/ 8) * 2; // stereo
    final bytes        = _format == 'wav'
        ? totalSeconds * bytesPerSec
        : totalSeconds * (_format == 'mp3' ? 16000 : 12000); // compressed estimate
    if (bytes < 1024 * 1024) return '~${(bytes / 1024).round()} KB';
    return '~${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.2)),
          ),
          child,
        ],
      ),
    );
  }
}

Widget _SwitchRow(String label, bool value, Color color, ValueChanged<bool> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label,
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.2)),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(value: value, onChanged: onChanged, activeColor: color),
        ),
      ],
    ),
  );
}
