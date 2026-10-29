import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

enum MediaType {
  all,
  image,
  video;

  RequestType get requestType => switch (this) {
    MediaType.all => RequestType.common,
    MediaType.image => RequestType.image,
    MediaType.video => RequestType.video,
  };
}

/// A value-type description of "which media to show". Every grid in the app
/// (library, album, search result, favourites, a year) is driven by one.
@immutable
class MediaQuerySpec {
  const MediaQuerySpec({
    this.albumId,
    this.type = MediaType.all,
    this.favoritesOnly = false,
    this.from,
    this.to,
    this.nameQuery,
  });

  static const library = MediaQuerySpec();

  /// `null` means the whole library ("Recents" / "All").
  final String? albumId;
  final MediaType type;
  final bool favoritesOnly;

  /// Inclusive start / exclusive end of a capture-date window.
  final DateTime? from;
  final DateTime? to;

  /// Case-insensitive file name fragment (Android only).
  final String? nameQuery;

  bool get hasName => nameQuery != null && nameQuery!.trim().isNotEmpty;
  bool get hasDate => from != null && to != null;

  MediaQuerySpec copyWith({
    String? albumId,
    MediaType? type,
    bool? favoritesOnly,
    DateTime? from,
    DateTime? to,
    String? nameQuery,
  }) => MediaQuerySpec(
    albumId: albumId ?? this.albumId,
    type: type ?? this.type,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    from: from ?? this.from,
    to: to ?? this.to,
    nameQuery: nameQuery ?? this.nameQuery,
  );

  @override
  bool operator ==(Object other) =>
      other is MediaQuerySpec &&
      other.albumId == albumId &&
      other.type == type &&
      other.favoritesOnly == favoritesOnly &&
      other.from == from &&
      other.to == to &&
      other.nameQuery == nameQuery;

  @override
  int get hashCode =>
      Object.hash(albumId, type, favoritesOnly, from, to, nameQuery);
}

/// A resolved, countable, rangeable list of assets.
abstract class MediaSource {
  Future<int> count();

  /// Assets in [start, end).
  Future<List<AssetEntity>> range(int start, int end);
}

enum AlbumKind { camera, screenshots, downloads, videos, favorites, other }

@immutable
class AlbumInfo {
  const AlbumInfo({
    required this.id,
    required this.name,
    required this.count,
    required this.kind,
    this.cover,
  });

  final String id;
  final String name;
  final int count;
  final AlbumKind kind;
  final AssetEntity? cover;
}

@immutable
class LibraryCounts {
  const LibraryCounts({required this.photos, required this.videos});
  final int photos;
  final int videos;
  int get total => photos + videos;
}

@immutable
class YearBucket {
  const YearBucket({required this.year, required this.count, this.cover});
  final int year;
  final int count;
  final AssetEntity? cover;
}

@immutable
class AssetDetails {
  const AssetDetails({
    required this.title,
    required this.date,
    required this.width,
    required this.height,
    this.bytes,
    this.mimeType,
    this.duration,
    this.folder,
    this.latitude,
    this.longitude,
  });

  final String title;
  final DateTime date;
  final int width;
  final int height;
  final int? bytes;
  final String? mimeType;
  final Duration? duration;
  final String? folder;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;
}
