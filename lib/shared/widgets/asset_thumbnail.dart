import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Thumbnail provider with a stable cache key, so the viewer can show the
/// already-decoded grid thumbnail instantly during the hero flight.
ImageProvider thumbnailProvider(AssetEntity entity, int px) =>
    AssetEntityImageProvider(
      entity,
      isOriginal: false,
      thumbnailSize: ThumbnailSize.square(px),
      thumbnailFormat: ThumbnailFormat.jpeg,
    );

/// Rounds a decode size up to a 64px bucket so neighbouring layouts share
/// cache entries.
int bucketPx(double logicalSize, double dpr) {
  final px = (logicalSize * dpr).ceil();
  return ((px + 63) ~/ 64) * 64;
}

/// Image that fades in once decoded, over a skeleton-coloured placeholder.
class FadeInAssetImage extends StatelessWidget {
  const FadeInAssetImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.placeholderColor,
  });

  final ImageProvider image;
  final BoxFit fit;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: placeholderColor ?? c.skeleton,
      child: Image(
        image: image,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, sync) {
          if (sync) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: Motion.medium,
            curve: Motion.curve,
            child: child,
          );
        },
        errorBuilder: (context, _, _) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: c.textTertiary,
            size: IconSizes.md,
          ),
        ),
      ),
    );
  }
}
