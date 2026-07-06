import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

enum TrackType { audio, midi, drum, bus }

/// Represents a single timeline track (audio, MIDI, or drum).
class Track extends Equatable {
  final String id;
  final String name;
  final TrackType type;
  final Color color;
  final double volume;    // 0.0 – 1.0
  final double pan;       // -1.0 (L) to +1.0 (R)
  final bool muted;
  final bool soloed;
  final bool armed;       // recording arm
  final int order;
  final List<TrackClip> clips;
  final List<EffectSlot> effects;

  const Track({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.volume,
    required this.pan,
    required this.muted,
    required this.soloed,
    required this.armed,
    required this.order,
    required this.clips,
    required this.effects,
  });

  factory Track.create({
    required String name,
    required TrackType type,
    required Color color,
    required int order,
  }) {
    return Track(
      id: const Uuid().v4(),
      name: name,
      type: type,
      color: color,
      volume: AppConstants.defaultVolume,
      pan: AppConstants.defaultPan,
      muted: false,
      soloed: false,
      armed: false,
      order: order,
      clips: [],
      effects: [],
    );
  }

  Track copyWith({
    String? id,
    String? name,
    TrackType? type,
    Color? color,
    double? volume,
    double? pan,
    bool? muted,
    bool? soloed,
    bool? armed,
    int? order,
    List<TrackClip>? clips,
    List<EffectSlot>? effects,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      muted: muted ?? this.muted,
      soloed: soloed ?? this.soloed,
      armed: armed ?? this.armed,
      order: order ?? this.order,
      clips: clips ?? this.clips,
      effects: effects ?? this.effects,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'color': color.value,
    'volume': volume,
    'pan': pan,
    'muted': muted,
    'soloed': soloed,
    'armed': armed,
    'order': order,
    'clips': clips.map((c) => c.toJson()).toList(),
    'effects': effects.map((e) => e.toJson()).toList(),
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TrackType.values.byName(json['type'] as String),
    color: Color(json['color'] as int),
    volume: (json['volume'] as num).toDouble(),
    pan: (json['pan'] as num).toDouble(),
    muted: json['muted'] as bool,
    soloed: json['soloed'] as bool,
    armed: json['armed'] as bool,
    order: json['order'] as int,
    clips: (json['clips'] as List)
        .map((c) => TrackClip.fromJson(c as Map<String, dynamic>))
        .toList(),
    effects: (json['effects'] as List)
        .map((e) => EffectSlot.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  List<Object?> get props => [id, name, type, muted, soloed, volume, pan];
}

/// A single audio/MIDI clip placed on a track timeline.
class TrackClip extends Equatable {
  final String id;
  final String name;
  final double startBeat;   // position in beats
  final double durationBeats;
  final String? filePath;   // for audio clips
  final Color? clipColor;

  const TrackClip({
    required this.id,
    required this.name,
    required this.startBeat,
    required this.durationBeats,
    this.filePath,
    this.clipColor,
  });

  factory TrackClip.create({
    required String name,
    required double startBeat,
    required double durationBeats,
    String? filePath,
    Color? color,
  }) {
    return TrackClip(
      id: const Uuid().v4(),
      name: name,
      startBeat: startBeat,
      durationBeats: durationBeats,
      filePath: filePath,
      clipColor: color,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startBeat': startBeat,
    'durationBeats': durationBeats,
    'filePath': filePath,
    'clipColor': clipColor?.value,
  };

  factory TrackClip.fromJson(Map<String, dynamic> json) => TrackClip(
    id: json['id'] as String,
    name: json['name'] as String,
    startBeat: (json['startBeat'] as num).toDouble(),
    durationBeats: (json['durationBeats'] as num).toDouble(),
    filePath: json['filePath'] as String?,
    clipColor: json['clipColor'] != null ? Color(json['clipColor'] as int) : null,
  );

  @override
  List<Object?> get props => [id, startBeat, durationBeats];
}

/// One slot in a track's effect chain.
class EffectSlot extends Equatable {
  final String id;
  final String effectName;
  final bool enabled;
  final Map<String, double> params;

  const EffectSlot({
    required this.id,
    required this.effectName,
    required this.enabled,
    required this.params,
  });

  factory EffectSlot.create(String effectName) => EffectSlot(
    id: const Uuid().v4(),
    effectName: effectName,
    enabled: true,
    params: {},
  );

  EffectSlot copyWith({bool? enabled, Map<String, double>? params}) =>
    EffectSlot(
      id: id,
      effectName: effectName,
      enabled: enabled ?? this.enabled,
      params: params ?? this.params,
    );

  Map<String, dynamic> toJson() => {
    'id': id,
    'effectName': effectName,
    'enabled': enabled,
    'params': params,
  };

  factory EffectSlot.fromJson(Map<String, dynamic> json) => EffectSlot(
    id: json['id'] as String,
    effectName: json['effectName'] as String,
    enabled: json['enabled'] as bool,
    params: Map<String, double>.from(json['params'] as Map),
  );

  @override
  List<Object?> get props => [id, effectName, enabled];
}
