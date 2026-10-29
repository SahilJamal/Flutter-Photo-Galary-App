import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/message_view.dart';
import '../permissions/access_controller.dart';
import '../permissions/limited_access_banner.dart';
import '../settings/settings_screen.dart';
import 'media_collection_view.dart';

const librarySelectionScope = 'library';

final libraryCountsProvider = FutureProvider<LibraryCounts>((ref) {
  ref.watch(mediaRevisionProvider);
  return ref.read(mediaServiceProvider).libraryCounts();
});

/// The Photos tab: every photo and video, newest first.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, required this.onSearch, this.controller});

  final VoidCallback onSearch;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(libraryCountsProvider).valueOrNull;
    final limited =
        ref.watch(accessProvider).valueOrNull?.level == AccessLevel.limited;

    String? subtitle;
    if (counts != null) {
      final parts = [
        if (counts.photos > 0 || counts.videos == 0)
          Formatters.plural(counts.photos, 'photo'),
        if (counts.videos > 0) Formatters.plural(counts.videos, 'video'),
      ];
      subtitle = parts.join('  ·  ');
    }

    return MediaCollectionView(
      title: 'Photos',
      controller: controller,
      subtitle: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(subtitle ?? ' ', key: ValueKey(subtitle)),
      ),
      spec: MediaQuerySpec.library,
      scope: librarySelectionScope,
      ownSelectionBar: false,
      actions: [
        AppIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          onPressed: onSearch,
        ),
        AppIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Settings',
          onPressed: () => openSettings(context),
        ),
        const SizedBox(width: 4),
      ],
      headerSlivers: [
        if (limited) const SliverToBoxAdapter(child: LimitedAccessBanner()),
      ],
      empty: limited
          ? MessageView(
              icon: Icons.add_photo_alternate_outlined,
              title: 'No photos selected',
              message: 'Choose the photos and videos you want to see here.',
              actionLabel: 'Select photos',
              onAction: () => showManageAccessSheet(context, ref),
            )
          : const MessageView(
              icon: Icons.photo_camera_outlined,
              title: 'No photos yet',
              message:
                  'Photos and videos you take or save on this device will appear here.',
            ),
    );
  }
}
