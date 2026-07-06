import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/providers/audio_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/level_meter.dart';

// ─── Record state ─────────────────────────────────────────────────────────────
enum _RecordPhase { idle, waitingPermission, recording, stopped }

class _RecordState {
  final _RecordPhase phase;
  final Duration duration;
  final double inputLevel;
  final List<double> waveSnippet;   // last N amplitude samples for live display
  final String? savedPath;
  final bool hasPermission;

  const _RecordState({
    this.phase = _RecordPhase.idle,
    this.duration = Duration.zero,
    this.inputLevel = 0,
    this.waveSnippet = const [],
    this.savedPath,
    this.hasPermission = false,
  });

  _RecordState copyWith({
    _RecordPhase? phase,
    Duration? duration,
    double? inputLevel,
    List<double>? waveSnippet,
    String? savedPath,
    bool? hasPermission,
  }) {
    return _RecordState(
      phase: phase ?? this.phase,
      duration: duration ?? this.duration,
      inputLevel: inputLevel ?? this.inputLevel,
      waveSnippet: waveSnippet ?? this.waveSnippet,
      savedPath: savedPath,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class _RecordNotifier extends StateNotifier<_RecordState> {
  Timer? _timer;
  Timer? _levelSimTimer;
  final math.Random _rng = math.Random();

  _RecordNotifier() : super(const _RecordState()) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    state = state.copyWith(hasPermission: status.isGranted);
  }

  Future<void> requestPermission() async {
    final status = await Permission.microphone.request();
    state = state.copyWith(hasPermission: status.isGranted);
  }

  void startRecording() {
    if (!state.hasPermission) {
      state = state.copyWith(phase: _RecordPhase.waitingPermission);
      return;
    }
    // TODO: record.start(path: outputPath, config: RecordConfig(...))
    state = state.copyWith(phase: _RecordPhase.recording, savedPath: null);

    // Simulate duration ticker
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });

    // Simulate live level animation
    _levelSimTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final level = 0.2 + _rng.nextDouble() * 0.7;
      final wave = [...state.waveSnippet, level];
      if (wave.length > 120) wave.removeAt(0);
      state = state.copyWith(inputLevel: level, waveSnippet: wave);
    });
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    _levelSimTimer?.cancel();

    // TODO: final path = await record.stop();
    const path = '/storage/emulated/0/Music/PixelDAW/recording_stub.wav';
    state = state.copyWith(
      phase: _RecordPhase.stopped,
      inputLevel: 0,
      savedPath: path,
    );
  }

  void discardRecording() {
    state = _RecordState(hasPermission: state.hasPermission);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _levelSimTimer?.cancel();
    super.dispose();
  }
}

final _recordProvider =
    StateNotifierProvider.autoDispose<_RecordNotifier, _RecordState>(
        (ref) => _RecordNotifier());

// ─── Screen ────────────────────────────────────────────────────────────────────
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Input settings
  double _gain = 0.8;
  bool _monitorInput = false;
  String _quality = '24bit / 44.1kHz';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec     = ref.watch(_recordProvider);
    final recNot  = ref.read(_recordProvider.notifier);
    final isRec   = rec.phase == _RecordPhase.recording;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RECORD'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Permission warning ──────────────────────────────────────────
            if (!rec.hasPermission)
              DawPanel(
                borderColor: AppColors.neonOrange,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: AppColors.neonOrange, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('MICROPHONE PERMISSION REQUIRED',
                            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.neonOrange, letterSpacing: 1.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NeonButton(
                      label: 'GRANT PERMISSION',
                      color: AppColors.neonOrange,
                      onPressed: () => recNot.requestPermission(),
                    ),
                  ],
                ),
              ),

            if (!rec.hasPermission) const SizedBox(height: 12),

            // ─── Main record button ──────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isRec
                        ? AppColors.neonRed.withOpacity(0.05 + _pulse.value * 0.05)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRec
                          ? AppColors.neonRed.withOpacity(0.4 + _pulse.value * 0.4)
                          : AppColors.border,
                      width: isRec ? 2 : 1,
                    ),
                    boxShadow: isRec
                        ? [BoxShadow(
                            color: AppColors.neonRed.withOpacity(0.15 + _pulse.value * 0.1),
                            blurRadius: 20, spreadRadius: 4,
                          )]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Record button
                      GestureDetector(
                        onTap: rec.hasPermission
                            ? () {
                                HapticFeedback.heavyImpact();
                                if (isRec) {
                                  recNot.stopRecording();
                                } else {
                                  recNot.startRecording();
                                }
                              }
                            : null,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRec
                                  ? AppColors.neonRed.withOpacity(0.8 + _pulse.value * 0.2)
                                  : AppColors.neonRed.withOpacity(0.2),
                              border: Border.all(
                                color: AppColors.neonRed,
                                width: isRec ? 3 : 2,
                              ),
                              boxShadow: isRec
                                  ? [BoxShadow(
                                      color: AppColors.neonRed.withOpacity(0.5 + _pulse.value * 0.3),
                                      blurRadius: 20, spreadRadius: 4,
                                    )]
                                  : [],
                            ),
                            child: Icon(
                              isRec ? Icons.stop : Icons.fiber_manual_record,
                              color: isRec ? Colors.white : AppColors.neonRed,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      Text(
                        _formatDuration(rec.duration),
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isRec ? AppColors.neonRed : AppColors.textMuted,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRec ? 'RECORDING...' : rec.phase == _RecordPhase.stopped ? 'STOPPED' : 'PRESS TO RECORD',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 10,
                          color: isRec ? AppColors.neonRed : AppColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ─── Live waveform ────────────────────────────────────────────────
            DawPanel(
              title: 'INPUT',
              child: Row(
                children: [
                  // Stereo meter
                  AnimatingLevelMeter(
                    active: isRec,
                    width: 10,
                    height: 60,
                    stereo: true,
                  ),
                  const SizedBox(width: 10),

                  // Live waveform
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: CustomPaint(
                        painter: _LiveWavePainter(
                          samples: rec.waveSnippet,
                          isActive: isRec,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Input settings ───────────────────────────────────────────────
            DawPanel(
              title: 'INPUT SETTINGS',
              child: Column(
                children: [
                  // Gain
                  Row(
                    children: [
                      const SizedBox(
                        width: 60,
                        child: Text('GAIN', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1.5)),
                      ),
                      Expanded(
                        child: Slider(
                          value: _gain,
                          onChanged: (v) => setState(() => _gain = v),
                          activeColor: AppColors.neonOrange,
                          inactiveColor: AppColors.border,
                        ),
                      ),
                      Text('${(_gain * 100).round()}%',
                        style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.neonOrange, letterSpacing: 1)),
                    ],
                  ),

                  const Divider(height: 1, color: AppColors.border),

                  // Monitor
                  Row(
                    children: [
                      Expanded(
                        child: const Text('MONITOR INPUT',
                          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.2)),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _monitorInput,
                          onChanged: (v) => setState(() => _monitorInput = v),
                          activeColor: AppColors.neonBlue,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 1, color: AppColors.border),

                  // Quality
                  Row(
                    children: [
                      Expanded(
                        child: const Text('QUALITY',
                          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.2)),
                      ),
                      PopupMenuButton<String>(
                        color: AppColors.surface,
                        child: Text(_quality,
                          style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.neonGreen, letterSpacing: 1)),
                        onSelected: (v) => setState(() => _quality = v),
                        itemBuilder: (_) => [
                          '16bit / 44.1kHz',
                          '24bit / 44.1kHz',
                          '24bit / 48kHz',
                          '32bit / 96kHz',
                        ].map((q) => PopupMenuItem(
                          value: q,
                          child: Text(q,
                            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textPrimary)),
                        )).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Saved recording ──────────────────────────────────────────────
            if (rec.savedPath != null)
              DawPanel(
                borderColor: AppColors.neonGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 16),
                        const SizedBox(width: 8),
                        const Text('RECORDING SAVED',
                          style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.neonGreen, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(rec.savedPath!,
                      style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        NeonButton(label: 'USE IN PROJECT', color: AppColors.neonBlue, onPressed: () {
                          // TODO: add recording to project as audio clip
                        }),
                        const SizedBox(width: 8),
                        NeonButton(label: 'DISCARD', color: AppColors.neonRed, onPressed: () {
                          recNot.discardRecording();
                        }),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m  = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s  = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }
}

class _LiveWavePainter extends CustomPainter {
  final List<double> samples;
  final bool isActive;
  const _LiveWavePainter({required this.samples, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      // Draw flat line when idle
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()..color = AppColors.border..strokeWidth = 1,
      );
      return;
    }

    final step = size.width / samples.length;
    final cy   = size.height / 2;
    final path = Path()..moveTo(0, cy);
    for (int i = 0; i < samples.length; i++) {
      final x   = i * step;
      final amp = samples[i].clamp(0.0, 1.0).toDouble() * cy * 0.9;
      path.lineTo(x, cy - amp);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = isActive ? AppColors.neonRed : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = isActive ? MaskFilter.blur(BlurStyle.normal, 1.5) : null,
    );

    // Mirror
    final pathBot = Path()..moveTo(0, cy);
    for (int i = 0; i < samples.length; i++) {
      final x   = i * step;
      final amp = samples[i].clamp(0.0, 1.0).toDouble() * cy * 0.9;
      pathBot.lineTo(x, cy + amp);
    }
    canvas.drawPath(
      pathBot,
      Paint()
        ..color = (isActive ? AppColors.neonRed : AppColors.border).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_LiveWavePainter old) => old.samples != samples;
}
