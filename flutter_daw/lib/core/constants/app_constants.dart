/// Global app constants and audio configuration defaults.
class AppConstants {
  AppConstants._();

  static const String appName    = 'PIXEL DAW';
  static const String appVersion = '1.0.0';

  // ─── Audio Engine ─────────────────────────────────────────────────────────
  static const int    defaultBpm        = 120;
  static const int    defaultBars       = 4;
  static const int    defaultBeatsPerBar = 4;
  static const int    defaultSubdivisions = 16; // 1/16 steps
  static const double defaultVolume     = 0.8;
  static const double defaultPan        = 0.0;   // center
  static const int    defaultSampleRate = 44100;
  static const int    defaultBitDepth   = 24;
  static const int    defaultBufferSize = 256;   // samples

  // ─── Project ──────────────────────────────────────────────────────────────
  static const int maxTracks         = 32;
  static const int maxBeatsPerStep   = 8;
  static const int defaultStepCount  = 16;
  static const int autosaveIntervalS = 60; // seconds

  // ─── Beat Maker ───────────────────────────────────────────────────────────
  static const int defaultPadRows    = 4;
  static const int defaultPadCols    = 4;
  static const int totalPads         = 16;
  static const List<String> drumPadLabels = [
    'KICK', 'SNARE', 'HI-HAT', 'OPEN-HH',
    'CLAP',  'RIM',   'TOM-HI', 'TOM-LO',
    'CRASH', 'RIDE',  'PERC-1', 'PERC-2',
    'FX-1',  'FX-2',  'SFX-1',  'SFX-2',
  ];

  // ─── Piano Roll ───────────────────────────────────────────────────────────
  static const int    pianoRollOctaves   = 8;
  static const int    pianoRollStartOct  = 1;
  static const double pianoKeyHeight     = 28.0;
  static const double pianoKeyWidth      = 48.0;
  static const double cellWidth          = 32.0;

  // ─── Mixer ────────────────────────────────────────────────────────────────
  static const int    maxChannels   = 16;
  static const int    maxFxSlots    = 8;
  static const double faderHeight   = 160.0;
  static const double channelWidth  = 64.0;

  // ─── UI ───────────────────────────────────────────────────────────────────
  static const double cornerRadius  = 4.0;
  static const double panelPadding  = 8.0;
  static const double gridLineWidth = 0.5;

  // ─── Effect Names ─────────────────────────────────────────────────────────
  static const List<String> effectNames = [
    'EQ',       'COMPRESSOR', 'REVERB',   'DELAY',
    'CHORUS',   'FLANGER',    'DISTORT',  'LIMITER',
    'FILTER',   'PITCH',      'BITCRUSH', 'STEREO',
  ];

  // ─── Instrument Presets ───────────────────────────────────────────────────
  static const List<String> instrumentPresets = [
    'INIT SYNTH', '808 BASS', 'LEAD SAWTOOTH', 'PAD DREAM',
    'PLUCK', 'BRASS', 'ORGAN', 'EP CLEAN',
    'STRINGS', 'CHOIR', 'BELL', 'FX RISER',
  ];

  // ─── File Extensions ──────────────────────────────────────────────────────
  static const List<String> audioExtensions = [
    'wav', 'mp3', 'aac', 'ogg', 'flac', 'm4a',
  ];
  static const String projectExtension = '.pdaw';
}
