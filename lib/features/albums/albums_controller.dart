import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../services/media_models.dart';
import '../../shared/providers.dart';
import '../../shared/state/favorites.dart';

final albumsProvider = FutureProvider<List<AlbumInfo>>((ref) {
  ref.watch(mediaRevisionProvider);
  return ref.read(mediaServiceProvider).albums();
});

@immutable
class MediaTypeSummary {
  const MediaTypeSummary({
    required this.videos,
    required this.favorites,
    this.videoCover,
    this.favoriteCover,
  });
  final int videos;
  final int favorites;
  final AssetEntity? videoCover;
  final AssetEntity? favoriteCover;
}

const videosSpec = MediaQuerySpec(type: MediaType.video);
const favoritesSpec = MediaQuerySpec(favoritesOnly: true);

final mediaTypesProvider = FutureProvider<MediaTypeSummary>((ref) async {
  ref.watch(mediaRevisionProvider);
  final local = ref.watch(favoritesProvider.select((s) => s.local));
  final media = ref.read(mediaServiceProvider);
  final videos = await media.sourceFor(videosSpec);
  final favs = await media.sourceFor(favoritesSpec, localFavorites: local);
  final counts = await Future.wait([videos.count(), favs.count()]);
  final covers = await Future.wait([videos.range(0, 1), favs.range(0, 1)]);
  return MediaTypeSummary(
    videos: counts[0],
    favorites: counts[1],
    videoCover: covers[0].firstOrNull,
    favoriteCover: covers[1].firstOrNull,
  );
});
