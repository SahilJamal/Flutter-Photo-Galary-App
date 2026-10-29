import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/sheets.dart';
import '../../shared/widgets/skeleton.dart';

final assetDetailsProvider = FutureProvider.autoDispose
    .family<AssetDetails, AssetEntity>(
      (ref, e) => ref.read(mediaServiceProvider).details(e),
    );

Future<void> showInfoSheet(BuildContext context, AssetEntity entity) =>
    showAppSheet(context, builder: (_) => InfoSheet(entity: entity));

/// Date, file, dimensions and location for one asset.
class InfoSheet extends ConsumerWidget {
  const InfoSheet({super.key, required this.entity});
  final AssetEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(assetDetailsProvider(entity));
    final c = context.colors;
    return AnimatedSize(
      duration: Motion.medium,
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: details.when(
        loading: () => const SkeletonPulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 220, height: 22),
              SizedBox(height: Insets.sm),
              SkeletonBox(width: 140, height: 14),
              SizedBox(height: Insets.xxl),
              SkeletonBox(height: 160, radius: Radii.lg),
            ],
          ),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.xxl),
          child: Text(
            "Details aren't available for this item.",
            style: context.text.bodyMedium,
          ),
        ),
        data: (d) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(Formatters.fullDate(d.date), style: context.text.titleLarge),
            const SizedBox(height: Insets.xxs),
            Text(Formatters.time(d.date), style: context.text.bodySmall),
            const SizedBox(height: Insets.xl),
            Container(
              decoration: BoxDecoration(
                color: c.surfaceMuted.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              padding: const EdgeInsets.symmetric(vertical: Insets.xs),
              child: Column(children: _rows(context, d)),
            ),
            const SizedBox(height: Insets.sm),
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(BuildContext context, AssetDetails d) {
    final mp = Formatters.megapixels(d.width, d.height);
    final type = _typeLabel(d);
    return [
      if (d.title.isNotEmpty)
        _InfoRow(
          icon: Icons.insert_drive_file_outlined,
          label: 'File',
          value: d.title,
        ),
      if (d.width > 0 && d.height > 0)
        _InfoRow(
          icon: Icons.aspect_ratio_rounded,
          label: 'Dimensions',
          value: '${d.width} × ${d.height}${mp.isEmpty ? '' : '  ·  $mp'}',
        ),
      if (d.duration != null)
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: 'Length',
          value: Formatters.duration(d.duration!),
        ),
      if (d.bytes != null)
        _InfoRow(
          icon: Icons.data_usage_rounded,
          label: 'Size',
          value: Formatters.bytes(d.bytes!),
        ),
      if (type != null)
        _InfoRow(icon: Icons.photo_outlined, label: 'Type', value: type),
      if (d.folder != null && d.folder!.isNotEmpty)
        _InfoRow(
          icon: Icons.folder_outlined,
          label: 'Folder',
          value: d.folder!,
        ),
      if (d.hasLocation)
        _InfoRow(
          icon: Icons.place_outlined,
          label: 'Location',
          value: Formatters.coordinate(d.latitude!, d.longitude!),
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: '${d.latitude}, ${d.longitude}'),
            );
            showToast(context, 'Coordinates copied');
          },
        )
      else
        const _InfoRow(
          icon: Icons.location_off_outlined,
          label: 'Location',
          value: 'Not recorded',
        ),
    ];
  }

  String? _typeLabel(AssetDetails d) {
    final mime = d.mimeType;
    if (mime != null && mime.contains('/')) {
      return mime.split('/').last.toUpperCase();
    }
    final dot = d.title.lastIndexOf('.');
    if (dot > 0) return d.title.substring(dot + 1).toUpperCase();
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: IconSizes.sm, color: c.textSecondary),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.bodySmall),
                    const SizedBox(height: 2),
                    Text(value, style: context.text.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.copy_rounded, size: 16, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
