import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/sheets.dart';

/// Opens the sheet that lets a limited-access user add photos or upgrade.
Future<void> showManageAccessSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet(
    context,
    builder: (sheetContext) {
      final media = ref.read(mediaServiceProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Manage photo access', style: sheetContext.text.titleLarge),
          const SizedBox(height: Insets.sm),
          Text(
            'Photos can only see the items you chose. You can add more, or allow '
            'access to your whole library. Nothing ever leaves your device.',
            style: sheetContext.text.bodyMedium?.copyWith(
              color: sheetContext.colors.textSecondary,
            ),
          ),
          const SizedBox(height: Insets.xxl),
          AppButton(
            label: 'Select more photos',
            icon: Icons.add_photo_alternate_outlined,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await media.presentLimitedPicker();
              ref.read(mediaRevisionProvider.notifier).bump();
            },
          ),
          const SizedBox(height: Insets.sm),
          AppButton(
            label: 'Allow access to all photos',
            tone: ButtonTone.neutral,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              media.openSystemSettings();
            },
          ),
        ],
      );
    },
  );
}

/// Quiet card at the top of the library when access is limited.
class LimitedAccessBanner extends ConsumerWidget {
  const LimitedAccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        0,
        Insets.screen,
        Insets.lg,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.md,
          Insets.xs,
          Insets.md,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.divider, width: 0.6),
        ),
        child: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: c.accent,
              size: IconSizes.md,
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Showing selected photos',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "You've given access to some of your library.",
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            AppTextButton(
              label: 'Manage',
              color: c.accent,
              bold: true,
              onPressed: () => showManageAccessSheet(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
