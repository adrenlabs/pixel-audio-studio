import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// A single row of on/off steps for one drum pad.
class BeatRow extends Equatable {
  final String id;
  final String padName;
  final String samplePath;
  final List<bool> steps;       // length == stepCount
  final double volume;
  final double pan;

  const BeatRow({
    required this.id,
    required this.padName,
    required this.samplePath,
    required this.steps,
    required this.volume,
    required this.pan,
  });

  factory BeatRow.create({
    required String padName,
    required String samplePath,
    int stepCount = AppConstants.defaultStepCount,
  }) {
    return BeatRow(
      id: const Uuid().v4(),
      padName: padName,
      samplePath: samplePath,
      steps: List.filled(stepCount, false),
      volume: 0.8,
      pan: 0.0,
    );
  }

  BeatRow toggleStep(int index) {
    final updated = List<bool>.from(steps);
    updated[index] = !updated[index];
    return BeatRow(
      id: id,
      padName: padName,
      samplePath: samplePath,
      steps: updated,
      volume: volume,
      pan: pan,
    );
  }

  BeatRow copyWith({
    List<bool>? steps,
    double? volume,
    double? pan,
  }) {
    return BeatRow(
      id: id,
      padName: padName,
      samplePath: samplePath,
      steps: steps ?? this.steps,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'padName': padName,
    'samplePath': samplePath,
    'steps': steps,
    'volume': volume,
    'pan': pan,
  };

  factory BeatRow.fromJson(Map<String, dynamic> json) => BeatRow(
    id: json['id'] as String,
    padName: json['padName'] as String,
    samplePath: json['samplePath'] as String,
    steps: List<bool>.from(json['steps'] as List),
    volume: (json['volume'] as num).toDouble(),
    pan: (json['pan'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [id, padName, steps];
}

/// A full beat pattern (typically 16 steps × N drum rows).
class BeatPattern extends Equatable {
  final String id;
  final String name;
  final int bpm;
  final int stepCount;
  final List<BeatRow> rows;
  final int currentStep;   // playback position (0-based)
  final bool isPlaying;

  const BeatPattern({
    required this.id,
    required this.name,
    required this.bpm,
    required this.stepCount,
    required this.rows,
    required this.currentStep,
    required this.isPlaying,
  });

  factory BeatPattern.create({
    String name = 'Pattern 1',
    int bpm = 120,
    int stepCount = 16,
  }) {
    final rows = AppConstants.drumPadLabels.asMap().entries.map((e) {
      return BeatRow.create(
        padName: e.value,
        samplePath: 'assets/samples/${e.value.toLowerCase().replaceAll(' ', '_')}.wav',
        stepCount: stepCount,
      );
    }).toList();

    return BeatPattern(
      id: const Uuid().v4(),
      name: name,
      bpm: bpm,
      stepCount: stepCount,
      rows: rows,
      currentStep: -1,
      isPlaying: false,
    );
  }

  /// Returns a default pattern with a standard four-on-the-floor kick pattern.
  factory BeatPattern.defaultHiphop() {
    final pattern = BeatPattern.create(name: 'Hip-Hop 1');
    // Kick on beats 1 and 3 (index 0 and 8 for 16-step)
    final kickRow = pattern.rows[0].copyWith(
      steps: _stepMask([0, 8], 16),
    );
    // Snare on beats 2 and 4
    final snareRow = pattern.rows[1].copyWith(
      steps: _stepMask([4, 12], 16),
    );
    // Closed HH on every even step
    final hhRow = pattern.rows[2].copyWith(
      steps: _stepMask([0, 2, 4, 6, 8, 10, 12, 14], 16),
    );
    final updatedRows = [...pattern.rows];
    updatedRows[0] = kickRow;
    updatedRows[1] = snareRow;
    updatedRows[2] = hhRow;
    return pattern.copyWith(rows: updatedRows);
  }

  static List<bool> _stepMask(List<int> onBeats, int total) {
    final steps = List.filled(total, false);
    for (final i in onBeats) { steps[i] = true; }
    return steps;
  }

  BeatPattern copyWith({
    String? name,
    int? bpm,
    int? stepCount,
    List<BeatRow>? rows,
    int? currentStep,
    bool? isPlaying,
  }) {
    return BeatPattern(
      id: id,
      name: name ?? this.name,
      bpm: bpm ?? this.bpm,
      stepCount: stepCount ?? this.stepCount,
      rows: rows ?? this.rows,
      currentStep: currentStep ?? this.currentStep,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  List<Object?> get props => [id, name, bpm, rows, currentStep, isPlaying];
}
