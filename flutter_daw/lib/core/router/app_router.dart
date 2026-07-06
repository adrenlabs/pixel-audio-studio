import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/sequencer/sequencer_screen.dart';
import '../../features/beat_maker/beat_maker_screen.dart';
import '../../features/sample_browser/sample_browser_screen.dart';
import '../../features/waveform_editor/waveform_editor_screen.dart';
import '../../features/piano_roll/piano_roll_screen.dart';
import '../../features/mixer/mixer_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/export/export_screen.dart';
import '../../features/record/record_screen.dart';

/// Route name constants — use these when pushing/replacing routes.
class AppRoutes {
  AppRoutes._();

  static const String onboarding    = '/onboarding';
  static const String home          = '/';
  static const String sequencer     = '/sequencer';
  static const String beatMaker     = '/beat-maker';
  static const String sampleBrowser = '/samples';
  static const String waveformEditor = '/waveform';
  static const String pianoRoll     = '/piano-roll';
  static const String mixer         = '/mixer';
  static const String settings      = '/settings';
  static const String exportAudio   = '/export';
  static const String record        = '/record';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (context, state) async {
    if (state.matchedLocation == AppRoutes.home) {
      final prefs = await SharedPreferences.getInstance();
      final seen  = prefs.getBool('onboarding_done') ?? false;
      if (!seen) return AppRoutes.onboarding;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'sequencer',
          builder: (_, __) => const SequencerScreen(),
        ),
        GoRoute(
          path: 'beat-maker',
          builder: (_, __) => const BeatMakerScreen(),
        ),
        GoRoute(
          path: 'samples',
          builder: (_, __) => const SampleBrowserScreen(),
        ),
        GoRoute(
          path: 'waveform',
          builder: (_, state) {
            final path = state.uri.queryParameters['path'];
            return WaveformEditorScreen(filePath: path);
          },
        ),
        GoRoute(
          path: 'piano-roll',
          builder: (_, state) {
            final trackId = state.uri.queryParameters['trackId'];
            return PianoRollScreen(trackId: trackId);
          },
        ),
        GoRoute(
          path: 'mixer',
          builder: (_, __) => const MixerScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'export',
          builder: (_, __) => const ExportScreen(),
        ),
        GoRoute(
          path: 'record',
          builder: (_, __) => const RecordScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF0A0A0F),
    body: Center(
      child: Text(
        'ROUTE NOT FOUND\n${state.uri}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'ShareTechMono',
          color: Color(0xFF00CFFF),
          fontSize: 14,
        ),
      ),
    ),
  ),
);
