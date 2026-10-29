import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/media_models.dart';
import '../media_actions.dart';
import '../state/favorites.dart';
import '../state/paged_assets.dart';
import '../state/selection.dart';
import 'pressable.dart';

/// Pinned header shown while selecting: Cancel · N selected · Select all.
class SelectionHeader extends ConsumerWidget {
  const SelectionHeader({super.key, required this.scope, required this.spec});
  final String scope;
  final MediaQuerySpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectionProvider(scope));
    final paged = ref.watch(pagedAssetsProvider(spec));
    final notifier = ref.read(selectionProvider(scope).notifier);
    final allSelected = sel.count > 0 && sel.count >= paged.total;
    final c = context.colors;

    return Row(
      children: [
        TextButton(
          onPressed: notifier.exit,
          style: TextButton.styleFrom(
            foregroundColor: c.textPrimary,
            minimumSize: const Size(64, 44),
          ),
          child: const Text('Cancel'),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              sel.count == 0
                  ? 'Select items'
                  : '${Formatters.count(sel.count)} selected',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Haptics.tick();
            if (allSelected) {
              notifier.clearSelection();
            } else {
              final all = await ref
                  .read(pagedAssetsProvider(spec).notifier)
                  .loadAll();
              notifier.selectAll(all.map((e) => e.id));
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: c.accent,
            minimumSize: const Size(64, 44),
          ),
          child: Text(allSelected ? 'Deselect all' : 'Select all'),
        ),
      ],
    );
  }
}

/// Contextual action bar for a selection: Share · Favourite · Delete.
class SelectionActionBar extends ConsumerWidget {
  const SelectionActionBar({
    super.key,
    required this.scope,
    required this.spec,
  });
  final String scope;
  final MediaQuerySpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectionProvider(scope));
    final favorites = ref.watch(favoritesProvider);
    final c = context.colors;

    List<AssetEntity> selected() {
      final items = ref.read(pagedAssetsProvider(spec)).items;
      return items.where((e) => sel.ids.contains(e.id)).toList();
    }

    final enabled = sel.count > 0;
    final allFavorite = enabled && selected().every(favorites.isFavorite);

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        border: Border(top: BorderSide(color: c.divider, width: 0.6)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
        top: Insets.xs,
        left: Insets.sm,
        right: Insets.sm,
      ),
      child: Row(
        children: [
          Builder(
            builder: (btnContext) => _BarAction(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: enabled
                  ? () {
                      final box = btnContext.findRenderObject() as RenderBox?;
                      final origin = box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size;
                      MediaActions.share(
                        context,
                        ref,
                        selected(),
                        origin: origin,
                      );
                    }
                  : null,
            ),
          ),
          _BarAction(
            icon: allFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: allFavorite ? 'Unfavourite' : 'Favourite',
            onTap: enabled
                ? () async {
                    await MediaActions.setFavorite(
                      context,
                      ref,
                      selected(),
                      !allFavorite,
                    );
                  }
                : null,
          ),
          _BarAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: c.danger,
            onTap: enabled
                ? () async {
                    final removed = await MediaActions.delete(
                      context,
                      ref,
                      selected(),
                    );
                    if (removed.isNotEmpty) {
                      ref
                          .read(pagedAssetsProvider(spec).notifier)
                          .removeIds(removed);
                      ref.read(selectionProvider(scope).notifier).exit();
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.textPrimary;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedOpacity(
          duration: Motion.fast,
          opacity: onTap == null ? 0.35 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg, size: IconSizes.md),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
