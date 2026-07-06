import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/project.dart';
import '../../core/models/track.dart';
import '../../core/theme/app_colors.dart';

// ─── History entry for undo/redo ──────────────────────────────────────────────
class _HistoryEntry {
  final Project project;
  const _HistoryEntry(this.project);
}

// ─── State ────────────────────────────────────────────────────────────────────
class ProjectState {
  final Project? currentProject;
  final List<Project> recentProjects;
  final bool isDirty;
  final bool isLoading;
  final String? errorMessage;

  const ProjectState({
    this.currentProject,
    this.recentProjects = const [],
    this.isDirty = false,
    this.isLoading = false,
    this.errorMessage,
  });

  ProjectState copyWith({
    Project? currentProject,
    List<Project>? recentProjects,
    bool? isDirty,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProjectState(
      currentProject: currentProject ?? this.currentProject,
      recentProjects: recentProjects ?? this.recentProjects,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class ProjectNotifier extends StateNotifier<ProjectState> {
  static const _prefKeyRecent  = 'recent_projects';
  static const _prefKeyProject = 'current_project';
  static const _maxUndoSteps   = 50;

  final List<_HistoryEntry> _undoStack = [];
  final List<_HistoryEntry> _redoStack = [];

  ProjectNotifier() : super(const ProjectState()) {
    _loadRecent();
  }

  // ─── Create / Open ──────────────────────────────────────────────────────────

  void createProject({String name = 'Untitled Project'}) {
    final p = Project.create(name: name);
    _undoStack.clear();
    _redoStack.clear();
    state = state.copyWith(currentProject: p, isDirty: true);
  }

  void createFromTemplate(ProjectTemplate template) {
    final p = Project.fromTemplate(template.label)
        .copyWith(name: 'New ${template.label}');
    // Seed default tracks based on template
    final tracks = _defaultTracksForTemplate(template);
    final seeded = p.copyWith(tracks: tracks);
    _undoStack.clear();
    _redoStack.clear();
    state = state.copyWith(currentProject: seeded, isDirty: true);
  }

  void openProject(Project project) {
    _undoStack.clear();
    _redoStack.clear();
    state = state.copyWith(currentProject: project, isDirty: false);
  }

  // ─── Tracks ────────────────────────────────────────────────────────────────

  void addTrack(TrackType type) {
    final project = state.currentProject;
    if (project == null) return;
    _pushUndo(project);

    final colors  = AppColors.trackColors;
    final color   = colors[project.tracks.length % colors.length];
    final idx     = project.tracks.length + 1;
    final names   = {TrackType.audio: 'Audio', TrackType.midi: 'MIDI', TrackType.drum: 'Drum', TrackType.bus: 'Bus'};
    final track   = Track.create(
      name: '${names[type]} $idx',
      type: type,
      color: color,
      order: project.tracks.length,
    );
    final updated = project.copyWith(
      tracks: [...project.tracks, track],
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(currentProject: updated, isDirty: true);
  }

  void removeTrack(String trackId) {
    final project = state.currentProject;
    if (project == null) return;
    _pushUndo(project);

    final updated = project.copyWith(
      tracks: project.tracks.where((t) => t.id != trackId).toList(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(currentProject: updated, isDirty: true);
  }

  void updateTrack(Track track) {
    final project = state.currentProject;
    if (project == null) return;
    final updated = project.copyWith(
      tracks: project.tracks.map((t) => t.id == track.id ? track : t).toList(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(currentProject: updated, isDirty: true);
  }

  // ─── Project metadata ──────────────────────────────────────────────────────

  void setBpm(int bpm) {
    final project = state.currentProject;
    if (project == null) return;
    _pushUndo(project);
    state = state.copyWith(
      currentProject: project.copyWith(bpm: bpm, updatedAt: DateTime.now()),
      isDirty: true,
    );
  }

  void renameProject(String name) {
    final project = state.currentProject;
    if (project == null) return;
    state = state.copyWith(
      currentProject: project.copyWith(name: name, updatedAt: DateTime.now()),
      isDirty: true,
    );
  }

  // ─── Save / Load ───────────────────────────────────────────────────────────

  Future<void> saveProject() async {
    final project = state.currentProject;
    if (project == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final prefs   = await SharedPreferences.getInstance();
      final saved   = project.copyWith(isSaved: true, updatedAt: DateTime.now());
      final encoded = jsonEncode(saved.toJson());
      await prefs.setString(_prefKeyProject, encoded);

      // Prepend to recents
      final recents = [
        saved,
        ...state.recentProjects.where((p) => p.id != saved.id),
      ].take(10).toList();

      final recentsJson = jsonEncode(recents.map((p) => p.toJson()).toList());
      await prefs.setString(_prefKeyRecent, recentsJson);

      state = state.copyWith(
        currentProject: saved,
        recentProjects: recents,
        isDirty: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Save failed: $e');
    }
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_prefKeyRecent);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(recentProjects: list);
      }
    } catch (_) {}
  }

  // ─── Undo / Redo ───────────────────────────────────────────────────────────

  void undo() {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeLast();
    if (state.currentProject != null) {
      _redoStack.add(_HistoryEntry(state.currentProject!));
    }
    state = state.copyWith(currentProject: entry.project, isDirty: true);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final entry = _redoStack.removeLast();
    if (state.currentProject != null) {
      _undoStack.add(_HistoryEntry(state.currentProject!));
    }
    state = state.copyWith(currentProject: entry.project, isDirty: true);
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushUndo(Project project) {
    _undoStack.add(_HistoryEntry(project));
    _redoStack.clear();
    if (_undoStack.length > _maxUndoSteps) _undoStack.removeAt(0);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  List<Track> _defaultTracksForTemplate(ProjectTemplate t) {
    final colors = AppColors.trackColors;
    switch (t) {
      case ProjectTemplate.hiphop:
      case ProjectTemplate.trap:
        return [
          Track.create(name: 'DRUMS', type: TrackType.drum,  color: colors[0], order: 0),
          Track.create(name: '808 BASS', type: TrackType.midi, color: colors[1], order: 1),
          Track.create(name: 'MELODY', type: TrackType.midi,  color: colors[2], order: 2),
          Track.create(name: 'FX',     type: TrackType.audio, color: colors[3], order: 3),
        ];
      case ProjectTemplate.edm:
        return [
          Track.create(name: 'KICK',   type: TrackType.drum,  color: colors[0], order: 0),
          Track.create(name: 'BASS',   type: TrackType.midi,  color: colors[1], order: 1),
          Track.create(name: 'LEAD',   type: TrackType.midi,  color: colors[2], order: 2),
          Track.create(name: 'PAD',    type: TrackType.midi,  color: colors[3], order: 3),
          Track.create(name: 'FX',     type: TrackType.audio, color: colors[4], order: 4),
        ];
      case ProjectTemplate.lofi:
        return [
          Track.create(name: 'DRUMS',  type: TrackType.drum,  color: colors[0], order: 0),
          Track.create(name: 'BASS',   type: TrackType.midi,  color: colors[1], order: 1),
          Track.create(name: 'CHORDS', type: TrackType.midi,  color: colors[2], order: 2),
          Track.create(name: 'SAMPLE', type: TrackType.audio, color: colors[3], order: 3),
        ];
      default:
        return [];
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final projectProvider =
    StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier();
});
