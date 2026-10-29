import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A soft opacity pulse shared by all placeholder shapes beneath it.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.55,
        end: 1,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.skeleton,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Grid placeholder shown while the first page loads.
class SkeletonGridSliver extends StatelessWidget {
  const SkeletonGridSliver({
    super.key,
    required this.columns,
    required this.gap,
    required this.radius,
    this.count = 24,
  });

  final int columns;
  final double gap;
  final double radius;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gap > 2 ? gap : 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => SkeletonPulse(child: SkeletonBox(radius: radius)),
          childCount: count,
        ),
      ),
    );
  }
}
