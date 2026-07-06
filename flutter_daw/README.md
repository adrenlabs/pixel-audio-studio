# PIXEL DAW — Flutter Music Production App

A professional, retro FL-Studio-inspired music production app built with Flutter for Android.

---

## 🎛 Features

| Screen | Description |
|---|---|
| **Home / Dashboard** | Project management, recent sessions, templates |
| **Sequencer** | Multi-track timeline, clip placement, playhead |
| **Beat Maker** | 16-step sequencer + 4×4 drum pad grid |
| **Sample Browser** | Library search, categories, preview, import from device |
| **Waveform Editor** | Trim, split, loop, fade, playback |
| **Piano Roll** | MIDI note editing with velocity lane |
| **Mixer** | Multi-channel faders, pan, mute/solo, FX chain |
| **Recorder** | Microphone recording with live waveform |
| **Export** | WAV / MP3 / AAC render with quality settings |
| **Settings** | Audio engine, UI, autosave, haptics |
| **Onboarding** | Animated first-launch welcome |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.13 — https://docs.flutter.dev/get-started/install
- Android SDK / Android Studio
- Dart ≥ 3.1

### Setup

```bash
# 1. Clone / copy this project
cd flutter_daw

# 2. Download ShareTechMono font
# Go to: https://fonts.google.com/specimen/Share+Tech+Mono
# Download → extract → copy ShareTechMono-Regular.ttf to:
mkdir -p assets/fonts
cp ~/Downloads/ShareTechMono-Regular.ttf assets/fonts/

# 3. Install dependencies
flutter pub get

# 4. Run on connected Android device or emulator
flutter run
```

---

## 📦 Build APK

### Debug APK (quick test)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (optimised, signed)
```bash
# First generate a signing key (one time):
keytool -genkey -v \
  -keystore android/app/release.jks \
  -alias pixel_daw \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Add to android/app/build.gradle signingConfigs.release, then:
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🗂 Project Structure

```
lib/
├── main.dart                     # Entry point — orientation + system UI setup
├── app.dart                      # MaterialApp.router root
│
├── core/
│   ├── constants/app_constants.dart   # BPM, step counts, pad labels, FX names
│   ├── models/
│   │   ├── project.dart          # Project, ProjectTemplate
│   │   ├── track.dart            # Track, TrackClip, EffectSlot, TrackType
│   │   ├── sample.dart           # Sample, SampleCategory, SampleLibrary
│   │   └── beat_pattern.dart     # BeatPattern, BeatRow
│   ├── router/app_router.dart    # GoRouter with all named routes
│   ├── theme/
│   │   ├── app_colors.dart       # Full retro neon palette + glow helpers
│   │   └── app_theme.dart        # Dark ThemeData with ShareTechMono typography
│   └── utils/audio_utils.dart    # dB math, MIDI, waveform gen, audio stubs (TODO)
│
├── features/
│   ├── onboarding/               # Animated welcome screen
│   ├── home/                     # Dashboard + project/track management
│   ├── sequencer/                # Timeline + clip editor
│   ├── beat_maker/               # Step sequencer + drum pad tabs
│   ├── sample_browser/           # Searchable sample library + file import
│   ├── waveform_editor/          # Waveform view + trim/split/loop/fade
│   ├── piano_roll/               # MIDI note grid + velocity lane
│   ├── mixer/                    # Channel strip + FX chain
│   ├── record/                   # Microphone recording
│   ├── export/                   # Format settings + render progress
│   └── settings/                 # Audio engine, UI, and export prefs
│
└── shared/
    ├── providers/
    │   ├── project_provider.dart  # StateNotifier + undo/redo + save/load
    │   ├── audio_provider.dart    # Playback state + beat pattern
    │   └── settings_provider.dart # App settings with SharedPreferences
    └── widgets/
        ├── neon_button.dart       # Animated tactile DAW button + icon button
        ├── studio_knob.dart       # Rotary drag-to-turn knob with glow arc
        ├── studio_slider.dart     # Vertical fader + pan slider + labeled slider
        ├── level_meter.dart       # LED VU meter (static + animated variants)
        ├── waveform_painter.dart  # Full waveform widget + clip thumbnail
        ├── daw_panel.dart         # Bordered panel + pixel grid background
        └── transport_bar.dart     # Play/stop/rec/BPM/loop/metronome/undo/redo
```

---

## 🔊 Audio Engine — TODO Stubs

The following functions in `lib/core/utils/audio_utils.dart` are **stubs** marked with `// TODO`:

| Stub | What to connect |
|---|---|
| `loadAudioFile(path)` | `just_audio` Player or custom native plugin |
| `playSample(handle, ...)` | Trigger one-shot playback at given volume/pitch |
| `stopAll()` | Halt all active players |
| `setBpm(bpm)` | Drive the engine step clock |
| `exportMix(...)` | Offline render to WAV/MP3/AAC |

The `record_screen.dart` recording flow also uses simulated level meters — connect `package:record` for real microphone capture.

---

## 🎨 Design System

| Token | Value |
|---|---|
| Background | `#0A0A0F` |
| Surface | `#161625` |
| Neon Blue | `#00CFFF` |
| Neon Purple | `#AA44FF` |
| Neon Green | `#00FF88` |
| Neon Orange | `#FF6600` |
| Neon Pink | `#FF3399` |
| Typography | ShareTechMono (mono) + Inter (body) |

---

## 🏗 Architecture

- **State management**: `flutter_riverpod` — `StateNotifierProvider` throughout
- **Navigation**: `go_router` — path-based with nested sub-routes
- **Persistence**: `shared_preferences` — projects and settings
- **Audio**: stubs via `audio_utils.dart` — ready for `just_audio`, `record`, or native engine
- **Layer separation**: `core/` (models, utils, theme) → `shared/` (providers, widgets) → `features/` (screens)

---

## 📋 Permissions Required (Android)

| Permission | Purpose |
|---|---|
| `RECORD_AUDIO` | Microphone recording |
| `READ_MEDIA_AUDIO` | Import samples from device (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Import samples (Android ≤12) |
| `FOREGROUND_SERVICE` | Background audio playback |

---

## 🛣 Roadmap / Missing Advanced Features

- [ ] Real audio engine integration (native plugin or FlutterSound)
- [ ] MIDI device input/output
- [ ] Plugin system for third-party instruments/effects
- [ ] Cloud project sync
- [ ] Collaboration / session sharing
- [ ] Automation lane editor (planned stub exists in sequencer)
- [ ] Piano roll: quantise, transpose, velocity edit
- [ ] Mixer: EQ & compressor UI with real parameter controls
- [ ] Beatmaker: swing engine, probability per step
- [ ] Sample editor: pitch shifting, time-stretch
