import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// A scroll view with a large title that hands off to a compact, blurred,
/// pinned bar as you scroll, the way native photo apps do.
class LargeTitleScrollView extends StatefulWidget {
  const LargeTitleScrollView({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.pinnedOverride,
    this.controller,
    this.bottomPadding = 0,
  });

  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  /// Replaces the pinned bar's content (e.g. the selection header).
  final Widget? pinnedOverride;
  final List<Widget> slivers;
  final ScrollController? controller;
  final double bottomPadding;

  @override
  State<LargeTitleScrollView> createState() => _LargeTitleScrollViewState();
}

class _LargeTitleScrollViewState extends State<LargeTitleScrollView> {
  ScrollController? _own;
  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());
  final _collapsed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant LargeTitleScrollView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_onScroll);
      _controller.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final c = _controller;
    if (!c.hasClients) return;
    _collapsed.value = c.offset > 36;
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _own?.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scrollbar(
      controller: _controller,
      interactive: true,
      child: CustomScrollView(
        controller: _controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedBar(
              height: top + 52,
              topPadding: top,
              collapsed: _collapsed,
              title: widget.title,
              leading: widget.leading,
              actions: widget.actions,
              overrideChild: widget.pinnedOverride,
              colors: context.colors,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                0,
                Insets.screen,
                Insets.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(widget.title, style: context.text.displaySmall),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: Insets.xs),
                    DefaultTextStyle.merge(
                      style: context.text.bodySmall,
                      child: widget.subtitle!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          ...widget.slivers,
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  widget.bottomPadding + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedBar extends SliverPersistentHeaderDelegate {
  _PinnedBar({
    required this.height,
    required this.topPadding,
    required this.collapsed,
    required this.title,
    required this.leading,
    required this.actions,
    required this.overrideChild,
    required this.colors,
  });

  /// Part of the delegate so a theme change rebuilds the bar.
  final AppColors colors;

  final double height;
  final double topPadding;
  final ValueNotifier<bool> collapsed;
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? overrideChild;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final c = context.colors;
    return ValueListenableBuilder<bool>(
      valueListenable: collapsed,
      builder: (context, isCollapsed, _) {
        final solid = isCollapsed || overrideChild != null;
        return SizedBox(
          height: height,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: solid ? 24 : 0,
                sigmaY: solid ? 24 : 0,
              ),
              child: AnimatedContainer(
                duration: Motion.medium,
                decoration: BoxDecoration(
                  color: solid ? c.surfaceElevated : c.background,
                  border: Border(
                    bottom: BorderSide(
                      color: solid ? c.divider : c.divider.withValues(alpha: 0),
                      width: 0.6,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: topPadding,
                  left: Insets.xs,
                  right: Insets.xs,
                ),
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Motion.curve,
                  child: overrideChild != null
                      ? KeyedSubtree(
                          key: const ValueKey('override'),
                          child: overrideChild!,
                        )
                      : Row(
                          key: const ValueKey('bar'),
                          children: [
                            if (leading != null)
                              leading!
                            else
                              const SizedBox(width: Insets.lg),
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: isCollapsed ? 1 : 0,
                                duration: Motion.fast,
                                child: Text(
                                  title,
                                  textAlign: leading != null
                                      ? TextAlign.center
                                      : TextAlign.start,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleMedium,
                                ),
                              ),
                            ),
                            ...actions,
                            if (leading != null && actions.isEmpty)
                              const SizedBox(width: 44),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_PinnedBar old) =>
      old.height != height ||
      old.title != title ||
      old.overrideChild != overrideChild ||
      old.colors != colors ||
      old.actions != actions ||
      old.leading != leading;
}
