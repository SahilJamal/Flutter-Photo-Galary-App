import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'device_service.dart';
import 'media_models.dart';

export 'media_models.dart';

/// The only place that talks to the photo library. Screens and controllers go
/// through this service, so platform quirks live in one file.
class MediaService {
  MediaService(this._device);

  final DeviceService _device;

  static const _channel = MethodChannel('photo_gallery/media');

  static const permissionOption = PermissionRequestOption(
    iosAccessLevel: IosAccessLevel.readWrite,
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: true,
    ),
  );

  /// Capture time in ms, falling back to when the file was added.
  static const _androidTakenAt = 'COALESCE(datetaken, date_added * 1000)';

  static final _defaultFilter = FilterOptionGroup(
    orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)],
  );

  // ---------------------------------------------------------------------------
  // Permissions

  Future<PermissionState> permissionState() =>
      PhotoManager.getPermissionState(requestOption: permissionOption);

  Future<PermissionState> requestPermission() =>
      PhotoManager.requestPermissionExtend(requestOption: permissionOption);

  /// Whether the OS will no longer show the permission dialog.
  Future<bool> osReportsPermanentlyDenied() async {
    try {
      final permission =
          _device.isAndroid && !_device.usesGranularMediaPermissions
          ? Permission.storage
          : Permission.photos;
      return await permission.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// iOS limited-library picker / Android 14+ "select more photos" picker.
  Future<void> presentLimitedPicker() => PhotoManager.presentLimited();

  Future<void> openSystemSettings() => PhotoManager.openSetting();

  // ---------------------------------------------------------------------------
  // Change notifications

  void Function(MethodCall)? _changeCallback;

  void startWatching(void Function() onChange) {
    stopWatching();
    _changeCallback = (_) => onChange();
    PhotoManager.addChangeCallback(_changeCallback!);
    PhotoManager.startChangeNotify();
  }

  void stopWatching() {
    final cb = _changeCallback;
    if (cb == null) return;
    PhotoManager.removeChangeCallback(cb);
    PhotoManager.stopChangeNotify();
    _changeCallback = null;
  }

  // ---------------------------------------------------------------------------
  // Queries

  /// Resolves a [MediaQuerySpec] to something that can be counted and paged.
  Future<MediaSource> sourceFor(
    MediaQuerySpec spec, {
    Set<String> localFavorites = const {},
  }) async {
    if (spec.favoritesOnly && !_device.supportsSystemFavorites) {
      return _IdSource(localFavorites.toList(), spec.type);
    }
    final filter = _filterFor(spec);
    final type = spec.type.requestType;
    if (spec.albumId == null) {
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: type,
        filterOption: filter,
      );
      return paths.isEmpty ? const _EmptySource() : _PathSource(paths.first);
    }
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      filterOption: filter,
    );
    for (final p in paths) {
      if (p.id == spec.albumId) return _PathSource(p);
    }
    return const _EmptySource();
  }

  Future<int> countFor(
    MediaQuerySpec spec, {
    Set<String> localFavorites = const {},
  }) async {
    final source = await sourceFor(spec, localFavorites: localFavorites);
    return source.count();
  }

  Future<LibraryCounts> libraryCounts() async {
    final results = await Future.wait([
      PhotoManager.getAssetCount(type: RequestType.image),
      PhotoManager.getAssetCount(type: RequestType.video),
    ]);
    return LibraryCounts(photos: results[0], videos: results[1]);
  }

  /// Every non-empty album with its cover and count, special albums first.
  Future<List<AlbumInfo>> albums() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterFor(MediaQuerySpec.library),
    );
    final infos = await Future.wait(
      paths.where((p) => !p.isAll).map((p) async {
        final count = await p.assetCountAsync;
        if (count == 0) return null;
        final cover = await p.getAssetListRange(start: 0, end: 1);
        return AlbumInfo(
          id: p.id,
          name: p.name.isEmpty ? 'Untitled' : p.name,
          count: count,
          kind: classify(p.name),
          cover: cover.isEmpty ? null : cover.first,
        );
      }),
    );
    final list = infos.whereType<AlbumInfo>().toList();
    list.sort((a, b) {
      final ka = _kindOrder(a.kind), kb = _kindOrder(b.kind);
      if (ka != kb) return ka.compareTo(kb);
      return b.count.compareTo(a.count);
    });
    return list;
  }

  static AlbumKind classify(String name) {
    final n = name.toLowerCase();
    if (n == 'camera' || n == 'dcim' || n.contains('camera roll')) {
      return AlbumKind.camera;
    }
    if (n.contains('screenshot')) return AlbumKind.screenshots;
    if (n.contains('download')) return AlbumKind.downloads;
    if (n == 'videos' || n == 'movies') return AlbumKind.videos;
    if (n.contains('favorite') || n.contains('favourite')) {
      return AlbumKind.favorites;
    }
    return AlbumKind.other;
  }

  static int _kindOrder(AlbumKind k) => switch (k) {
    AlbumKind.camera => 0,
    AlbumKind.screenshots => 1,
    AlbumKind.downloads => 2,
    AlbumKind.videos => 3,
    AlbumKind.favorites => 4,
    AlbumKind.other => 5,
  };

  /// Years that contain media, newest first, each with a count and cover.
  Future<List<YearBucket>> years() async {
    final all = await sourceFor(MediaQuerySpec.library);
    final total = await all.count();
    if (total == 0) return const [];
    final newest = (await all.range(0, 1)).firstOrNull;
    final oldest = (await all.range(total - 1, total)).firstOrNull;
    if (newest == null || oldest == null) return const [];
    final hi = newest.createDateTime.year;
    final lo = oldest.createDateTime.year;
    final buckets = <YearBucket>[];
    for (var y = hi; y >= lo && hi - y < 60; y--) {
      final source = await sourceFor(
        MediaQuerySpec(from: DateTime(y), to: DateTime(y + 1)),
      );
      final count = await source.count();
      if (count == 0) continue;
      final cover = await source.range(0, 1);
      buckets.add(YearBucket(year: y, count: count, cover: cover.firstOrNull));
    }
    return buckets;
  }

  // ---------------------------------------------------------------------------
  // Mutations

  /// Deletes through the platform. Android 11+ and iOS show their own system
  /// confirmation; returns the ids that were actually removed.
  Future<List<String>> delete(List<AssetEntity> assets) async {
    if (assets.isEmpty) return const [];
    return PhotoManager.editor.deleteWithIds(assets.map((e) => e.id).toList());
  }

  /// Sets the system favourite flag. Returns false if the user declined or the
  /// platform doesn't support it.
  Future<bool> setSystemFavorite(
    List<AssetEntity> assets,
    bool favorite,
  ) async {
    if (assets.isEmpty) return true;
    if (_device.isAndroid) {
      if (_device.androidSdk < 30) return false;
      // One MediaStore.createFavoriteRequest for the whole batch, so the user
      // confirms once instead of once per item.
      final ok = await _channel.invokeMethod<bool>('setFavorite', {
        'favorite': favorite,
        'items': [
          for (final a in assets)
            {'id': a.id, 'video': a.type == AssetType.video},
        ],
      });
      return ok ?? false;
    }
    if (_device.isIOS) {
      try {
        for (final a in assets) {
          await PhotoManager.editor.darwin.favoriteAsset(
            entity: a,
            favorite: favorite,
          );
        }
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Files and metadata

  Future<File?> fileFor(AssetEntity asset) => asset.file;

  Future<AssetDetails> details(AssetEntity asset) async {
    final title = await asset.titleAsync.catchError((_) => '');
    int? bytes;
    String? folder;
    try {
      final file = await asset.file;
      if (file != null) {
        bytes = await file.length();
        folder = file.parent.path.split(Platform.pathSeparator).lastOrNull;
      }
    } catch (_) {}
    if (_device.isAndroid && asset.relativePath != null) {
      final parts = asset.relativePath!.split('/').where((s) => s.isNotEmpty);
      if (parts.isNotEmpty) folder = parts.last;
    }
    double? lat = asset.latitude, lng = asset.longitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      try {
        final ll = await asset.latlngAsync();
        lat = ll?.latitude;
        lng = ll?.longitude;
      } catch (_) {}
    }
    final hasLocation = lat != null && lng != null && !(lat == 0 && lng == 0);
    return AssetDetails(
      title: title.isEmpty ? (asset.title ?? '') : title,
      date: asset.createDateTime,
      width: asset.orientatedWidth,
      height: asset.orientatedHeight,
      bytes: bytes,
      mimeType: asset.mimeType,
      duration: asset.type == AssetType.video ? asset.videoDuration : null,
      folder: folder,
      latitude: hasLocation ? lat : null,
      longitude: hasLocation ? lng : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Filters

  PMFilter _filterFor(MediaQuerySpec spec) {
    final conditions = <String>[];
    if (Platform.isIOS || Platform.isMacOS) {
      if (spec.favoritesOnly) conditions.add('favorite == 1');
      if (spec.hasDate) {
        final u = CustomColumns.utils;
        conditions.add('creationDate >= ${u.convertDateTimeToSql(spec.from!)}');
        conditions.add('creationDate < ${u.convertDateTimeToSql(spec.to!)}');
      }
      // PhotoKit predicates can't match file names; name search is Android-only.
      if (conditions.isEmpty) return _defaultFilter;
      return CustomFilter.sql(
        where: conditions.join(' AND '),
        orderBy: [const OrderByItem.desc('creationDate')],
      );
    }

    if (spec.favoritesOnly) conditions.add('is_favorite = 1');
    if (spec.hasDate) {
      conditions.add(
        '$_androidTakenAt >= ${spec.from!.millisecondsSinceEpoch}',
      );
      conditions.add('$_androidTakenAt < ${spec.to!.millisecondsSinceEpoch}');
    }
    if (spec.hasName) {
      final escaped = spec.nameQuery!
          .trim()
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll("'", "''");
      conditions.add("_display_name LIKE '%$escaped%' ESCAPE '\\'");
    }
    // Always use a custom filter on Android: the stock filter orders by
    // DATE_ADDED (when the file arrived), but people expect capture order.
    // A custom where-clause replaces photo_manager's own media-type clause, so
    // restate it here.
    conditions.insert(0, switch (spec.type) {
      MediaType.all => 'media_type IN (1, 3)',
      MediaType.image => 'media_type = 1',
      MediaType.video => 'media_type = 3',
    });
    return CustomFilter.sql(
      where: conditions.join(' AND '),
      orderBy: [const OrderByItem.desc(_androidTakenAt)],
    );
  }
}

class _PathSource implements MediaSource {
  _PathSource(this.path);
  final AssetPathEntity path;

  @override
  Future<int> count() => path.assetCountAsync;

  @override
  Future<List<AssetEntity>> range(int start, int end) =>
      path.getAssetListRange(start: start, end: end);
}

class _EmptySource implements MediaSource {
  const _EmptySource();

  @override
  Future<int> count() async => 0;

  @override
  Future<List<AssetEntity>> range(int start, int end) async => const [];
}

/// Favourites stored by the app (Android 10 and below): resolve ids lazily,
/// dropping anything that no longer exists.
class _IdSource implements MediaSource {
  _IdSource(this._ids, this._type);
  final List<String> _ids;
  final MediaType _type;
  List<AssetEntity>? _resolved;

  Future<List<AssetEntity>> _all() async {
    if (_resolved != null) return _resolved!;
    final entities = await Future.wait(_ids.map(AssetEntity.fromId));
    final list = entities.whereType<AssetEntity>().where((e) {
      return switch (_type) {
        MediaType.all => true,
        MediaType.image => e.type == AssetType.image,
        MediaType.video => e.type == AssetType.video,
      };
    }).toList()..sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return _resolved = list;
  }

  @override
  Future<int> count() async => (await _all()).length;

  @override
  Future<List<AssetEntity>> range(int start, int end) async {
    final all = await _all();
    if (start >= all.length) return const [];
    return all.sublist(start, end.clamp(start, all.length));
  }
}
