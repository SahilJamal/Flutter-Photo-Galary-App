import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../services/media_models.dart';
import '../../shared/state/selection.dart';
import '../../shared/widgets/large_title_scroll_view.dart';
import '../../shared/widgets/media_grid.dart';
import '../../shared/widgets/selection_bars.dart';
import '../settings/settings_controller.dart';
import '../viewer/viewer_screen.dart';

/// Large-title screen around a [MediaGridSliver], with multi-select. Used for
/// the library, albums, favourites, years and search results.
class MediaCollectionView extends ConsumerWidget {
  const MediaCollectionView({
    super.key,
    required this.title,
    required this.spec,
    required this.scope,
    required this.empty,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.headerSlivers = const [],
    this.ownSelectionBar = true,
    this.groupingOverride,
    this.controller,
  });

  final String title;
  final Widget? subtitle;
  final MediaQuerySpec spec;

  /// Selection and hero namespace; unique per screen.
  final String scope;
  final Widget empty;
  final Widget? leading;
  final List<Widget> actions;
  final List<Widget> headerSlivers;

  /// False when a parent (the home shell) shows the selection bar instead.
  final bool ownSelectionBar;
  final DateGrouping? groupingOverride;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectionProvider(scope));

    return PopScope(
      canPop: !sel.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(selectionProvider(scope).notifier).exit();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: LargeTitleScrollView(
              controller: controller,
              title: title,
              subtitle: subtitle,
              leading: leading,
              actions: actions,
              bottomPadding: ownSelectionBar && sel.active ? 64 : Insets.lg,
              pinnedOverride: sel.active
                  ? SelectionHeader(scope: scope, spec: spec)
                  : null,
              slivers: [
                ...headerSlivers,
                MediaGridSliver(
                  spec: spec,
                  selectionScope: scope,
                  heroScope: scope,
                  groupingOverride: groupingOverride,
                  empty: empty,
                  onOpen: (index, thumbPx) => openViewer(
                    context,
                    spec: spec,
                    index: index,
                    heroScope: scope,
                    thumbPx: thumbPx,
                  ),
                ),
              ],
            ),
          ),
          if (ownSelectionBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: sel.active ? Offset.zero : const Offset(0, 1.2),
                duration: Motion.medium,
                curve: Motion.curve,
                child: AnimatedOpacity(
                  opacity: sel.active ? 1 : 0,
                  duration: Motion.fast,
                  child: IgnorePointer(
                    ignoring: !sel.active,
                    child: SelectionActionBar(scope: scope, spec: spec),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
