import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';
import '../core/utils/haptics.dart';
import 'providers.dart';
import 'state/favorites.dart';
import 'widgets/sheets.dart';

/// Share / delete / favourite flows shared by the viewer and multi-select.
abstract final class MediaActions {
  static Future<void> share(
    BuildContext context,
    WidgetRef ref,
    List<AssetEntity> assets, {
    Rect? origin,
  }) async {
    if (assets.isEmpty) return;
    final media = ref.read(mediaServiceProvider);
    final files = await Future.wait(
      assets.map((a) async {
        final f = await media.fileFor(a);
        return f == null ? null : XFile(f.path, mimeType: a.mimeType);
      }),
    );
    final shareable = files.whereType<XFile>().toList();
    if (!context.mounted) return;
    if (shareable.isEmpty) {
      showToast(context, "These items couldn't be prepared for sharing.");
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: shareable, sharePositionOrigin: origin),
    );
  }

  /// Confirms, then deletes through the OS. Returns the ids actually removed.
  static Future<Set<String>> delete(
    BuildContext context,
    WidgetRef ref,
    List<AssetEntity> assets,
  ) async {
    if (assets.isEmpty) return const {};
    final n = assets.length;
    final what = n == 1
        ? (assets.first.type == AssetType.video ? 'this video' : 'this photo')
        : Formatters.plural(n, 'item');
    final message = Platform.isIOS
        ? 'It will move to Recently Deleted in the Photos app, where you can recover it for 30 days.'
        : 'This permanently removes ${n == 1 ? 'it' : 'them'} from this device. '
              'Android will ask you to confirm.';
    final ok = await showConfirmSheet(
      context,
      title: 'Delete $what?',
      message: message,
      confirmLabel: n == 1 ? 'Delete' : 'Delete $n items',
    );
    if (!ok || !context.mounted) return const {};
    try {
      final deleted = await ref.read(mediaServiceProvider).delete(assets);
      ref.read(mediaRevisionProvider.notifier).bump();
      if (context.mounted && deleted.isNotEmpty) {
        showToast(
          context,
          deleted.length == 1
              ? 'Deleted'
              : 'Deleted ${Formatters.count(deleted.length)} items',
        );
      }
      return deleted.toSet();
    } catch (_) {
      if (context.mounted) {
        showToast(context, "Couldn't delete. Please try again.");
      }
      return const {};
    }
  }

  static Future<void> setFavorite(
    BuildContext context,
    WidgetRef ref,
    List<AssetEntity> assets,
    bool favorite,
  ) async {
    if (assets.isEmpty) return;
    Haptics.light();
    final ok = await ref
        .read(favoritesProvider.notifier)
        .setFavorite(assets, favorite);
    if (!context.mounted) return;
    if (!ok) {
      showToast(context, 'Favourites were not changed.');
    } else if (assets.length > 1) {
      showToast(
        context,
        favorite
            ? 'Added ${Formatters.count(assets.length)} to Favourites'
            : 'Removed ${Formatters.count(assets.length)} from Favourites',
      );
    }
  }
}
