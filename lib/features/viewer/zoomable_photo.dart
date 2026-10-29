import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../shared/widgets/asset_thumbnail.dart';

/// Size an asset occupies when contained in [box]; falls back to the box
/// itself when the platform reports no dimensions.
Size fittedSize(AssetEntity e, Size box) {
  final src = e.orientatedSize;
  if (src.width <= 0 || src.height <= 0) return box;
  return applyBoxFit(BoxFit.contain, src, box).destination;
}

/// Thumbnail request preserving aspect, capped at [maxEdge] pixels and never
/// larger than the original.
ImageProvider sizedProvider(
  AssetEntity e,
  Size logical,
  double dpr,
  int maxEdge,
) {
  final src = e.orientatedSize;
  var w = logical.width * dpr;
  var h = logical.height * dpr;
  if (src.width > 0 && src.height > 0) {
    final scale = math.min(1.0, math.min(src.width / w, src.height / h));
    w *= scale;
    h *= scale;
  }
  final longest = math.max(w, h);
  if (longest > maxEdge) {
    w *= maxEdge / longest;
    h *= maxEdge / longest;
  }
  return AssetEntityImageProvider(
    e,
    isOriginal: false,
    thumbnailSize: ThumbnailSize(
      math.max(1, w.round()),
      math.max(1, h.round()),
    ),
    thumbnailFormat: ThumbnailFormat.jpeg,
  );
}

/// Hero shuttle that rounds the corners back into the grid tile's shape.
Widget viewerHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final hero =
      (direction == HeroFlightDirection.push ? toContext : fromContext).widget
          as Hero;
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) => ClipRRect(
      borderRadius: BorderRadius.circular(10 * (1 - animation.value)),
      child: child,
    ),
    child: hero.child,
  );
}

/// Image layers: grid thumbnail (instant) → screen-sized → detail when zoomed.
/// The original is never decoded.
class LayeredAssetImage extends StatelessWidget {
  const LayeredAssetImage({
    super.key,
    required this.entity,
    required this.thumbPx,
    required this.logicalSize,
    this.detail = false,
  });

  final AssetEntity entity;
  final int thumbPx;
  final Size logicalSize;
  final bool detail;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget layer(ImageProvider p) => Image(
      image: p,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: child,
            ),
      errorBuilder: (context, _, _) => const SizedBox.shrink(),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: thumbnailProvider(entity, thumbPx),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) =>
              const ColoredBox(color: Color(0xFF202024)),
        ),
        layer(sizedProvider(entity, logicalSize, dpr, 2560)),
        if (detail) layer(sizedProvider(entity, logicalSize * 2.5, dpr, 4096)),
      ],
    );
  }
}

/// Pinch / double-tap zoomable photo page.
class ZoomablePhoto extends StatefulWidget {
  const ZoomablePhoto({
    super.key,
    required this.entity,
    required this.heroTag,
    required this.thumbPx,
    required this.onTap,
    required this.onZoomChanged,
  });

  final AssetEntity entity;
  final Object heroTag;
  final int thumbPx;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final _tc = TransformationController();
  late final AnimationController _anim;
  Animation<Matrix4>? _animation;
  Offset _tapPosition = Offset.zero;
  bool _zoomed = false;
  bool _detail = false;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          final a = _animation;
          if (a != null) _tc.value = a.value;
        });
    _tc.addListener(_onTransform);
  }

  void _onTransform() {
    final scale = _tc.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(zoomed);
    }
    if (scale > 1.8 && !_detail) setState(() => _detail = true);
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(
      begin: _tc.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  void _onDoubleTap() {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    const s = 2.6;
    final p = _tapPosition;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(-p.dx * (s - 1), -p.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1),
    );
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransform);
    _tc.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        final fitted = fittedSize(widget.entity, box);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTapDown: (d) => _tapPosition = d.localPosition,
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _tc,
            minScale: 1,
            maxScale: 6,
            clipBehavior: Clip.none,
            child: SizedBox.fromSize(
              size: box,
              child: Center(
                child: SizedBox.fromSize(
                  size: fitted,
                  child: Hero(
                    tag: widget.heroTag,
                    flightShuttleBuilder: viewerHeroShuttle,
                    child: LayeredAssetImage(
                      entity: widget.entity,
                      thumbPx: widget.thumbPx,
                      logicalSize: fitted,
                      detail: _detail,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
