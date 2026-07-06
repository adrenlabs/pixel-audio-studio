import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'track.dart';

/// Top-level project model – everything needed to recreate a session.
class Project extends Equatable {
  final String id;
  final String name;
  final int bpm;
  final int beatsPerBar;
  final int bars;
  final List<Track> tracks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverPath;
  final String templateName;
  final bool isSaved;

  const Project({
    required this.id,
    required this.name,
    required this.bpm,
    required this.beatsPerBar,
    required this.bars,
    required this.tracks,
    required this.createdAt,
    required this.updatedAt,
    this.coverPath,
    this.templateName = 'blank',
    this.isSaved = false,
  });

  factory Project.create({String name = 'Untitled Project'}) {
    final now = DateTime.now();
    return Project(
      id: const Uuid().v4(),
      name: name,
      bpm: 120,
      beatsPerBar: 4,
      bars: 4,
      tracks: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a project from one of the built-in templates.
  factory Project.fromTemplate(String templateName) {
    final base = Project.create(name: 'New ${templateName.toUpperCase()}');
    return base.copyWith(templateName: templateName);
  }

  Project copyWith({
    String? id,
    String? name,
    int? bpm,
    int? beatsPerBar,
    int? bars,
    List<Track>? tracks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverPath,
    String? templateName,
    bool? isSaved,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      bpm: bpm ?? this.bpm,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      bars: bars ?? this.bars,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverPath: coverPath ?? this.coverPath,
      templateName: templateName ?? this.templateName,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bpm': bpm,
    'beatsPerBar': beatsPerBar,
    'bars': bars,
    'tracks': tracks.map((t) => t.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'coverPath': coverPath,
    'templateName': templateName,
    'isSaved': isSaved,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    bpm: json['bpm'] as int,
    beatsPerBar: json['beatsPerBar'] as int,
    bars: json['bars'] as int,
    tracks: (json['tracks'] as List)
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    coverPath: json['coverPath'] as String?,
    templateName: json['templateName'] as String? ?? 'blank',
    isSaved: json['isSaved'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, name, bpm, tracks, updatedAt];
}

/// Available project templates shown in the home screen.
enum ProjectTemplate {
  blank('BLANK', 'Empty project'),
  hiphop('HIP-HOP', '808 drums + bass preset'),
  edm('EDM', 'Four-on-floor + synth leads'),
  lofi('LO-FI', 'Vinyl drums + chords'),
  trap('TRAP', 'Hi-hat roll + 808 bass'),
  ambient('AMBIENT', 'Pads + atmosphere');

  final String label;
  final String description;
  const ProjectTemplate(this.label, this.description);
}
