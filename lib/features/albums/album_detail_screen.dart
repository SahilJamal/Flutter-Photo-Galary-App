import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/state/paged_assets.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/message_view.dart';
import '../gallery/media_collection_view.dart';
import '../settings/settings_controller.dart';

/// Pushes a full-screen grid for any collection (album, favourites, a year).
void openCollection(
  BuildContext context, {
  required String title,
  required MediaQuerySpec spec,
  required String scope,
  DateGrouping? grouping,
  IconData emptyIcon = Icons.photo_outlined,
  String emptyTitle = 'Nothing here yet',
  String emptyMessage =
      'Photos and videos added here will show up automatically.',
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CollectionScreen(
        title: title,
        spec: spec,
        scope: scope,
        grouping: grouping,
        empty: MessageView(
          icon: emptyIcon,
          title: emptyTitle,
          message: emptyMessage,
        ),
      ),
    ),
  );
}

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({
    super.key,
    required this.title,
    required this.spec,
    required this.scope,
    required this.empty,
    this.grouping,
  });

  final String title;
  final MediaQuerySpec spec;
  final String scope;
  final Widget empty;
  final DateGrouping? grouping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paged = ref.watch(pagedAssetsProvider(spec));
    final count = paged.initialLoading ? null : paged.total;
    return Scaffold(
      body: MediaCollectionView(
        title: title,
        subtitle: Text(count == null ? ' ' : Formatters.plural(count, 'item')),
        spec: spec,
        scope: scope,
        groupingOverride: grouping,
        empty: empty,
        leading: AppIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: 'Back',
          size: 18,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
