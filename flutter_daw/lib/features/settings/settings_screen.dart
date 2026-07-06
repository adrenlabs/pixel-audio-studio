import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ─── Audio Engine ────────────────────────────────────────────────
          DawPanel(
            title: 'AUDIO ENGINE',
            child: Column(
              children: [
                _SettingRow(
                  label: 'SAMPLE RATE',
                  child: _DropdownField<int>(
                    value: settings.audioSampleRate,
                    items: const [22050, 44100, 48000, 96000],
                    labels: const ['22.05 kHz', '44.1 kHz', '48 kHz', '96 kHz'],
                    onChanged: (v) => notifier.update((s) => s.copyWith(audioSampleRate: v)),
                  ),
                ),
                _Divider(),
                _SettingRow(
                  label: 'BUFFER SIZE',
                  child: _DropdownField<int>(
                    value: settings.bufferSize,
                    items: const [64, 128, 256, 512, 1024],
                    labels: const ['64 samp', '128 samp', '256 samp', '512 samp', '1024 samp'],
                    onChanged: notifier.setBufferSize,
                  ),
                ),
                _Divider(),
                _SettingRow(
                  label: 'LATENCY',
                  child: Text(
                    '~${(settings.bufferSize / settings.audioSampleRate * 1000).toStringAsFixed(1)} ms',
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 11,
                      color: AppColors.neonGreen,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── UI ──────────────────────────────────────────────────────────
          DawPanel(
            title: 'INTERFACE',
            child: Column(
              children: [
                _SwitchRow(
                  label: 'SHOW GRID LINES',
                  value: settings.showGridLines,
                  color: AppColors.neonBlue,
                  onChanged: (_) => notifier.toggleGridLines(),
                ),
                _Divider(),
                _SwitchRow(
                  label: 'SNAP TO GRID',
                  value: settings.snapToGrid,
                  color: AppColors.neonBlue,
                  onChanged: (_) => notifier.toggleSnapToGrid(),
                ),
                _Divider(),
                _SwitchRow(
                  label: 'SHOW LEVEL METERS',
                  value: settings.showLevelMeters,
                  color: AppColors.neonGreen,
                  onChanged: (_) => notifier.toggleLevelMeters(),
                ),
                _Divider(),
                _SwitchRow(
                  label: 'SHOW WAVEFORMS',
                  value: settings.showWaveforms,
                  color: AppColors.neonGreen,
                  onChanged: (_) => notifier.toggleWaveforms(),
                ),
                _Divider(),
                _SwitchRow(
                  label: 'HAPTIC FEEDBACK',
                  value: settings.hapticFeedback,
                  color: AppColors.neonPurple,
                  onChanged: (_) => notifier.toggleHaptics(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Project ─────────────────────────────────────────────────────
          DawPanel(
            title: 'PROJECT',
            child: Column(
              children: [
                _SwitchRow(
                  label: 'AUTOSAVE',
                  value: settings.autosave,
                  color: AppColors.neonYellow,
                  onChanged: (_) => notifier.toggleAutosave(),
                ),
                if (settings.autosave) ...[
                  _Divider(),
                  _SettingRow(
                    label: 'AUTOSAVE INTERVAL',
                    child: Text(
                      '${AppConstants.autosaveIntervalS}s',
                      style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.neonYellow),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Export ──────────────────────────────────────────────────────
          DawPanel(
            title: 'EXPORT DEFAULTS',
            child: Column(
              children: [
                _SettingRow(
                  label: 'FORMAT',
                  child: _DropdownField<String>(
                    value: settings.exportFormat,
                    items: const ['wav', 'mp3', 'aac'],
                    labels: const ['WAV (lossless)', 'MP3 (compressed)', 'AAC (mobile)'],
                    onChanged: notifier.setExportFormat,
                  ),
                ),
                _Divider(),
                _SettingRow(
                  label: 'SAMPLE RATE',
                  child: _DropdownField<int>(
                    value: settings.exportSampleRate,
                    items: const [44100, 48000],
                    labels: const ['44.1 kHz', '48 kHz'],
                    onChanged: notifier.setExportSampleRate,
                  ),
                ),
                _Divider(),
                _SettingRow(
                  label: 'BIT DEPTH',
                  child: _DropdownField<int>(
                    value: settings.exportBitDepth,
                    items: const [16, 24, 32],
                    labels: const ['16-bit', '24-bit', '32-bit float'],
                    onChanged: notifier.setExportBitDepth,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── About ───────────────────────────────────────────────────────
          DawPanel(
            title: 'ABOUT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('APP', AppConstants.appName),
                _Divider(),
                _InfoRow('VERSION', AppConstants.appVersion),
                _Divider(),
                _InfoRow('ENGINE', 'STUB — see audio_utils.dart TODOs'),
                _Divider(),
                _InfoRow('THEME', 'RETRO PIXEL DARK'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Reset ───────────────────────────────────────────────────────
          NeonButton(
            label: 'RESET ALL SETTINGS',
            color: AppColors.neonRed,
            height: 44,
            onPressed: () => _confirmReset(context, notifier),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('RESET SETTINGS',
          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 13, color: AppColors.neonRed, letterSpacing: 2)),
        content: const Text('All settings will return to defaults. Projects are not affected.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
            onPressed: () {
              Navigator.pop(context);
              notifier.update((_) => const AppSettings());
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      label: label,
      child: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final List<String> labels;
  final ValueChanged<T> onChanged;
  const _DropdownField({required this.value, required this.items, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.surface,
          style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textPrimary),
          items: items.asMap().entries.map((e) => DropdownMenuItem<T>(
            value: e.value,
            child: Text(labels[e.key]),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.2)),
          ),
          Text(value,
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}
