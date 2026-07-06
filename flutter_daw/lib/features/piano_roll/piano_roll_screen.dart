import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/providers/audio_provider.dart';
import '../../core/models/track.dart'; // EffectSlot (unused here, included for model completeness)

// ─── Note model ───────────────────────────────────────────────────────────────
class PianoNote {
  final int midiNote;    // 0-127
  final double startBeat;
  final double length;   // beats
  final int velocity;    // 0-127
  final String id;

  const PianoNote({
    required this.midiNote,
    required this.startBeat,
    required this.length,
    required this.velocity,
    required this.id,
  });

  PianoNote copyWith({double? length, int? velocity}) => PianoNote(
    midiNote: midiNote,
    startBeat: startBeat,
    length: length ?? this.length,
    velocity: velocity ?? this.velocity,
    id: id,
  );
}

// ─── Provider ─────────────────────────────────────────────────────────────────
class _PianoRollNotifier extends StateNotifier<List<PianoNote>> {
  _PianoRollNotifier() : super(_defaultNotes());

  void addNote(int midi, double beat, {double length = 1.0, int velocity = 100}) {
    final note = PianoNote(
      midiNote: midi,
      startBeat: beat,
      length: length,
      velocity: velocity,
      id: '${midi}_${beat}_${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [...state, note];
    // TODO: trigger note preview via MIDI engine
    AudioUtils.playSample('stub_${note.id}');
  }

  void removeNote(String id) => state = state.where((n) => n.id != id).toList();

  void clearAll() => state = [];

  static List<PianoNote> _defaultNotes() => [
    const PianoNote(midiNote: 60, startBeat: 0,   length: 1.0, velocity: 100, id: 'n1'),
    const PianoNote(midiNote: 64, startBeat: 1,   length: 0.5, velocity:  90, id: 'n2'),
    const PianoNote(midiNote: 67, startBeat: 1.5, length: 0.5, velocity:  85, id: 'n3'),
    const PianoNote(midiNote: 60, startBeat: 2,   length: 2.0, velocity: 100, id: 'n4'),
    const PianoNote(midiNote: 62, startBeat: 4,   length: 1.0, velocity:  80, id: 'n5'),
    const PianoNote(midiNote: 65, startBeat: 5,   length: 1.0, velocity:  90, id: 'n6'),
  ];
}

final _pianoRollProvider =
    StateNotifierProvider<_PianoRollNotifier, List<PianoNote>>(
        (ref) => _PianoRollNotifier());

// ─── Screen ────────────────────────────────────────────────────────────────────
class PianoRollScreen extends ConsumerStatefulWidget {
  final String? trackId;
  const PianoRollScreen({super.key, this.trackId});

  @override
  ConsumerState<PianoRollScreen> createState() => _PianoRollScreenState();
}

class _PianoRollScreenState extends ConsumerState<PianoRollScreen> {
  static const double _keyW     = 44.0;
  static const double _noteH    = AppConstants.pianoKeyHeight;
  static const double _cellW    = AppConstants.cellWidth;
  static const int    _totalKeys = 88;   // A0 (21) to C8 (108)
  static const int    _startMidi = 21;
  static const int    _visibleBeats = 16;

  String _tool = 'DRAW'; // DRAW | SELECT | ERASE
  double _zoom = 1.0;

  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start scrolled to middle C (MIDI 60)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = (_totalKeys - (60 - _startMidi) - 1) * _noteH - 200;
      _vScroll.jumpTo(offset.clamp(0.0, double.infinity).toDouble());
    });
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes    = ref.watch(_pianoRollProvider);
    final notifier = ref.read(_pianoRollProvider.notifier);
    final audio    = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PIANO ROLL'),
        actions: [
          ...[
            ('DRAW',   Icons.edit,        AppColors.neonBlue),
            ('SELECT', Icons.crop_square, AppColors.neonPurple),
            ('ERASE',  Icons.auto_delete, AppColors.neonRed),
          ].map((t) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: NeonButton(
              label: t.$1,
              icon: t.$2,
              color: t.$3,
              active: _tool == t.$1,
              mini: true,
              onPressed: () => setState(() => _tool = t.$1),
            ),
          )),
          const SizedBox(width: 4),
          NeonIconButton(
            icon: Icons.delete_sweep,
            color: AppColors.neonOrange,
            size: 32,
            onPressed: () => notifier.clearAll(),
            tooltip: 'Clear all notes',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ─── Beat ruler ─────────────────────────────────────────────────────
          Row(
            children: [
              SizedBox(width: _keyW, height: 24, child: Container(color: AppColors.surfaceDark)),
              Container(width: 1, color: AppColors.border),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _visibleBeats * _cellW * _zoom * 2,
                      child: CustomPaint(
                        painter: _BeatRulerPainter(
                          cellW: _cellW * _zoom,
                          totalBeats: _visibleBeats * 2,
                          playheadBeat: audio.playheadBeat,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(height: 1, color: AppColors.border),

          // ─── Piano keys + note grid ──────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Piano keys
                SizedBox(
                  width: _keyW,
                  child: SingleChildScrollView(
                    controller: _vScroll,
                    child: Column(
                      children: List.generate(_totalKeys, (i) {
                        final midi = _startMidi + (_totalKeys - 1 - i);
                        return _PianoKey(
                          midi: midi,
                          height: _noteH,
                          width: _keyW,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AudioUtils.playSample('midi_$midi');
                          },
                        );
                      }),
                    ),
                  ),
                ),

                Container(width: 1, color: AppColors.border),

                // Note grid
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, box) {
                      final gridW = _visibleBeats * _cellW * _zoom * 2;
                      return GestureDetector(
                        onTapDown: (d) => _onGridTap(
                          d,
                          gridW,
                          notifier,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _hScroll,
                          child: SizedBox(
                            width: gridW,
                            child: SingleChildScrollView(
                              controller: _vScroll,
                              child: SizedBox(
                                height: _totalKeys * _noteH,
                                child: Stack(
                                  children: [
                                    // Grid background
                                    CustomPaint(
                                      size: Size(gridW, _totalKeys * _noteH),
                                      painter: _NoteGridPainter(
                                        cellW: _cellW * _zoom,
                                        noteH: _noteH,
                                        totalKeys: _totalKeys,
                                        startMidi: _startMidi,
                                        playheadBeat: audio.playheadBeat,
                                      ),
                                    ),
                                    // Notes
                                    ...notes.map((n) => _NoteBlock(
                                      note: n,
                                      cellW: _cellW * _zoom,
                                      noteH: _noteH,
                                      startMidi: _startMidi,
                                      totalKeys: _totalKeys,
                                      onRemove: _tool == 'ERASE'
                                          ? () => notifier.removeNote(n.id)
                                          : null,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ─── Velocity lane ────────────────────────────────────────────────
          Container(height: 1, color: AppColors.border),
          _VelocityLane(notes: notes, cellW: _cellW * _zoom),
        ],
      ),
    );
  }

  void _onGridTap(TapDownDetails d, double gridW, _PianoRollNotifier notifier) {
    if (_tool != 'DRAW') return;
    final beat   = d.localPosition.dx / (_cellW * _zoom);
    final rowIdx = (d.localPosition.dy / _noteH).floor();
    final midi   = _startMidi + (_totalKeys - 1 - rowIdx);
    if (midi < _startMidi || midi > _startMidi + _totalKeys - 1) return;

    HapticFeedback.selectionClick();
    notifier.addNote(midi, beat.floorToDouble(), length: 1.0);
  }
}

class _PianoKey extends StatelessWidget {
  final int midi;
  final double height;
  final double width;
  final VoidCallback onTap;

  const _PianoKey({required this.midi, required this.height, required this.width, required this.onTap});

  bool get _isBlack {
    final note = midi % 12;
    return [1, 3, 6, 8, 10].contains(note);
  }

  @override
  Widget build(BuildContext context) {
    final name  = AudioUtils.midiToNoteName(midi);
    final isC   = midi % 12 == 0;
    final black  = _isBlack;

    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: black ? AppColors.pianoBlack : AppColors.pianoWhite,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: isC
                ? Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 7,
                      color: black ? AppColors.textMuted : const Color(0xFF1A1A2E),
                      letterSpacing: 0.5,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// Piano key text contrast color for white keys
const Color _pianoKeyTextColor = Color(0xFF1A1A2E);

class _NoteBlock extends StatelessWidget {
  final PianoNote note;
  final double cellW;
  final double noteH;
  final int startMidi;
  final int totalKeys;
  final VoidCallback? onRemove;

  const _NoteBlock({
    required this.note,
    required this.cellW,
    required this.noteH,
    required this.startMidi,
    required this.totalKeys,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final row   = totalKeys - 1 - (note.midiNote - startMidi);
    final isBlack = [1, 3, 6, 8, 10].contains(note.midiNote % 12);
    final color = isBlack ? AppColors.noteBlockAlt : AppColors.noteBlock;

    return Positioned(
      left: note.startBeat * cellW,
      top:  row * noteH + 1,
      width: (note.length * cellW - 2).clamp(4.0, double.infinity).toDouble(),
      height: noteH - 2,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 0.8),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                AudioUtils.midiToNoteName(note.midiNote),
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 7,
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteGridPainter extends CustomPainter {
  final double cellW;
  final double noteH;
  final int totalKeys;
  final int startMidi;
  final double playheadBeat;

  const _NoteGridPainter({
    required this.cellW,
    required this.noteH,
    required this.totalKeys,
    required this.startMidi,
    required this.playheadBeat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blackRow = Paint()..color = const Color(0xFF111122);
    final whiteRow = Paint()..color = const Color(0xFF0E0E1A);
    final line     = Paint()..color = AppColors.border..strokeWidth = 0.4;
    final beatLine = Paint()..color = AppColors.borderBright..strokeWidth = 0.8;

    for (int i = 0; i < totalKeys; i++) {
      final midi    = startMidi + (totalKeys - 1 - i);
      final isBlack = [1, 3, 6, 8, 10].contains(midi % 12);
      canvas.drawRect(
        Rect.fromLTWH(0, i * noteH, size.width, noteH),
        isBlack ? blackRow : whiteRow,
      );
      canvas.drawLine(Offset(0, i * noteH), Offset(size.width, i * noteH), line);
    }

    // Vertical beat/sub-beat lines
    for (double x = 0; x <= size.width; x += cellW / 4) {
      final isBeat = (x % cellW).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          isBeat ? beatLine : (Paint()..color = AppColors.border.withOpacity(0.3)..strokeWidth = 0.4));
    }

    // Playhead
    final phx = playheadBeat * cellW;
    canvas.drawLine(
      Offset(phx, 0), Offset(phx, size.height),
      Paint()..color = AppColors.playhead..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_NoteGridPainter old) =>
      old.playheadBeat != playheadBeat || old.cellW != cellW;
}

class _BeatRulerPainter extends CustomPainter {
  final double cellW;
  final int totalBeats;
  final double playheadBeat;

  const _BeatRulerPainter({
    required this.cellW,
    required this.totalBeats,
    required this.playheadBeat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int b = 0; b <= totalBeats; b++) {
      final x = b * cellW;
      canvas.drawLine(
        Offset(x, b % 4 == 0 ? 0 : size.height * 0.5),
        Offset(x, size.height),
        Paint()..color = AppColors.border..strokeWidth = b % 4 == 0 ? 1 : 0.5,
      );
      if (b % 4 == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${b + 1}',
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 2, 3));
      }
    }
    final phx = playheadBeat * cellW;
    canvas.drawLine(Offset(phx, 0), Offset(phx, size.height),
        Paint()..color = AppColors.playhead..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_BeatRulerPainter old) => old.playheadBeat != playheadBeat;
}

class _VelocityLane extends StatelessWidget {
  final List<PianoNote> notes;
  final double cellW;
  const _VelocityLane({required this.notes, required this.cellW});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.surfaceDark,
      child: Row(
        children: [
          Container(
            width: 44,
            alignment: Alignment.center,
            child: const RotatedBox(
              quarterTurns: 3,
              child: Text('VEL', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted, letterSpacing: 1.5)),
            ),
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 16 * cellW * 2,
                child: CustomPaint(
                  painter: _VelocityPainter(notes: notes, cellW: cellW),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VelocityPainter extends CustomPainter {
  final List<PianoNote> notes;
  final double cellW;
  const _VelocityPainter({required this.notes, required this.cellW});

  @override
  void paint(Canvas canvas, Size size) {
    for (final n in notes) {
      final x = n.startBeat * cellW;
      final h = (n.velocity / 127) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, 6, h),
        Paint()..color = AppColors.neonBlue.withOpacity(0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_VelocityPainter old) => old.notes != notes;
}
