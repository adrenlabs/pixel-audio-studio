// ─────────────────────────────────────────────────────────────────────────────
// audio_utils.dart
// Pure utility helpers for audio math, format conversion, and UI helpers.
// Real audio-engine calls are stubbed and marked TODO.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;

class AudioUtils {
  AudioUtils._();

  // ─── Decibel / Linear ──────────────────────────────────────────────────────

  /// Convert a linear amplitude (0.0–1.0) to dBFS.
  static double linearToDb(double linear) {
    if (linear <= 0.0) return -96.0;
    return 20.0 * math.log(linear) / math.ln10;
  }

  /// Convert dBFS to linear (0.0–1.0).  Clamps at -96 dB.
  static double dbToLinear(double db) {
    if (db <= -96.0) return 0.0;
    return math.pow(10.0, db / 20.0).toDouble();
  }

  /// Clamp a linear value to [0.0, 1.0].
  static double clampLinear(double v) => v.clamp(0.0, 1.0);

  // ─── BPM / Time ────────────────────────────────────────────────────────────

  /// Duration of one beat in milliseconds given a BPM.
  static double beatDurationMs(int bpm) => 60000.0 / bpm;

  /// Duration of one 1/16 step in milliseconds.
  static double stepDurationMs(int bpm) => beatDurationMs(bpm) / 4.0;

  /// Convert a beat position to a time string (bar:beat).
  static String beatToTimeString(double beat, int beatsPerBar) {
    final bar  = (beat / beatsPerBar).floor() + 1;
    final b    = (beat % beatsPerBar).floor() + 1;
    return '$bar:$b';
  }

  /// Convert seconds to a mm:ss.ms display string.
  static String secondsToDisplay(double seconds) {
    final m  = (seconds / 60).floor().toString().padLeft(2, '0');
    final s  = (seconds % 60).floor().toString().padLeft(2, '0');
    final ms = ((seconds % 1) * 100).floor().toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  // ─── Note / MIDI ───────────────────────────────────────────────────────────

  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// MIDI note number → display string, e.g. 60 → "C4".
  static String midiToNoteName(int midi) {
    final note   = noteNames[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$note$octave';
  }

  /// Display string → MIDI note number.
  static int noteNameToMidi(String name) {
    final match = RegExp(r'([A-G]#?)(-?\d+)').firstMatch(name);
    if (match == null) return 60;
    final noteIdx = noteNames.indexOf(match.group(1)!);
    final octave  = int.parse(match.group(2)!);
    return noteIdx + (octave + 1) * 12;
  }

  /// Frequency (Hz) for a given MIDI note number.
  static double midiToFrequency(int midi) =>
      440.0 * math.pow(2.0, (midi - 69) / 12.0);

  // ─── Pan ───────────────────────────────────────────────────────────────────

  /// Convert a -1.0…+1.0 pan to a display label ("L50", "C", "R50").
  static String panLabel(double pan) {
    if (pan.abs() < 0.02) return 'C';
    final pct = (pan.abs() * 100).round();
    return pan < 0 ? 'L$pct' : 'R$pct';
  }

  // ─── Waveform ──────────────────────────────────────────────────────────────

  /// Generate a list of N amplitude values simulating a waveform
  /// (used for display when the real audio data is not yet loaded).
  static List<double> fakeWaveform(int points, {double seed = 0}) {
    final rng = math.Random((seed * 1000).toInt());
    final List<double> wave = [];
    double phase = 0;
    for (int i = 0; i < points; i++) {
      phase += rng.nextDouble() * 0.3 + 0.05;
      wave.add((math.sin(phase) * 0.5 + rng.nextDouble() * 0.5).clamp(0.0, 1.0).toDouble());
    }
    return wave;
  }

  // ─── TODO: Real audio engine stubs ────────────────────────────────────────
  // The following methods are stubs.  Replace the bodies with calls to
  // the platform audio engine once the native plugin is integrated.

  /// TODO: Load an audio file at [path] into the engine. Returns a handle.
  static Future<String?> loadAudioFile(String path) async {
    // TODO: call AudioEngine.load(path)
    return 'stub_handle_${path.hashCode}';
  }

  /// TODO: Play the sample with [handle] at [volume] and [pitch] cents.
  static Future<void> playSample(
    String handle, {
    double volume = 1.0,
    double pitch  = 0.0,
  }) async {
    // TODO: AudioEngine.play(handle, volume: volume, pitch: pitch)
  }

  /// TODO: Stop all audio engine playback.
  static Future<void> stopAll() async {
    // TODO: AudioEngine.stopAll()
  }

  /// TODO: Set master BPM on the engine clock.
  static Future<void> setBpm(int bpm) async {
    // TODO: AudioEngine.setBpm(bpm)
  }

  /// TODO: Export the current session to a WAV/MP3 file at [outputPath].
  static Future<String?> exportMix({
    required String outputPath,
    required String format,   // 'wav' | 'mp3' | 'aac'
    required int sampleRate,
    required int bitDepth,
  }) async {
    // TODO: AudioEngine.renderOffline(...)
    return null;
  }
}
