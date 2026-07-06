import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/project.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/project_provider.dart';
import '../../shared/widgets/daw_panel.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/transport_bar.dart';
import '../../core/models/track.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _navIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home,       label: 'HOME'),
    _NavItem(icon: Icons.grid_on,    label: 'SEQUENCE'),
    _NavItem(icon: Icons.piano,      label: 'PADS'),
    _NavItem(icon: Icons.tune,       label: 'MIXER'),
    _NavItem(icon: Icons.settings,   label: 'SETTINGS'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 1: context.go('${AppRoutes.home}sequencer'); break;
      case 2: context.go('${AppRoutes.home}beat-maker'); break;
      case 3: context.go('${AppRoutes.home}mixer'); break;
      case 4: context.go('${AppRoutes.home}settings'); break;
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PIXEL DAW'),
        actions: [
          NeonIconButton(
            icon: Icons.save,
            color: AppColors.neonGreen,
            size: 34,
            tooltip: 'Save Project',
            onPressed: state.currentProject != null
                ? () => ref.read(projectProvider.notifier).saveProject()
                : null,
          ),
          const SizedBox(width: 4),
          NeonIconButton(
            icon: Icons.folder_open,
            color: AppColors.neonPurple,
            size: 34,
            tooltip: 'Open Project',
            onPressed: () => _showRecentProjects(),
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
          // Transport bar always visible at top
          if (state.currentProject != null) const TransportBar(),
          if (state.currentProject != null)
            Container(height: 1, color: AppColors.border),

          Expanded(
            child: state.currentProject == null
                ? _buildLanding()
                : _buildProjectDashboard(state),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        items: _navItems
            .map((n) => BottomNavigationBarItem(icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }

  // ─── Landing (no project open) ─────────────────────────────────────────────
  Widget _buildLanding() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Hero
          _HeroBanner(),
          const SizedBox(height: 16),

          // Quick actions
          DawPanel(
            title: 'QUICK START',
            child: Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: '+ NEW PROJECT',
                    color: AppColors.neonBlue,
                    height: 44,
                    onPressed: () => _showNewProjectDialog(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeonButton(
                    label: 'FROM TEMPLATE',
                    color: AppColors.neonPurple,
                    height: 44,
                    onPressed: () => _showTemplateSheet(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Feature cards
          DawPanel(
            title: 'TOOLS',
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                _ToolCard(icon: Icons.grid_on,       label: 'SEQUENCER',  color: AppColors.neonBlue,   route: '${AppRoutes.home}sequencer'),
                _ToolCard(icon: Icons.piano,         label: 'BEAT MAKER', color: AppColors.neonPurple, route: '${AppRoutes.home}beat-maker'),
                _ToolCard(icon: Icons.library_music, label: 'SAMPLES',    color: AppColors.neonGreen,  route: '${AppRoutes.home}samples'),
                _ToolCard(icon: Icons.tune,          label: 'MIXER',      color: AppColors.neonOrange, route: '${AppRoutes.home}mixer'),
                _ToolCard(icon: Icons.music_note,    label: 'PIANO ROLL', color: AppColors.neonPink,   route: '${AppRoutes.home}piano-roll'),
                _ToolCard(icon: Icons.mic,           label: 'RECORD',     color: AppColors.neonRed,    route: '${AppRoutes.home}record'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Project Dashboard ─────────────────────────────────────────────────────
  Widget _buildProjectDashboard(ProjectState state) {
    final project = state.currentProject!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project header
          DawPanel(
            child: Row(
              children: [
                const Icon(Icons.folder, color: AppColors.neonBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (state.isDirty)
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.neonOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _StatChip(label: 'BPM',    value: '${project.bpm}',       color: AppColors.neonYellow),
              const SizedBox(width: 8),
              _StatChip(label: 'TRACKS', value: '${project.tracks.length}', color: AppColors.neonBlue),
              const SizedBox(width: 8),
              _StatChip(label: 'BARS',   value: '${project.bars}',      color: AppColors.neonPurple),
            ],
          ),
          const SizedBox(height: 12),

          // Tracks overview
          DawPanel(
            title: 'TRACKS',
            actions: [
              NeonIconButton(
                icon: Icons.add,
                color: AppColors.neonBlue,
                size: 28,
                onPressed: () => _showAddTrackSheet(),
              ),
            ],
            child: project.tracks.isEmpty
                ? _EmptyTracks(onAdd: () => _showAddTrackSheet())
                : Column(
                    children: project.tracks.map((t) => _TrackRow(track: t)).toList(),
                  ),
          ),
          const SizedBox(height: 10),

          // Tool launchers
          DawPanel(
            title: 'OPEN IN',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                NeonButton(label: 'SEQUENCER',  color: AppColors.neonBlue,   onPressed: () => context.go('${AppRoutes.home}sequencer')),
                NeonButton(label: 'BEAT MAKER', color: AppColors.neonPurple, onPressed: () => context.go('${AppRoutes.home}beat-maker')),
                NeonButton(label: 'PIANO ROLL', color: AppColors.neonPink,   onPressed: () => context.go('${AppRoutes.home}piano-roll')),
                NeonButton(label: 'MIXER',      color: AppColors.neonOrange, onPressed: () => context.go('${AppRoutes.home}mixer')),
                NeonButton(label: 'SAMPLES',    color: AppColors.neonGreen,  onPressed: () => context.go('${AppRoutes.home}samples')),
                NeonButton(label: 'RECORD',     color: AppColors.neonRed,    onPressed: () => context.go('${AppRoutes.home}record')),
                NeonButton(label: 'EXPORT',     color: AppColors.neonYellow, onPressed: () => context.go('${AppRoutes.home}export')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs / Sheets ──────────────────────────────────────────────────────
  void _showNewProjectDialog() {
    final ctrl = TextEditingController(text: 'Untitled Project');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('NEW PROJECT',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 13, color: AppColors.neonBlue, letterSpacing: 2)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'ShareTechMono', fontSize: 13),
          decoration: const InputDecoration(hintText: 'Project name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted, fontFamily: 'ShareTechMono', fontSize: 10))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(projectProvider.notifier).createProject(name: ctrl.text.trim().isEmpty ? 'Untitled' : ctrl.text.trim());
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _showTemplateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('SELECT TEMPLATE',
                style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.neonBlue, letterSpacing: 2)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...ProjectTemplate.values.map((t) => ListTile(
            leading: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: AppColors.trackColors[ProjectTemplate.values.indexOf(t) % AppColors.trackColors.length], shape: BoxShape.circle),
            ),
            title: Text(t.label, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textPrimary, letterSpacing: 1.5)),
            subtitle: Text(t.description, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            onTap: () {
              Navigator.pop(context);
              ref.read(projectProvider.notifier).createFromTemplate(t);
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showRecentProjects() {
    final recents = ref.read(projectProvider).recentProjects;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('RECENT PROJECTS',
                style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.neonBlue, letterSpacing: 2)),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (recents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No saved projects', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ...recents.map((p) => ListTile(
              leading: const Icon(Icons.folder, color: AppColors.neonBlue, size: 18),
              title: Text(p.name, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textPrimary)),
              subtitle: Text('${p.bpm} BPM · ${p.tracks.length} tracks', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                ref.read(projectProvider.notifier).openProject(p);
              },
            )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showAddTrackSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('ADD TRACK', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.neonBlue, letterSpacing: 2)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...TrackType.values.map((t) => ListTile(
            leading: Icon(_trackTypeIcon(t), color: AppColors.neonBlue, size: 18),
            title: Text(t.name.toUpperCase(), style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: AppColors.textPrimary, letterSpacing: 1.5)),
            onTap: () {
              Navigator.pop(context);
              ref.read(projectProvider.notifier).addTrack(t);
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  IconData _trackTypeIcon(TrackType t) {
    switch (t) {
      case TrackType.audio: return Icons.audiotrack;
      case TrackType.midi:  return Icons.piano;
      case TrackType.drum:  return Icons.grid_on;
      case TrackType.bus:   return Icons.merge_type;
    }
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
        boxShadow: [AppColors.glowBlue(4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PIXEL DAW',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 28, fontWeight: FontWeight.bold,
              color: AppColors.neonBlue, letterSpacing: 4,
              shadows: [Shadow(color: AppColors.neonBlue, blurRadius: 10)],
            )),
          const SizedBox(height: 4),
          const Text('Professional Mobile Music Production',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              _pill('DAW', AppColors.neonBlue),
              const SizedBox(width: 6),
              _pill('SEQUENCER', AppColors.neonPurple),
              const SizedBox(width: 6),
              _pill('MIXER', AppColors.neonGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: color, letterSpacing: 1.5)),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _ToolCard({required this.icon, required this.label, required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, color: color, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 7, color: AppColors.textMuted, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final dynamic track;
  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: track.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 18, color: track.color, margin: const EdgeInsets.only(right: 8)),
          Expanded(
            child: Text(track.name,
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: AppColors.textPrimary, letterSpacing: 1)),
          ),
          Text(track.type.name.toUpperCase(),
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _EmptyTracks extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTracks({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Center(
          child: Text('TAP + TO ADD TRACKS',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

