import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';
import 'buttons.dart';

/// Consistent modal sheet: rounded, drag handle, safe-area aware, scrollable.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 220),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Insets.screen,
          0,
          Insets.screen,
          Insets.lg,
        ),
        child: builder(context),
      ),
    ),
  );
}

/// Pick one value from a short list.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T) label,
  String? description,
}) {
  return showAppSheet<T>(
    context,
    builder: (context) {
      final c = context.colors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.text.titleLarge),
          if (description != null) ...[
            const SizedBox(height: Insets.xs),
            Text(description, style: context.text.bodySmall),
          ],
          const SizedBox(height: Insets.md),
          for (final v in values)
            Semantics(
              selected: v == selected,
              inMutuallyExclusiveGroup: true,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Insets.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                title: Text(label(v), style: context.text.bodyLarge),
                trailing: AnimatedOpacity(
                  opacity: v == selected ? 1 : 0,
                  duration: Motion.fast,
                  child: Icon(Icons.check_rounded, color: c.accent),
                ),
                onTap: () {
                  Haptics.tick();
                  Navigator.of(context).pop(v);
                },
              ),
            ),
        ],
      );
    },
  );
}

/// Confirmation sheet. Destructive actions use the danger tone.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.delete_outline_rounded,
  bool destructive = true,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (context) {
      final c = context.colors;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: destructive ? c.dangerSoft : c.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: destructive ? c.danger : c.textPrimary),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: Insets.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.xxl),
          AppButton(
            label: confirmLabel,
            tone: destructive ? ButtonTone.danger : ButtonTone.primary,
            onPressed: () {
              Haptics.medium();
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: Insets.sm),
          AppButton(
            label: 'Cancel',
            tone: ButtonTone.neutral,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}
