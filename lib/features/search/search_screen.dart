import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/media_models.dart';
import '../../shared/providers.dart';
import '../../shared/state/paged_assets.dart';
import '../../shared/state/selection.dart';
import '../../shared/widgets/asset_thumbnail.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/large_title_scroll_view.dart';
import '../../shared/widgets/media_grid.dart';
import '../../shared/widgets/message_view.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/selection_bars.dart';
import '../../shared/widgets/skeleton.dart';
import '../albums/album_card.dart';
import '../albums/album_detail_screen.dart';
import '../settings/settings_controller.dart';
import '../viewer/viewer_screen.dart';
import 'search_controller.dart';

const searchSelectionScope = 'search';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.controller, this.active = true});
  final ScrollController? controller;
  final bool active;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void didUpdateWidget(covariant SearchScreen old) {
    super.didUpdateWidget(old);
    if (!widget.active) _focus.unfocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      ref.read(searchProvider.notifier).setQuery(v);
      ref.read(selectionProvider(searchSelectionScope).notifier).exit();
    });
  }

  void _apply(String q) {
    _text.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    _debounce?.cancel();
    ref.read(searchProvider.notifier).setQuery(q);
    ref.read(recentSearchesProvider.notifier).add(q);
    _focus.unfocus();
    setState(() {});
  }

  void _clear() {
    _text.clear();
    _debounce?.cancel();
    ref.read(searchProvider.notifier).setQuery('');
    setState(() {});
  }

  void _remember() {
    final q = _text.text.trim();
    if (q.isNotEmpty) ref.read(recentSearchesProvider.notifier).add(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final plan = ref.watch(searchPlanProvider);
    final selecting = ref.watch(selectionProvider(searchSelectionScope)).active;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(selectionProvider(searchSelectionScope).notifier).exit();
        }
      },
      child: LargeTitleScrollView(
        title: 'Search',
        controller: widget.controller,
        pinnedOverride: selecting && plan?.spec != null
            ? SelectionHeader(scope: searchSelectionScope, spec: plan!.spec!)
            : null,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              height: 60 * textScale.scale(1) + 52,
              background: context.colors.background,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScale),
                child: _SearchBar(
                  controller: _text,
                  focus: _focus,
                  filter: state.filter,
                  onChanged: _onChanged,
                  onSubmitted: _apply,
                  onClear: _clear,
                  onFilter: (f) {
                    Haptics.tick();
                    ref.read(searchProvider.notifier).toggleFilter(f);
                    ref
                        .read(selectionProvider(searchSelectionScope).notifier)
                        .exit();
                  },
                ),
              ),
            ),
          ),
          if (plan == null)
            ..._idle(context)
          else
            ..._results(context, plan, state),
        ],
      ),
    );
  }

  List<Widget> _idle(BuildContext context) {
    final recent = ref.watch(recentSearchesProvider);
    final years = ref.watch(yearsProvider);
    final c = context.colors;
    return [
      if (recent.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionTitle(
            'Recent',
            trailing: AppTextButton(
              label: 'Clear',
              color: c.accent,
              onPressed: () {
                Haptics.light();
                ref.read(recentSearchesProvider.notifier).clear();
              },
            ),
          ),
        ),
        SliverList.builder(
          itemCount: recent.length,
          itemBuilder: (context, i) => _RecentRow(
            text: recent[i],
            onTap: () => _apply(recent[i]),
            onRemove: () =>
                ref.read(recentSearchesProvider.notifier).remove(recent[i]),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SectionTitle('Browse by Date')),
      SliverToBoxAdapter(
        child: years.when(
          loading: () => const _YearRowSkeleton(),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
            child: AppTextButton(
              label: 'Try again',
              onPressed: () => ref.invalidate(yearsProvider),
            ),
          ),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.screen,
                  ),
                  child: Text(
                    'Dates appear once you have photos.',
                    style: context.text.bodySmall,
                  ),
                )
              : _YearRow(years: list),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            Insets.xxl,
            Insets.screen,
            0,
          ),
          child: Text(
            'Search by album name, a month like “March”, or a year like “2024”'
            '${ref.read(deviceServiceProvider).supportsNameSearch ? ', or part of a file name' : ''}.',
            style: context.text.bodySmall?.copyWith(color: c.textTertiary),
          ),
        ),
      ),
    ];
  }

  List<Widget> _results(
    BuildContext context,
    SearchPlan plan,
    SearchState state,
  ) {
    final q = state.query.trim();
    final spec = plan.spec;
    final c = context.colors;
    final noResults = MessageView(
      compact: true,
      icon: Icons.search_off_rounded,
      title: q.isEmpty ? 'Nothing here' : 'No results for “$q”',
      message: q.isEmpty
          ? 'There are no ${state.filter?.label.toLowerCase() ?? 'items'} in your library yet.'
          : 'Try an album name, a month like “March”, or a year like “2024”.',
    );
    return [
      if (plan.date != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.screen,
              Insets.lg,
              Insets.screen,
              0,
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: IconSizes.sm, color: c.accent),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    'Showing ${plan.date!.label}',
                    style: context.text.labelMedium?.copyWith(color: c.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (plan.albums.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionTitle('Albums')),
        SliverToBoxAdapter(
          child: _AlbumRow(albums: plan.albums, onOpen: _remember),
        ),
      ],
      if (spec != null) ...[
        SliverToBoxAdapter(child: _ResultsTitle(spec: spec)),
        MediaGridSliver(
          spec: spec,
          selectionScope: searchSelectionScope,
          heroScope: searchSelectionScope,
          groupingOverride: DateGrouping.none,
          empty: plan.albums.isEmpty
              ? noResults
              : _InlineNote('No photos or videos match “$q”.'),
          onOpen: (index, px) {
            _remember();
            openViewer(
              context,
              spec: spec,
              index: index,
              heroScope: searchSelectionScope,
              thumbPx: px,
            );
          },
        ),
      ] else if (plan.albums.isEmpty)
        SliverFillRemaining(hasScrollBody: false, child: noResults)
      else
        const SliverToBoxAdapter(
          child: _InlineNote(
            'Searching inside file names isn’t available on this device.',
          ),
        ),
    ];
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Insets.screen,
      Insets.sm,
      Insets.screen,
      Insets.xl,
    ),
    child: Text(text, style: context.text.bodySmall),
  );
}

class _ResultsTitle extends ConsumerWidget {
  const _ResultsTitle({required this.spec});
  final MediaQuerySpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paged = ref.watch(pagedAssetsProvider(spec));
    final label = paged.initialLoading
        ? null
        : Formatters.plural(paged.total, 'result');
    return SectionTitle(
      'Photos & Videos',
      trailing: label == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: Insets.md),
              child: Text(label, style: context.text.bodySmall),
            ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarDelegate({
    required this.height,
    required this.child,
    required this.background,
  });
  final double height;
  final Color background;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(
    height: height,
    child: ColoredBox(color: background, child: child),
  );

  @override
  bool shouldRebuild(_SearchBarDelegate old) =>
      old.height != height ||
      old.child != child ||
      old.background != background;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focus,
    required this.filter,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final SearchFilter? filter;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<SearchFilter> onFilter;

  static const _icons = {
    SearchFilter.photos: Icons.photo_outlined,
    SearchFilter.videos: Icons.videocam_outlined,
    SearchFilter.screenshots: Icons.screenshot_outlined,
    SearchFilter.favorites: Icons.favorite_border_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            Insets.xs,
            Insets.screen,
            Insets.sm,
          ),
          child: TextField(
            controller: controller,
            focusNode: focus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Albums, months, years',
              hintStyle: context.text.bodyLarge?.copyWith(
                color: c.textTertiary,
              ),
              filled: true,
              fillColor: c.surfaceMuted,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: c.textSecondary,
                size: IconSizes.md,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: c.textTertiary,
                        size: IconSizes.sm,
                      ),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
            children: [
              for (final f in SearchFilter.values) ...[
                _FilterChip(
                  label: f.label,
                  icon: _icons[f]!,
                  selected: filter == f,
                  onTap: () => onFilter(f),
                ),
                const SizedBox(width: Insets.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.background : c.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label filter',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          padding: const EdgeInsets.symmetric(horizontal: Insets.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.textPrimary : c.surface,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: selected ? c.textPrimary : c.divider,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? Icons.check_rounded : icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label, style: context.text.labelMedium?.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.text,
    required this.onTap,
    required this.onRemove,
  });
  final String text;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: Insets.screen, right: Insets.xs),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: IconSizes.sm,
              color: c.textTertiary,
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyLarge,
              ),
            ),
            AppIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Remove “$text”',
              size: IconSizes.sm,
              color: c.textTertiary,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.years});
  final List<YearBucket> years;

  @override
  Widget build(BuildContext context) {
    const size = 136.0;
    final px = bucketPx(size, MediaQuery.devicePixelRatioOf(context));
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
        itemCount: years.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
        itemBuilder: (context, i) {
          final y = years[i];
          return Pressable(
            semanticLabel: '${y.year}, ${Formatters.plural(y.count, 'item')}',
            onTap: () => openCollection(
              context,
              title: '${y.year}',
              spec: MediaQuerySpec(
                from: DateTime(y.year),
                to: DateTime(y.year + 1),
              ),
              scope: 'year:${y.year}',
              grouping: DateGrouping.month,
            ),
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.lg),
                child: SizedBox.square(
                  dimension: size,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (y.cover != null)
                        FadeInAssetImage(
                          image: thumbnailProvider(y.cover!, px),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x8C000000)],
                            stops: [0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: Insets.md,
                        right: Insets.md,
                        bottom: Insets.md,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${y.year}',
                              style: context.text.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              Formatters.count(y.count),
                              style: context.text.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _YearRowSkeleton extends StatelessWidget {
  const _YearRowSkeleton();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 136,
    child: SkeletonPulse(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
        itemBuilder: (_, _) =>
            const SkeletonBox(width: 136, height: 136, radius: Radii.lg),
      ),
    ),
  );
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.albums, required this.onOpen});
  final List<AlbumInfo> albums;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const w = 128.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: w + 10 + 42 * textScale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
        itemCount: albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
        itemBuilder: (context, i) {
          final a = albums[i];
          return SizedBox(
            width: w,
            child: AlbumCard(
              name: a.name,
              count: a.count,
              cover: a.cover,
              kind: a.kind,
              onTap: () {
                onOpen();
                openCollection(
                  context,
                  title: a.name,
                  spec: MediaQuerySpec(albumId: a.id),
                  scope: 'album:${a.id}',
                );
              },
            ),
          );
        },
      ),
    );
  }
}
