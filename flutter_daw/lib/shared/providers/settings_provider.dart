import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String theme;           // 'dark' (only for now)
  final int audioSampleRate;
  final int bufferSize;
  final bool showGridLines;
  final bool snapToGrid;
  final bool autosave;
  final bool hapticFeedback;
  final String exportFormat;    // 'wav' | 'mp3' | 'aac'
  final int exportSampleRate;
  final int exportBitDepth;
  final bool showLevelMeters;
  final bool showWaveforms;

  const AppSettings({
    this.theme = 'dark',
    this.audioSampleRate = 44100,
    this.bufferSize = 256,
    this.showGridLines = true,
    this.snapToGrid = true,
    this.autosave = true,
    this.hapticFeedback = true,
    this.exportFormat = 'wav',
    this.exportSampleRate = 44100,
    this.exportBitDepth = 24,
    this.showLevelMeters = true,
    this.showWaveforms = true,
  });

  AppSettings copyWith({
    String? theme,
    int? audioSampleRate,
    int? bufferSize,
    bool? showGridLines,
    bool? snapToGrid,
    bool? autosave,
    bool? hapticFeedback,
    String? exportFormat,
    int? exportSampleRate,
    int? exportBitDepth,
    bool? showLevelMeters,
    bool? showWaveforms,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      bufferSize: bufferSize ?? this.bufferSize,
      showGridLines: showGridLines ?? this.showGridLines,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      autosave: autosave ?? this.autosave,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      exportFormat: exportFormat ?? this.exportFormat,
      exportSampleRate: exportSampleRate ?? this.exportSampleRate,
      exportBitDepth: exportBitDepth ?? this.exportBitDepth,
      showLevelMeters: showLevelMeters ?? this.showLevelMeters,
      showWaveforms: showWaveforms ?? this.showWaveforms,
    );
  }

  Map<String, dynamic> toMap() => {
    'theme': theme,
    'audioSampleRate': audioSampleRate,
    'bufferSize': bufferSize,
    'showGridLines': showGridLines,
    'snapToGrid': snapToGrid,
    'autosave': autosave,
    'hapticFeedback': hapticFeedback,
    'exportFormat': exportFormat,
    'exportSampleRate': exportSampleRate,
    'exportBitDepth': exportBitDepth,
    'showLevelMeters': showLevelMeters,
    'showWaveforms': showWaveforms,
  };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
    theme: m['theme'] as String? ?? 'dark',
    audioSampleRate: m['audioSampleRate'] as int? ?? 44100,
    bufferSize: m['bufferSize'] as int? ?? 256,
    showGridLines: m['showGridLines'] as bool? ?? true,
    snapToGrid: m['snapToGrid'] as bool? ?? true,
    autosave: m['autosave'] as bool? ?? true,
    hapticFeedback: m['hapticFeedback'] as bool? ?? true,
    exportFormat: m['exportFormat'] as String? ?? 'wav',
    exportSampleRate: m['exportSampleRate'] as int? ?? 44100,
    exportBitDepth: m['exportBitDepth'] as int? ?? 24,
    showLevelMeters: m['showLevelMeters'] as bool? ?? true,
    showWaveforms: m['showWaveforms'] as bool? ?? true,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _prefKey = 'app_settings';

  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys  = prefs.getKeys();
      final map   = <String, dynamic>{};
      for (final k in ['theme','audioSampleRate','bufferSize','showGridLines',
        'snapToGrid','autosave','hapticFeedback','exportFormat',
        'exportSampleRate','exportBitDepth','showLevelMeters','showWaveforms']) {
        if (keys.contains('$_prefKey/$k')) {
          final v = prefs.get('$_prefKey/$k');
          if (v != null) map[k] = v;
        }
      }
      if (map.isNotEmpty) state = AppSettings.fromMap(map);
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map   = state.toMap();
    for (final e in map.entries) {
      final key = '$_prefKey/${e.key}';
      final v   = e.value;
      if (v is bool)   await prefs.setBool(key, v);
      if (v is int)    await prefs.setInt(key, v);
      if (v is String) await prefs.setString(key, v);
      if (v is double) await prefs.setDouble(key, v);
    }
  }

  void update(AppSettings Function(AppSettings) updater) {
    state = updater(state);
    _save();
  }

  void toggleSnapToGrid()    => update((s) => s.copyWith(snapToGrid: !s.snapToGrid));
  void toggleGridLines()     => update((s) => s.copyWith(showGridLines: !s.showGridLines));
  void toggleAutosave()      => update((s) => s.copyWith(autosave: !s.autosave));
  void toggleHaptics()       => update((s) => s.copyWith(hapticFeedback: !s.hapticFeedback));
  void toggleLevelMeters()   => update((s) => s.copyWith(showLevelMeters: !s.showLevelMeters));
  void toggleWaveforms()     => update((s) => s.copyWith(showWaveforms: !s.showWaveforms));
  void setBufferSize(int v)  => update((s) => s.copyWith(bufferSize: v));
  void setExportFormat(String f) => update((s) => s.copyWith(exportFormat: f));
  void setExportSampleRate(int r) => update((s) => s.copyWith(exportSampleRate: r));
  void setExportBitDepth(int d)   => update((s) => s.copyWith(exportBitDepth: d));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (ref) => SettingsNotifier());
