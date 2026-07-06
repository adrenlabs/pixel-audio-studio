import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/beat_pattern.dart';
import '../../core/utils/audio_utils.dart';

enum PlaybackState { stopped, playing, paused, recording }

class AudioState {
  final PlaybackState playback;
  final int bpm;
  final double masterVolume;
  final double playheadBeat;
  final bool metronomeEnabled;
  final bool loopEnabled;
  final double loopStartBeat;
  final double loopEndBeat;

  const AudioState({
    this.playback = PlaybackState.stopped,
    this.bpm = 120,
    this.masterVolume = 0.8,
    this.playheadBeat = 0.0,
    this.metronomeEnabled = false,
    this.loopEnabled = false,
    this.loopStartBeat = 0.0,
    this.loopEndBeat = 16.0,
  });

  AudioState copyWith({
    PlaybackState? playback,
    int? bpm,
    double? masterVolume,
    double? playheadBeat,
    bool? metronomeEnabled,
    bool? loopEnabled,
    double? loopStartBeat,
    double? loopEndBeat,
  }) {
    return AudioState(
      playback: playback ?? this.playback,
      bpm: bpm ?? this.bpm,
      masterVolume: masterVolume ?? this.masterVolume,
      playheadBeat: playheadBeat ?? this.playheadBeat,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      loopEnabled: loopEnabled ?? this.loopEnabled,
      loopStartBeat: loopStartBeat ?? this.loopStartBeat,
      loopEndBeat: loopEndBeat ?? this.loopEndBeat,
    );
  }

  bool get isPlaying => playback == PlaybackState.playing;
  bool get isRecording => playback == PlaybackState.recording;
}

class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState());

  void play() {
    state = state.copyWith(playback: PlaybackState.playing);
    AudioUtils.setBpm(state.bpm); // stub
    // TODO: start engine clock
  }

  void pause() {
    state = state.copyWith(playback: PlaybackState.paused);
    // TODO: engine.pause()
  }

  void stop() {
    state = state.copyWith(playback: PlaybackState.stopped, playheadBeat: 0.0);
    AudioUtils.stopAll(); // stub
    // TODO: engine.stop(), reset clock
  }

  void togglePlay() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void startRecording() {
    state = state.copyWith(playback: PlaybackState.recording);
    // TODO: record.start()
  }

  void stopRecording() {
    state = state.copyWith(playback: PlaybackState.stopped);
    // TODO: record.stop()
  }

  void setBpm(int bpm) {
    state = state.copyWith(bpm: bpm.clamp(20, 300).toInt());
    AudioUtils.setBpm(state.bpm);
  }

  void setMasterVolume(double vol) {
    state = state.copyWith(masterVolume: vol.clamp(0.0, 1.0).toDouble());
    // TODO: engine.setMasterVolume(vol)
  }

  void setPlayhead(double beat) {
    state = state.copyWith(playheadBeat: beat.clamp(0.0, double.infinity).toDouble());
  }

  void toggleMetronome() {
    state = state.copyWith(metronomeEnabled: !state.metronomeEnabled);
  }

  void toggleLoop() {
    state = state.copyWith(loopEnabled: !state.loopEnabled);
  }

  void setLoopRange(double start, double end) {
    state = state.copyWith(loopStartBeat: start, loopEndBeat: end);
  }
}

final audioProvider =
    StateNotifierProvider<AudioNotifier, AudioState>((ref) => AudioNotifier());

// ─── Beat Pattern provider ─────────────────────────────────────────────────────
class BeatPatternNotifier extends StateNotifier<BeatPattern> {
  BeatPatternNotifier() : super(BeatPattern.defaultHiphop());

  void toggleStep(int rowIndex, int stepIndex) {
    final updated = state.rows[rowIndex].toggleStep(stepIndex);
    final rows = [...state.rows];
    rows[rowIndex] = updated;
    state = state.copyWith(rows: rows);
  }

  void setRowVolume(int rowIndex, double volume) {
    final rows = [...state.rows];
    rows[rowIndex] = rows[rowIndex].copyWith(volume: volume);
    state = state.copyWith(rows: rows);
  }

  void setBpm(int bpm) {
    state = state.copyWith(bpm: bpm);
  }

  void clearAll() {
    final rows = state.rows.map((r) =>
      r.copyWith(steps: List.filled(r.steps.length, false))
    ).toList();
    state = state.copyWith(rows: rows);
  }

  void randomize() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    final rows = state.rows.asMap().entries.map((e) {
      final seed = rng + e.key * 13;
      final steps = List.generate(e.value.steps.length, (i) {
        // Kick on 0,8 with high probability; others random
        if (e.key == 0 && (i == 0 || i == 8)) return true;
        return ((seed + i * 7) % 5) == 0;
      });
      return e.value.copyWith(steps: steps);
    }).toList();
    state = state.copyWith(rows: rows);
  }

  void advanceStep() {
    final next = (state.currentStep + 1) % state.stepCount;
    state = state.copyWith(currentStep: next);
    // TODO: trigger samples for active steps at state.rows[*].steps[next]
  }
}

final beatPatternProvider =
    StateNotifierProvider<BeatPatternNotifier, BeatPattern>(
        (ref) => BeatPatternNotifier());
