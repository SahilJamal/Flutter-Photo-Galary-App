import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/grouped_list.dart';
import '../../shared/widgets/large_title_scroll_view.dart';
import '../../shared/widgets/message_view.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/skeleton.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_screen.dart';
import 'album_card.dart';
import 'album_detail_screen.dart';
import 'albums_controller.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key, this.controller});
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    final types = ref.watch(mediaTypesProvider).valueOrNull;
    final list = albums.valueOrNull;

    return LargeTitleScrollView(
      title: 'Albums',
      controller: controller,
      subtitle: Text(
        list == null ? ' ' : Formatters.plural(list.length, 'album'),
      ),
      actions: [
        AppIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Settings',
          onPressed: () => openSettings(context),
        ),
        const SizedBox(width: 4),
      ],
      slivers: [
        if (albums.hasError && list == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: MessageView.error(
              onRetry: () => ref.invalidate(albumsProvider),
            ),
          )
        else if (list == null)
          const _AlbumGridSkeleton()
        else if (list.isEmpty &&
            (types == null || types.videos + types.favorites == 0))
          const SliverFillRemaining(
            hasScrollBody: false,
            child: MessageView(
              icon: Icons.photo_album_outlined,
              title: 'No albums yet',
              message:
                  'Folders like Camera, Screenshots and Downloads appear here once they contain photos or videos.',
            ),
          )
        else ...[
          if (list.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionTitle(
                'My Albums',
                padding: EdgeInsets.fromLTRB(
                  Insets.screen,
                  0,
                  Insets.sm,
                  Insets.md,
                ),
              ),
            ),
            _AlbumGrid(albums: list),
          ],
          const SliverToBoxAdapter(child: SectionTitle('Media Types')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
            sliver: SliverToBoxAdapter(
              child: GroupedCard(
                children: [
                  ListRow(
                    icon: Icons.videocam_outlined,
                    label: 'Videos',
                    count: types?.videos,
                    onTap: () => openCollection(
                      context,
                      title: 'Videos',
                      spec: videosSpec,
                      scope: 'type:videos',
                      emptyIcon: Icons.videocam_outlined,
                      emptyTitle: 'No videos',
                      emptyMessage:
                          'Videos you record or save will appear here.',
                    ),
                  ),
                  ListRow(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favourites',
                    count: types?.favorites,
                    showDivider: false,
                    onTap: () => openCollection(
                      context,
                      title: 'Favourites',
                      spec: favoritesSpec,
                      scope: 'type:favorites',
                      grouping: DateGrouping.none,
                      emptyIcon: Icons.favorite_border_rounded,
                      emptyTitle: 'No favourites yet',
                      emptyMessage:
                          'Tap the heart on any photo or video to keep it here.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

int _albumColumns(double width) => math.max(2, (width / 200).floor());

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums});
  final List<AlbumInfo> albums;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final cols = _albumColumns(constraints.crossAxisExtent);
          const gap = Insets.lg;
          final cell = (constraints.crossAxisExtent - gap * (cols - 1)) / cols;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: gap,
              mainAxisSpacing: Insets.xl,
              mainAxisExtent: cell + 10 + 42 * textScale,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final a = albums[i];
              return AlbumCard(
                name: a.name,
                count: a.count,
                cover: a.cover,
                kind: a.kind,
                onTap: () => openCollection(
                  context,
                  title: a.name,
                  spec: MediaQuerySpec(albumId: a.id),
                  scope: 'album:${a.id}',
                ),
              );
            }, childCount: albums.length),
          );
        },
      ),
    );
  }
}

class _AlbumGridSkeleton extends StatelessWidget {
  const _AlbumGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final cols = _albumColumns(constraints.crossAxisExtent);
          final cell =
              (constraints.crossAxisExtent - Insets.lg * (cols - 1)) / cols;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: Insets.lg,
              mainAxisSpacing: Insets.xl,
              mainAxisExtent: cell + 52,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => SkeletonPulse(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: cell, height: cell, radius: Radii.lg),
                    const SizedBox(height: Insets.sm),
                    const SkeletonBox(width: 90, height: 14),
                    const SizedBox(height: 6),
                    const SkeletonBox(width: 40, height: 12),
                  ],
                ),
              ),
              childCount: 6,
            ),
          );
        },
      ),
    );
  }
}
