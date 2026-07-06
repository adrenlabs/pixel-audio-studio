import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/sample.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/waveform_painter.dart';
import '../../core/utils/audio_utils.dart';

// ─── Provider ──────────────────────────────────────────────────────────────────
final _sampleLibraryProvider = StateNotifierProvider<_SampleLibraryNotifier, _SampleState>(
  (ref) => _SampleLibraryNotifier(),
);

class _SampleState {
  final List<Sample> all;
  final List<Sample> filtered;
  final String query;
  final SampleCategory? activeCategory;
  final String? previewingId;

  const _SampleState({
    required this.all,
    required this.filtered,
    this.query = '',
    this.activeCategory,
    this.previewingId,
  });

  _SampleState copyWith({
    List<Sample>? all,
    List<Sample>? filtered,
    String? query,
    SampleCategory? activeCategory,
    String? previewingId,
    bool clearCategory = false,
    bool clearPreview  = false,
  }) {
    return _SampleState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      activeCategory: clearCategory ? null : activeCategory ?? this.activeCategory,
      previewingId: clearPreview ? null : previewingId ?? this.previewingId,
    );
  }
}

class _SampleLibraryNotifier extends StateNotifier<_SampleState> {
  _SampleLibraryNotifier()
      : super(_SampleState(
          all: SampleLibrary.builtinSamples,
          filtered: SampleLibrary.builtinSamples,
        ));

  void search(String q) {
    final f = state.all
        .where((s) =>
            s.name.toLowerCase().contains(q.toLowerCase()) &&
            (state.activeCategory == null || s.category == state.activeCategory))
        .toList();
    state = state.copyWith(query: q, filtered: f);
  }

  void filterCategory(SampleCategory? cat) {
    final f = state.all
        .where((s) =>
            (cat == null || s.category == cat) &&
            (state.query.isEmpty || s.name.toLowerCase().contains(state.query.toLowerCase())))
        .toList();
    state = state.copyWith(
      activeCategory: cat,
      filtered: f,
      clearCategory: cat == null,
    );
  }

  void toggleFavorite(String id) {
    final all = state.all.map((s) => s.id == id ? s.copyWith(isFavorite: !s.isFavorite) : s).toList();
    final filtered = state.filtered.map((s) => s.id == id ? s.copyWith(isFavorite: !s.isFavorite) : s).toList();
    state = state.copyWith(all: all, filtered: filtered);
  }

  void previewSample(String? id) {
    state = state.copyWith(previewingId: id, clearPreview: id == null);
    if (id != null) {
      AudioUtils.playSample('stub_handle_$id'); // TODO: real playback
    } else {
      AudioUtils.stopAll();
    }
  }

  Future<void> importFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null) return;
    final newSamples = result.files
        .where((f) => f.path != null)
        .map((f) => Sample.create(
              name: f.name.replaceAll(RegExp(r'\.\w+$'), '').toUpperCase(),
              filePath: f.path!,
              category: SampleCategory.user,
            ))
        .toList();
    final all = [...state.all, ...newSamples];
    state = state.copyWith(all: all, filtered: all);
  }
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class SampleBrowserScreen extends ConsumerStatefulWidget {
  const SampleBrowserScreen({super.key});

  @override
  ConsumerState<SampleBrowserScreen> createState() => _SampleBrowserScreenState();
}

class _SampleBrowserScreenState extends ConsumerState<SampleBrowserScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_sampleLibraryProvider);
    final notifier = ref.read(_sampleLibraryProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SAMPLE BROWSER'),
        actions: [
          NeonIconButton(
            icon: Icons.upload_file,
            color: AppColors.neonGreen,
            size: 34,
            tooltip: 'Import from Device',
            onPressed: () => notifier.importFromDevice(),
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
          // ─── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'ShareTechMono', fontSize: 12),
              onChanged: notifier.search,
              decoration: InputDecoration(
                hintText: 'SEARCH SAMPLES...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 16),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          notifier.search('');
                        },
                        child: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                      )
                    : null,
              ),
            ),
          ),

          // ─── Category chips ───────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _CatChip(
                  label: 'ALL',
                  color: AppColors.neonBlue,
                  isActive: state.activeCategory == null,
                  onTap: () => notifier.filterCategory(null),
                ),
                ...SampleCategory.values.map((c) => _CatChip(
                      label: c.name.toUpperCase(),
                      color: _catColor(c),
                      isActive: state.activeCategory == c,
                      onTap: () => notifier.filterCategory(state.activeCategory == c ? null : c),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ─── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text('${state.filtered.length} SAMPLES',
                  style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1.5)),
                const Spacer(),
                if (state.previewingId != null) ...[
                  const Icon(Icons.volume_up, color: AppColors.neonGreen, size: 12),
                  const SizedBox(width: 4),
                  const Text('PREVIEWING',
                    style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.neonGreen, letterSpacing: 1.5)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          Container(height: 1, color: AppColors.border),

          // ─── Sample list ──────────────────────────────────────────────────
          Expanded(
            child: state.filtered.isEmpty
                ? const Center(
                    child: Text('NO SAMPLES FOUND',
                      style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textMuted, letterSpacing: 2)),
                  )
                : ListView.builder(
                    itemCount: state.filtered.length,
                    itemBuilder: (_, i) => _SampleTile(
                      sample: state.filtered[i],
                      isPreviewing: state.previewingId == state.filtered[i].id,
                      onPreview: () {
                        HapticFeedback.selectionClick();
                        if (state.previewingId == state.filtered[i].id) {
                          notifier.previewSample(null);
                        } else {
                          notifier.previewSample(state.filtered[i].id);
                        }
                      },
                      onFavorite: () => notifier.toggleFavorite(state.filtered[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _catColor(SampleCategory c) {
    switch (c) {
      case SampleCategory.drums:  return AppColors.neonBlue;
      case SampleCategory.bass:   return AppColors.neonPurple;
      case SampleCategory.leads:  return AppColors.neonGreen;
      case SampleCategory.pads:   return AppColors.neonPink;
      case SampleCategory.fx:     return AppColors.neonOrange;
      case SampleCategory.vocals: return AppColors.neonYellow;
      case SampleCategory.loops:  return AppColors.neonGreen;
      case SampleCategory.user:   return AppColors.textSecondary;
    }
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _CatChip({required this.label, required this.color, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Text(label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive ? color : AppColors.textMuted,
            letterSpacing: 1.2,
          )),
      ),
    );
  }
}

class _SampleTile extends StatelessWidget {
  final Sample sample;
  final bool isPreviewing;
  final VoidCallback onPreview;
  final VoidCallback onFavorite;

  const _SampleTile({
    required this.sample,
    required this.isPreviewing,
    required this.onPreview,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final waveData = AudioUtils.fakeWaveform(40, seed: sample.id.hashCode.toDouble());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPreviewing ? AppColors.neonGreen.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isPreviewing ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: GestureDetector(
          onTap: onPreview,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPreviewing ? AppColors.neonGreen.withOpacity(0.15) : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isPreviewing ? AppColors.neonGreen : AppColors.border,
              ),
            ),
            child: Icon(
              isPreviewing ? Icons.stop : Icons.play_arrow,
              color: isPreviewing ? AppColors.neonGreen : AppColors.textMuted,
              size: 18,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sample.name,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.textPrimary, letterSpacing: 0.8)),
            const SizedBox(height: 3),
            // Mini waveform
            WaveformThumbnail(
              samples: waveData,
              color: isPreviewing ? AppColors.neonGreen : AppColors.waveformInactive,
              height: 18,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              _Tag(label: sample.category.name.toUpperCase()),
              if (sample.bpm > 0) ...[const SizedBox(width: 4), _Tag(label: '${sample.bpm} BPM')],
              if (sample.key.isNotEmpty) ...[const SizedBox(width: 4), _Tag(label: sample.key)],
              const Spacer(),
              Text(sample.durationFormatted,
                style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: AppColors.textMuted)),
            ],
          ),
        ),
        trailing: GestureDetector(
          onTap: onFavorite,
          child: Icon(
            sample.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: sample.isFavorite ? AppColors.neonPink : AppColors.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(label,
        style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted, letterSpacing: 0.8)),
    );
  }
}
