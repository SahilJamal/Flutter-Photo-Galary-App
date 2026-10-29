import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/widgets/asset_thumbnail.dart';
import '../../shared/widgets/pressable.dart';

IconData? albumKindIcon(AlbumKind k) => switch (k) {
  AlbumKind.camera => Icons.photo_camera_outlined,
  AlbumKind.screenshots => Icons.screenshot_outlined,
  AlbumKind.downloads => Icons.download_rounded,
  AlbumKind.videos => Icons.videocam_outlined,
  AlbumKind.favorites => Icons.favorite_border_rounded,
  AlbumKind.other => null,
};

/// Large square cover with the album name and count beneath.
class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.name,
    required this.count,
    required this.onTap,
    this.cover,
    this.kind = AlbumKind.other,
  });

  final String name;
  final int count;
  final AssetEntity? cover;
  final AlbumKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = albumKindIcon(kind);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$name, ${Formatters.plural(count, 'item')}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final px = bucketPx(
                    constraints.maxWidth,
                    MediaQuery.devicePixelRatioOf(context),
                  );
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (cover != null)
                            FadeInAssetImage(
                              image: thumbnailProvider(cover!, px),
                            )
                          else
                            ColoredBox(
                              color: c.surfaceMuted,
                              child: Icon(
                                Icons.photo_outlined,
                                color: c.textTertiary,
                                size: 32,
                              ),
                            ),
                          if (icon != null)
                            Positioned(
                              left: Insets.sm,
                              top: Insets.sm,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
            const SizedBox(height: 1),
            Text(
              Formatters.count(count),
              maxLines: 1,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
