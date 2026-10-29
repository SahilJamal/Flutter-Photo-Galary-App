import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';

enum ButtonTone { primary, neutral, danger }

/// Full-width, pill-shaped call to action.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.primary,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonTone tone;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      ButtonTone.primary => (c.textPrimary, c.background),
      ButtonTone.neutral => (c.surfaceMuted, c.textPrimary),
      ButtonTone.danger => (c.danger, Colors.white),
    };
    final disabled = onPressed == null;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: IconSizes.sm, color: fg),
        if (busy || icon != null) const SizedBox(width: Insets.sm),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.labelLarge?.copyWith(color: fg),
          ),
        ),
      ],
    );
    return Pressable(
      onTap: disabled || busy ? null : onPressed,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: disabled ? 0.4 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xl,
            vertical: Insets.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          alignment: Alignment.center,
          child: ExcludeSemantics(child: content),
        ),
      ),
    );
  }
}

/// Quiet text button, used for secondary actions.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.bold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? context.colors.textPrimary,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: Insets.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        textStyle: context.text.labelLarge?.copyWith(
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// 44×44 icon button with a tooltip (which doubles as the accessibility label).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.filled = false,
    this.size = IconSizes.md,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size,
      color: color ?? c.textPrimary,
      style: IconButton.styleFrom(
        backgroundColor: filled ? c.surfaceMuted : null,
        minimumSize: const Size(44, 44),
        fixedSize: const Size(44, 44),
      ),
      icon: Icon(icon),
    );
  }
}
