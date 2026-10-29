import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/media_actions.dart';
import '../../shared/state/favorites.dart';
import '../../shared/state/paged_assets.dart';
import '../../shared/widgets/buttons.dart';
import 'info_sheet.dart';
import 'video_page.dart';
import 'zoomable_photo.dart';

/// Opens the full-screen viewer over the list described by [spec].
void openViewer(
  BuildContext context, {
  required MediaQuerySpec spec,
  required int index,
  required String heroScope,
  required int thumbPx,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Motion.hero,
      reverseTransitionDuration: Motion.hero,
      pageBuilder: (_, _, _) => ViewerScreen(
        spec: spec,
        initialIndex: index,
        heroScope: heroScope,
        thumbPx: thumbPx,
      ),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({
    super.key,
    required this.spec,
    required this.initialIndex,
    required this.heroScope,
    required this.thumbPx,
  });

  final MediaQuerySpec spec;
  final int initialIndex;
  final String heroScope;
  final int thumbPx;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  String? _currentId;
  bool _chrome = true;
  bool _zoomed = false;

  static const _toolbarHeight = 64.0;

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pages.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    SystemChrome.setEnabledSystemUIMode(
      _chrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  /// Keeps the same asset on screen when the list changes underneath us
  /// (new photo taken, item deleted elsewhere).
  void _reconcile(List<AssetEntity> items) {
    if (items.isEmpty) return;
    final id = _currentId;
    if (id == null) {
      _currentId = items[_index.clamp(0, items.length - 1)].id;
      return;
    }
    if (_index < items.length && items[_index].id == id) return;
    final found = items.indexWhere((e) => e.id == id);
    final target = found >= 0 ? found : _index.clamp(0, items.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      if (_pages.page?.round() != target) _pages.jumpToPage(target);
      setState(() {
        _index = target;
        _currentId = items[target].id;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(pagedAssetsProvider(widget.spec));
    final items = paged.items;
    final c = context.colors;

    if (items.isEmpty && !paged.initialLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
    _reconcile(items);

    final current = items.isEmpty
        ? null
        : items[_index.clamp(0, items.length - 1)];
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final bg = _chrome ? c.background : Colors.black;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_chrome && !context.isDark)
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: AnimatedContainer(
        duration: Motion.medium,
        color: bg,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _pages,
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                  itemCount: items.length,
                  onPageChanged: (i) {
                    setState(() {
                      _index = i;
                      _currentId = items[i].id;
                      _zoomed = false;
                    });
                    if (i >= items.length - 8) {
                      ref
                          .read(pagedAssetsProvider(widget.spec).notifier)
                          .loadMore();
                    }
                  },
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final tag = '${widget.heroScope}/${e.id}';
                    if (e.type == AssetType.video) {
                      return VideoPage(
                        key: ValueKey(e.id),
                        entity: e,
                        heroTag: tag,
                        thumbPx: widget.thumbPx,
                        active: i == _index,
                        chromeVisible: _chrome,
                        bottomInset: bottomPad + _toolbarHeight + Insets.md,
                        onTap: _toggleChrome,
                      );
                    }
                    return ZoomablePhoto(
                      key: ValueKey(e.id),
                      entity: e,
                      heroTag: tag,
                      thumbPx: widget.thumbPx,
                      onTap: _toggleChrome,
                      onZoomChanged: (z) {
                        if (z != _zoomed && i == _index) {
                          setState(() => _zoomed = z);
                        }
                      },
                    );
                  },
                ),
              ),
              if (current != null) ...[
                _Chrome(
                  visible: _chrome,
                  top: true,
                  child: _TopBar(entity: current),
                ),
                _Chrome(
                  visible: _chrome,
                  top: false,
                  child: _Toolbar(
                    entity: current,
                    height: _toolbarHeight,
                    onDeleted: (ids) => ref
                        .read(pagedAssetsProvider(widget.spec).notifier)
                        .removeIds(ids),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and slides a bar in or out; ignores touches while hidden.
class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.visible,
    required this.top,
    required this.child,
  });
  final bool visible;
  final bool top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : Offset(0, top ? -0.3 : 0.3),
          duration: Motion.medium,
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: Motion.medium,
            child: Container(
              color: c.background.withValues(alpha: 0.92),
              child: SafeArea(top: top, bottom: !top, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.entity});
  final AssetEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider).isFavorite(entity);
    final c = context.colors;
    final d = entity.createDateTime;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: Insets.xs),
          AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            size: IconSizes.sm,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Formatters.shortDate(d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                Text(
                  Formatters.time(d),
                  maxLines: 1,
                  style: context.text.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            tooltip: fav ? 'Remove from Favourites' : 'Add to Favourites',
            color: fav ? c.favorite : null,
            onPressed: () =>
                MediaActions.setFavorite(context, ref, [entity], !fav),
          ),
          const SizedBox(width: Insets.xs),
        ],
      ),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.entity,
    required this.height,
    required this.onDeleted,
  });
  final AssetEntity entity;
  final double height;
  final ValueChanged<Set<String>> onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider).isFavorite(entity);
    final c = context.colors;
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Builder(
            builder: (btn) => AppIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: 'Share',
              onPressed: () {
                final box = btn.findRenderObject() as RenderBox?;
                MediaActions.share(
                  context,
                  ref,
                  [entity],
                  origin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                );
              },
            ),
          ),
          AppIconButton(
            icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            tooltip: fav ? 'Remove from Favourites' : 'Add to Favourites',
            color: fav ? c.favorite : null,
            onPressed: () =>
                MediaActions.setFavorite(context, ref, [entity], !fav),
          ),
          AppIconButton(
            icon: Icons.info_outline_rounded,
            tooltip: 'Details',
            onPressed: () => showInfoSheet(context, entity),
          ),
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete',
            onPressed: () async {
              final removed = await MediaActions.delete(context, ref, [entity]);
              if (removed.isNotEmpty) onDeleted(removed);
            },
          ),
        ],
      ),
    );
  }
}
