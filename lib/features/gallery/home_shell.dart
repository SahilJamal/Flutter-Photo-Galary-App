import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../services/media_models.dart';
import '../../shared/state/selection.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/selection_bars.dart';
import '../albums/albums_screen.dart';
import '../search/search_controller.dart';
import '../search/search_screen.dart';
import 'gallery_screen.dart';

/// Three-tab shell: Photos, Albums, Search.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  final _controllers = List.generate(3, (_) => ScrollController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _select(int i) {
    if (i == _tab) {
      final c = _controllers[i];
      if (c.hasClients) {
        c.animateTo(0, duration: Motion.slow, curve: Motion.emphasized);
      }
      return;
    }
    Haptics.tick();
    ref.read(selectionProvider(librarySelectionScope).notifier).exit();
    ref.read(selectionProvider(searchSelectionScope).notifier).exit();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final searchSpec = ref.watch(searchPlanProvider)?.spec;
    final selectingLibrary =
        _tab == 0 && ref.watch(selectionProvider(librarySelectionScope)).active;
    final selectingSearch =
        _tab == 2 &&
        searchSpec != null &&
        ref.watch(selectionProvider(searchSelectionScope)).active;

    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _tab,
          children: [
            GalleryScreen(
              controller: _controllers[0],
              onSearch: () => _select(2),
            ),
            AlbumsScreen(controller: _controllers[1]),
            SearchScreen(controller: _controllers[2], active: _tab == 2),
          ],
        ),
        bottomNavigationBar: AnimatedSwitcher(
          duration: Motion.medium,
          switchInCurve: Motion.curve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: selectingLibrary
              ? const SelectionActionBar(
                  key: ValueKey('library-selection'),
                  scope: librarySelectionScope,
                  spec: MediaQuerySpec.library,
                )
              : selectingSearch
              ? SelectionActionBar(
                  key: const ValueKey('search-selection'),
                  scope: searchSelectionScope,
                  spec: searchSpec,
                )
              : AppNavBar(
                  key: const ValueKey('nav'),
                  index: _tab,
                  onSelect: _select,
                ),
        ),
      ),
    );
  }
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.photo_library_outlined, Icons.photo_library_rounded, 'Photos'),
    (Icons.photo_album_outlined, Icons.photo_album_rounded, 'Albums'),
    (Icons.search_rounded, Icons.manage_search_rounded, 'Search'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            border: Border(top: BorderSide(color: c.divider, width: 0.6)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg,
                vertical: Insets.xs,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _items[i].$1,
                        activeIcon: _items[i].$2,
                        label: _items[i].$3,
                        active: i == index,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.textPrimary : c.textTertiary;
    return Semantics(
      selected: active,
      button: true,
      label: '$label tab',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Motion.medium,
                curve: Motion.curve,
                width: active ? 60 : 44,
                height: 30,
                decoration: BoxDecoration(
                  color: active
                      ? c.textPrimary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: AnimatedSwitcher(
                  duration: Motion.fast,
                  transitionBuilder: (child, a) => ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(a),
                    child: FadeTransition(opacity: a, child: child),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    key: ValueKey(active),
                    color: fg,
                    size: IconSizes.md,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: Motion.medium,
                style: context.text.labelSmall!.copyWith(
                  color: fg,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
