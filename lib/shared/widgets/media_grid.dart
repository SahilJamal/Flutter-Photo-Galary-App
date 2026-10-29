import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../features/settings/settings_controller.dart';
import '../../services/media_models.dart';
import '../state/favorites.dart';
import '../state/paged_assets.dart';
import '../state/selection.dart';
import 'asset_thumbnail.dart';
import 'asset_tile.dart';
import 'message_view.dart';
import 'skeleton.dart';

/// Column count, spacing and decode size for a given width and settings.
class GridMetrics {
  GridMetrics._(this.columns, this.gap, this.radius, this.thumbPx);

  factory GridMetrics.resolve({
    required double width,
    required AppSettings settings,
    required double dpr,
  }) {
    final size = settings.thumbSize;
    final minColumns = size == ThumbSize.large
        ? 2
        : (size == ThumbSize.small ? 4 : 3);
    final columns = math
        .max(minColumns, (width / size.targetWidth).round())
        .clamp(2, 14);
    final gap = settings.density.gap;
    final cell = (width - gap * (columns - 1)) / columns;
    return GridMetrics._(
      columns,
      gap,
      settings.density.radius,
      bucketPx(cell, dpr),
    );
  }

  final int columns;
  final double gap;
  final double radius;
  final int thumbPx;

  EdgeInsets get padding => EdgeInsets.symmetric(horizontal: gap > 2 ? gap : 0);
}

class GridSection {
  const GridSection(this.label, this.start, this.length);
  final String? label;
  final int start;
  final int length;
}

final _sectionCache = Expando<(DateGrouping, List<GridSection>)>();

List<GridSection> sectionsFor(List<AssetEntity> items, DateGrouping grouping) {
  final cached = _sectionCache[items];
  if (cached != null && cached.$1 == grouping) return cached.$2;
  final now = DateTime.now();
  final result = <GridSection>[];
  if (grouping == DateGrouping.none || items.isEmpty) {
    result.add(GridSection(null, 0, items.length));
  } else {
    int keyOf(DateTime d) => switch (grouping) {
      DateGrouping.day => d.year * 10000 + d.month * 100 + d.day,
      DateGrouping.month => d.year * 100 + d.month,
      _ => d.year,
    };
    String labelOf(DateTime d) => switch (grouping) {
      DateGrouping.day => Formatters.dayHeader(d, now),
      DateGrouping.month => Formatters.monthHeader(d, now),
      _ => '${d.year}',
    };
    var start = 0;
    var key = keyOf(items.first.createDateTime);
    for (var i = 1; i <= items.length; i++) {
      final k = i < items.length ? keyOf(items[i].createDateTime) : -1;
      if (k != key) {
        result.add(
          GridSection(labelOf(items[start].createDateTime), start, i - start),
        );
        start = i;
        key = k;
      }
    }
  }
  _sectionCache[items] = (grouping, result);
  return result;
}

/// The paginated, grouped, selectable grid used by every media screen.
class MediaGridSliver extends ConsumerWidget {
  const MediaGridSliver({
    super.key,
    required this.spec,
    required this.selectionScope,
    required this.heroScope,
    required this.onOpen,
    required this.empty,
    this.groupingOverride,
  });

  final MediaQuerySpec spec;
  final String selectionScope;
  final String heroScope;
  final void Function(int index, int thumbPx) onOpen;
  final Widget empty;
  final DateGrouping? groupingOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final paged = ref.watch(pagedAssetsProvider(spec));
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final m = GridMetrics.resolve(
          width: constraints.crossAxisExtent,
          settings: settings,
          dpr: dpr,
        );
        if (paged.initialLoading) {
          return SkeletonGridSliver(
            columns: m.columns,
            gap: m.gap,
            radius: m.radius,
          );
        }
        if (paged.error != null && paged.items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: MessageView.error(
              onRetry: () =>
                  ref.read(pagedAssetsProvider(spec).notifier).retry(),
            ),
          );
        }
        if (paged.items.isEmpty) {
          return SliverFillRemaining(hasScrollBody: false, child: empty);
        }
        return _Grid(
          spec: spec,
          paged: paged,
          metrics: m,
          grouping: groupingOverride ?? settings.grouping,
          selectionScope: selectionScope,
          heroScope: heroScope,
          onOpen: onOpen,
        );
      },
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({
    required this.spec,
    required this.paged,
    required this.metrics,
    required this.grouping,
    required this.selectionScope,
    required this.heroScope,
    required this.onOpen,
  });

  final MediaQuerySpec spec;
  final PagedAssets paged;
  final GridMetrics metrics;
  final DateGrouping grouping;
  final String selectionScope;
  final String heroScope;
  final void Function(int index, int thumbPx) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider(selectionScope));
    final favorites = ref.watch(favoritesProvider);
    final items = paged.items;
    final sections = sectionsFor(items, grouping);
    final m = metrics;

    void maybeLoadMore(int index) {
      if (paged.hasMore && !paged.loadingMore && index >= items.length - 60) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ref.read(pagedAssetsProvider(spec).notifier).loadMore();
        });
      }
    }

    Widget tile(int index) {
      maybeLoadMore(index);
      final e = items[index];
      final sel = ref.read(selectionProvider(selectionScope).notifier);
      return AssetTile(
        key: ValueKey(e.id),
        entity: e,
        thumbPx: m.thumbPx,
        radius: m.radius,
        heroTag: '$heroScope/${e.id}',
        selectionMode: selection.active,
        selected: selection.contains(e.id),
        favorite: favorites.isFavorite(e),
        onTap: () {
          if (selection.active) {
            Haptics.tick();
            sel.toggle(e.id);
          } else {
            onOpen(index, m.thumbPx);
          }
        },
        onLongPress: () {
          Haptics.medium();
          selection.active ? sel.toggle(e.id) : sel.start(e.id);
        },
      );
    }

    SliverGrid grid(GridSection s) => SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: m.columns,
        mainAxisSpacing: m.gap,
        crossAxisSpacing: m.gap,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => tile(s.start + i),
        childCount: s.length,
        findChildIndexCallback: (key) {
          final id = (key as ValueKey<String>).value;
          for (var i = 0; i < s.length; i++) {
            if (items[s.start + i].id == id) return i;
          }
          return null;
        },
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        for (final s in sections) ...[
          if (s.label != null)
            SliverToBoxAdapter(child: _SectionHeader(label: s.label!)),
          SliverPadding(padding: m.padding, sliver: grid(s)),
        ],
        if (paged.hasMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(Insets.xl),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.xl,
        Insets.screen,
        Insets.md,
      ),
      child: Semantics(
        header: true,
        child: Text(label, style: context.text.titleSmall),
      ),
    );
  }
}
