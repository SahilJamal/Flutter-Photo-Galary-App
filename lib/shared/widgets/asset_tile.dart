import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import 'asset_thumbnail.dart';

/// One cell in a media grid: thumbnail, video/favourite badges, selection.
class AssetTile extends StatefulWidget {
  const AssetTile({
    super.key,
    required this.entity,
    required this.thumbPx,
    required this.radius,
    required this.heroTag,
    required this.selectionMode,
    required this.selected,
    required this.favorite,
    required this.onTap,
    required this.onLongPress,
  });

  final AssetEntity entity;
  final int thumbPx;
  final double radius;
  final Object heroTag;
  final bool selectionMode;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<AssetTile> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  String _semantics() {
    final e = widget.entity;
    final kind = e.type == AssetType.video
        ? 'Video, ${Formatters.duration(e.videoDuration)}'
        : 'Photo';
    final parts = [kind, Formatters.shortDate(e.createDateTime)];
    if (widget.favorite) parts.add('Favourite');
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = widget.entity;
    final isVideo = e.type == AssetType.video;
    final scale = widget.selected ? 0.88 : (_down ? 0.96 : 1.0);
    final radius = widget.selected ? widget.radius + 6 : widget.radius;

    return Semantics(
      button: true,
      selected: widget.selectionMode ? widget.selected : null,
      label: _semantics(),
      hint: widget.selectionMode
          ? 'Double tap to toggle selection'
          : 'Double tap to open',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: widget.onTap,
        onLongPress: () {
          _setDown(false);
          widget.onLongPress();
        },
        child: ColoredBox(
          color: widget.selected ? c.accentSoft : Colors.transparent,
          child: AnimatedScale(
            scale: scale,
            duration: Motion.medium,
            curve: Motion.curve,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: radius),
                  duration: Motion.medium,
                  curve: Motion.curve,
                  builder: (context, r, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(r),
                    child: child,
                  ),
                  child: Hero(
                    tag: widget.heroTag,
                    child: FadeInAssetImage(
                      image: thumbnailProvider(e, widget.thumbPx),
                    ),
                  ),
                ),
                if (isVideo || widget.favorite)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: _BottomBadges(
                        video: isVideo ? e.videoDuration : null,
                        favorite: widget.favorite,
                        radius: radius,
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: _SelectionMark(
                      visible: widget.selectionMode,
                      selected: widget.selected,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBadges extends StatelessWidget {
  const _BottomBadges({
    required this.video,
    required this.favorite,
    required this.radius,
  });
  final Duration? video;
  final bool favorite;
  final double radius;

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Color(0x66000000), blurRadius: 6)];
    final style = context.text.labelSmall?.copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: shadow,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x59000000)],
        ),
      ),
      child: Row(
        children: [
          if (favorite)
            const Icon(
              Icons.favorite_rounded,
              size: 13,
              color: Colors.white,
              shadows: shadow,
            ),
          const Spacer(),
          if (video != null) ...[
            const Icon(
              Icons.play_arrow_rounded,
              size: 14,
              color: Colors.white,
              shadows: shadow,
            ),
            const SizedBox(width: 1),
            Flexible(
              child: Text(
                Formatters.duration(video!),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textScaler: TextScaler.noScaling,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.visible, required this.selected});
  final bool visible;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: Motion.fast,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? c.accent : Colors.black.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white, width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
        ),
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: Motion.fast,
          curve: Curves.easeOutBack,
          child: Icon(Icons.check_rounded, size: 14, color: c.onAccent),
        ),
      ),
    );
  }
}
