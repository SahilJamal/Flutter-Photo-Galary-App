import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/buttons.dart';
import 'zoomable_photo.dart';

/// A video page: poster with hero, then inline playback with calm controls.
class VideoPage extends ConsumerStatefulWidget {
  const VideoPage({
    super.key,
    required this.entity,
    required this.heroTag,
    required this.thumbPx,
    required this.active,
    required this.chromeVisible,
    required this.bottomInset,
    required this.onTap,
  });

  final AssetEntity entity;
  final Object heroTag;
  final int thumbPx;
  final bool active;
  final bool chromeVisible;
  final double bottomInset;
  final VoidCallback onTap;

  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load(autoplay: true);
  }

  @override
  void didUpdateWidget(covariant VideoPage old) {
    super.didUpdateWidget(old);
    if (old.active && !widget.active) _controller?.pause();
    if (!old.active && widget.active && _controller == null) {
      _load(autoplay: true);
    }
  }

  Future<void> _load({bool autoplay = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final file = await ref.read(mediaServiceProvider).fileFor(widget.entity);
      if (file == null) throw StateError('missing file');
      final c = VideoPlayerController.file(file);
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() => _controller = c);
      if (autoplay && widget.active) c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) {
      _load(autoplay: true);
      return;
    }
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        final fitted = fittedSize(widget.entity, box);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: SizedBox.fromSize(
                  size: fitted,
                  child: Hero(
                    tag: widget.heroTag,
                    flightShuttleBuilder: viewerHeroShuttle,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LayeredAssetImage(
                          entity: widget.entity,
                          thumbPx: widget.thumbPx,
                          logicalSize: fitted,
                        ),
                        if (c != null && c.value.isInitialized)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox.fromSize(
                              size: c.value.size,
                              child: VideoPlayer(c),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_failed)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(Insets.lg),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "This video can't be played.",
                          style: context.text.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        AppTextButton(
                          label: 'Try again',
                          color: Colors.white,
                          onPressed: _load,
                        ),
                      ],
                    ),
                  ),
                )
              else
                _CenterPlayButton(
                  controller: c,
                  loading: _loading,
                  visible: widget.chromeVisible,
                  onPressed: _togglePlay,
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: widget.bottomInset,
                child: IgnorePointer(
                  ignoring: !widget.chromeVisible,
                  child: AnimatedOpacity(
                    opacity: widget.chromeVisible && c != null ? 1 : 0,
                    duration: Motion.medium,
                    child: c == null
                        ? const SizedBox.shrink()
                        : _Scrubber(controller: c),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CenterPlayButton extends StatelessWidget {
  const _CenterPlayButton({
    required this.controller,
    required this.loading,
    required this.visible,
    required this.onPressed,
  });

  final VideoPlayerController? controller;
  final bool loading;
  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    Widget button(bool playing) => AnimatedOpacity(
      opacity: (visible || !playing) ? 1 : 0,
      duration: Motion.medium,
      child: IgnorePointer(
        ignoring: !(visible || !playing),
        child: Semantics(
          button: true,
          label: playing ? 'Pause' : 'Play',
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0x73000000),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
            ),
          ),
        ),
      ),
    );

    final c = controller;
    return Center(
      child: c == null
          ? button(false)
          : ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (context, v, _) => button(v.isPlaying),
            ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final style = context.text.labelSmall?.copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.lg),
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      decoration: BoxDecoration(
        color: const Color(0x8C000000),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, v, _) {
          final total = v.duration.inMilliseconds.toDouble();
          final pos = v.position.inMilliseconds.clamp(0, total).toDouble();
          return Row(
            children: [
              Text(Formatters.duration(v.position), style: style),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white12,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: total <= 0 ? 0 : pos,
                    max: total <= 0 ? 1 : total,
                    semanticFormatterCallback: (_) =>
                        '${Formatters.duration(v.position)} of ${Formatters.duration(v.duration)}',
                    onChanged: total <= 0
                        ? null
                        : (x) => controller.seekTo(
                            Duration(milliseconds: x.round()),
                          ),
                  ),
                ),
              ),
              Text(Formatters.duration(v.duration), style: style),
            ],
          );
        },
      ),
    );
  }
}
