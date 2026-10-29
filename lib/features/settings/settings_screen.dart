import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/grouped_list.dart';
import '../../shared/widgets/large_title_scroll_view.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/sheets.dart';
import '../albums/albums_controller.dart';
import '../gallery/gallery_screen.dart';
import '../permissions/access_controller.dart';
import '../permissions/limited_access_banner.dart';
import 'settings_controller.dart';

void openSettings(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));

final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final counts = ref.watch(libraryCountsProvider).valueOrNull;
    final albums = ref.watch(albumsProvider).valueOrNull;
    final access = ref.watch(accessProvider).valueOrNull;
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final device = ref.watch(deviceServiceProvider);
    final c = context.colors;

    Widget pad(Widget child) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
      sliver: SliverToBoxAdapter(child: child),
    );

    return Scaffold(
      body: LargeTitleScrollView(
        title: 'Settings',
        leading: AppIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: 'Back',
          size: IconSizes.sm,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottomPadding: Insets.xxxl,
        slivers: [
          const SliverToBoxAdapter(
            child: SectionTitle(
              'Appearance',
              padding: EdgeInsets.fromLTRB(
                Insets.screen,
                0,
                Insets.sm,
                Insets.md,
              ),
            ),
          ),
          pad(_ThemePicker(selected: s.themeMode, onSelect: ctl.setThemeMode)),
          const SliverToBoxAdapter(child: SectionTitle('Grid')),
          pad(
            GroupedCard(
              children: [
                ListRow(
                  icon: Icons.grid_view_rounded,
                  label: 'Thumbnail size',
                  value: s.thumbSize.label,
                  onTap: () async {
                    final v = await showChoiceSheet(
                      context,
                      title: 'Thumbnail size',
                      description:
                          'Larger thumbnails show fewer items per row.',
                      values: ThumbSize.values,
                      selected: s.thumbSize,
                      label: (v) => v.label,
                    );
                    if (v != null) ctl.setThumbSize(v);
                  },
                ),
                ListRow(
                  icon: Icons.space_dashboard_outlined,
                  label: 'Grid density',
                  value: s.density.label,
                  onTap: () async {
                    final v = await showChoiceSheet(
                      context,
                      title: 'Grid density',
                      description:
                          'Compact keeps thumbnails edge to edge; Comfortable adds breathing room.',
                      values: GridDensity.values,
                      selected: s.density,
                      label: (v) => v.label,
                    );
                    if (v != null) ctl.setDensity(v);
                  },
                ),
                ListRow(
                  icon: Icons.calendar_view_month_outlined,
                  label: 'Group by date',
                  value: s.grouping.label,
                  showDivider: false,
                  onTap: () async {
                    final v = await showChoiceSheet(
                      context,
                      title: 'Group by date',
                      values: DateGrouping.values,
                      selected: s.grouping,
                      label: (v) => v.label,
                    );
                    if (v != null) ctl.setGrouping(v);
                  },
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('Library')),
          pad(
            GroupedCard(
              children: [
                ListRow(
                  icon: Icons.photo_outlined,
                  label: 'Photos',
                  count: counts?.photos,
                ),
                ListRow(
                  icon: Icons.videocam_outlined,
                  label: 'Videos',
                  count: counts?.videos,
                ),
                ListRow(
                  icon: Icons.photo_album_outlined,
                  label: 'Albums',
                  count: albums?.length,
                ),
                ListRow(
                  icon: Icons.lock_open_rounded,
                  label: 'Access',
                  value: switch (access?.level) {
                    AccessLevel.full => 'All photos',
                    AccessLevel.limited => 'Selected photos',
                    _ => '—',
                  },
                  showDivider: false,
                  onTap: access?.level == AccessLevel.limited
                      ? () => showManageAccessSheet(context, ref)
                      : null,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('Privacy')),
          pad(
            Container(
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: c.divider, width: 0.6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: c.accent,
                    size: IconSizes.md,
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      'Your photos never leave this device. Photos reads your library '
                      'through the system, works fully offline, and has no accounts, '
                      'analytics or uploads.',
                      style: context.text.bodyMedium?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pad(const SizedBox(height: Insets.md)),
          pad(
            GroupedCard(
              children: [
                ListRow(
                  icon: Icons.settings_outlined,
                  label: 'Photo access in system settings',
                  showDivider: false,
                  onTap: () =>
                      ref.read(mediaServiceProvider).openSystemSettings(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('About')),
          pad(
            GroupedCard(
              children: [
                ListRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  value: info == null
                      ? '—'
                      : '${info.version} (${info.buildNumber})',
                ),
                ListRow(
                  icon: Icons.favorite_border_rounded,
                  label: 'Favourites',
                  value: device.supportsSystemFavorites
                      ? 'Synced with system'
                      : 'Stored in this app',
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onSelect});
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in ThemeMode.values) ...[
          if (m != ThemeMode.values.first) const SizedBox(width: Insets.md),
          Expanded(
            child: _ThemeOption(
              mode: m,
              selected: m == selected,
              onTap: () {
                Haptics.tick();
                onSelect(m);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget preview(AppColors p) => Container(
      color: p.background,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 26, height: 5, color: p.textPrimary),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: List.generate(
                6,
                (i) => Container(
                  decoration: BoxDecoration(
                    color: p.skeleton,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final body = switch (mode) {
      ThemeMode.light => preview(AppColors.light),
      ThemeMode.dark => preview(AppColors.dark),
      ThemeMode.system => Row(
        children: [
          Expanded(child: ClipRect(child: preview(AppColors.light))),
          Expanded(child: ClipRect(child: preview(AppColors.dark))),
        ],
      ),
    };

    return Pressable(
      onTap: onTap,
      semanticLabel: '${mode.label} theme',
      selected: selected,
      child: Column(
        children: [
          AnimatedContainer(
            duration: Motion.medium,
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md + 3),
              border: Border.all(
                color: selected ? c.accent : c.divider,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: body,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            mode.label,
            style: context.text.labelMedium?.copyWith(
              color: selected ? c.textPrimary : c.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
