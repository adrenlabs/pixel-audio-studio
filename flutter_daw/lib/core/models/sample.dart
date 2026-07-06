import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum SampleCategory { drums, bass, leads, pads, fx, vocals, loops, user }

/// Represents one sample in the library or user's imported files.
class Sample extends Equatable {
  final String id;
  final String name;
  final String filePath;
  final SampleCategory category;
  final double durationSeconds;
  final int bpm;           // 0 = undetected
  final String key;        // e.g. "C" or "" if unknown
  final int sampleRate;
  final bool isFavorite;
  final DateTime addedAt;
  final List<String> tags;

  const Sample({
    required this.id,
    required this.name,
    required this.filePath,
    required this.category,
    required this.durationSeconds,
    required this.bpm,
    required this.key,
    required this.sampleRate,
    required this.isFavorite,
    required this.addedAt,
    required this.tags,
  });

  factory Sample.create({
    required String name,
    required String filePath,
    required SampleCategory category,
    double durationSeconds = 0,
    int bpm = 0,
    String key = '',
    int sampleRate = 44100,
  }) {
    return Sample(
      id: const Uuid().v4(),
      name: name,
      filePath: filePath,
      category: category,
      durationSeconds: durationSeconds,
      bpm: bpm,
      key: key,
      sampleRate: sampleRate,
      isFavorite: false,
      addedAt: DateTime.now(),
      tags: [],
    );
  }

  Sample copyWith({bool? isFavorite, List<String>? tags}) => Sample(
    id: id,
    name: name,
    filePath: filePath,
    category: category,
    durationSeconds: durationSeconds,
    bpm: bpm,
    key: key,
    sampleRate: sampleRate,
    isFavorite: isFavorite ?? this.isFavorite,
    addedAt: addedAt,
    tags: tags ?? this.tags,
  );

  String get durationFormatted {
    if (durationSeconds < 60) {
      return '${durationSeconds.toStringAsFixed(1)}s';
    }
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$s';
  }

  @override
  List<Object?> get props => [id, name, filePath, isFavorite];
}

/// Dummy sample library used in the browser when no real files are present.
class SampleLibrary {
  static List<Sample> get builtinSamples => [
    _make('KICK 01',    'assets/samples/kick_01.wav',   SampleCategory.drums,  0.35, 120),
    _make('KICK 02',    'assets/samples/kick_02.wav',   SampleCategory.drums,  0.40, 140),
    _make('SNARE 01',   'assets/samples/snare_01.wav',  SampleCategory.drums,  0.28, 120),
    _make('SNARE 808',  'assets/samples/snare_808.wav', SampleCategory.drums,  0.55, 140),
    _make('HH CLOSED',  'assets/samples/hh_cl.wav',    SampleCategory.drums,  0.12, 120),
    _make('HH OPEN',    'assets/samples/hh_op.wav',    SampleCategory.drums,  0.45, 120),
    _make('CLAP',       'assets/samples/clap.wav',     SampleCategory.drums,  0.20, 120),
    _make('808 BASS A', 'assets/samples/808_a.wav',    SampleCategory.bass,   1.20, 140, 'A'),
    _make('808 BASS C', 'assets/samples/808_c.wav',    SampleCategory.bass,   1.20, 140, 'C'),
    _make('DEEP BASS',  'assets/samples/deepbass.wav', SampleCategory.bass,   0.90, 120),
    _make('LEAD SAW',   'assets/samples/lead_saw.wav', SampleCategory.leads,  2.00, 128, 'C'),
    _make('LEAD SQ',    'assets/samples/lead_sq.wav',  SampleCategory.leads,  2.00, 128, 'G'),
    _make('PAD DREAM',  'assets/samples/pad_dream.wav',SampleCategory.pads,   4.00,   0, 'Am'),
    _make('PAD SPACE',  'assets/samples/pad_space.wav',SampleCategory.pads,   4.00,   0, 'Dm'),
    _make('RISER',      'assets/samples/riser.wav',    SampleCategory.fx,     4.00, 128),
    _make('CRASH',      'assets/samples/crash.wav',    SampleCategory.fx,     1.80, 120),
    _make('LOOP FUNK',  'assets/samples/loop_funk.wav',SampleCategory.loops,  2.00, 120),
    _make('LOOP SOUL',  'assets/samples/loop_soul.wav',SampleCategory.loops,  4.00,  90, 'Fm'),
  ];

  static Sample _make(
    String name,
    String path,
    SampleCategory cat,
    double dur,
    int bpm, [
    String key = '',
  ]) {
    return Sample(
      id: const Uuid().v4(),
      name: name,
      filePath: path,
      category: cat,
      durationSeconds: dur,
      bpm: bpm,
      key: key,
      sampleRate: 44100,
      isFavorite: false,
      addedAt: DateTime.now(),
      tags: [],
    );
  }
}
