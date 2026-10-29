import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../services/media_service.dart';
import '../providers.dart';
import 'favorites.dart';

@immutable
class PagedAssets {
  const PagedAssets({
    this.items = const [],
    this.total = 0,
    this.initialLoading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<AssetEntity> items;
  final int total;
  final bool initialLoading;
  final bool loadingMore;
  final Object? error;

  bool get hasMore => items.length < total;
  bool get isEmpty => !initialLoading && error == null && items.isEmpty;

  PagedAssets copyWith({
    List<AssetEntity>? items,
    int? total,
    bool? initialLoading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
  }) => PagedAssets(
    items: items ?? this.items,
    total: total ?? this.total,
    initialLoading: initialLoading ?? this.initialLoading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Paginated, refreshable asset list for any [MediaQuerySpec]. The viewer
/// reads the same instance as the grid it was opened from.
final pagedAssetsProvider = NotifierProvider.autoDispose
    .family<PagedAssetsController, PagedAssets, MediaQuerySpec>(
      PagedAssetsController.new,
    );

class PagedAssetsController
    extends AutoDisposeFamilyNotifier<PagedAssets, MediaQuerySpec> {
  static const pageSize = 120;

  MediaSource? _source;
  int _generation = 0;

  @override
  PagedAssets build(MediaQuerySpec arg) {
    ref.listen(mediaRevisionProvider, (_, _) => refresh());
    _generation++;
    _source = null;
    scheduleMicrotask(_loadFirstPage);
    return const PagedAssets();
  }

  MediaService get _media => ref.read(mediaServiceProvider);

  Future<MediaSource> _resolve() =>
      _media.sourceFor(arg, localFavorites: ref.read(favoritesProvider).local);

  Future<void> _loadFirstPage() async {
    final gen = _generation;
    try {
      final source = await _resolve();
      final total = await source.count();
      final items = await source.range(0, pageSize);
      if (gen != _generation) return;
      _source = source;
      state = PagedAssets(items: items, total: total, initialLoading: false);
    } catch (e) {
      if (gen != _generation) return;
      state = PagedAssets(initialLoading: false, error: e);
    }
  }

  Future<void> retry() async {
    _generation++;
    state = const PagedAssets();
    await _loadFirstPage();
  }

  Future<void> loadMore() async {
    final source = _source;
    if (source == null ||
        state.loadingMore ||
        !state.hasMore ||
        state.error != null) {
      return;
    }
    final gen = _generation;
    state = state.copyWith(loadingMore: true);
    try {
      final start = state.items.length;
      final next = await source.range(start, start + pageSize);
      if (gen != _generation) return;
      state = state.copyWith(
        items: [...state.items, ...next],
        loadingMore: false,
        // An empty page means the library shrank under us; stop paging.
        total: next.isEmpty ? state.items.length : null,
      );
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  /// Loads everything (used by "Select all").
  Future<List<AssetEntity>> loadAll() async {
    while (state.hasMore && state.error == null) {
      final before = state.items.length;
      await loadMore();
      if (state.items.length == before) break;
    }
    return state.items;
  }

  /// Re-queries in place, keeping as many items as are currently loaded so
  /// scroll position and open viewers stay stable.
  Future<void> refresh() async {
    final gen = ++_generation;
    try {
      final source = await _resolve();
      final total = await source.count();
      final keep = state.items.length.clamp(
        pageSize,
        total < pageSize ? pageSize : total,
      );
      final items = await source.range(0, keep);
      if (gen != _generation) return;
      _source = source;
      state = PagedAssets(items: items, total: total, initialLoading: false);
    } catch (e) {
      if (gen != _generation) return;
      if (state.items.isEmpty) {
        state = PagedAssets(initialLoading: false, error: e);
      }
    }
  }

  /// Optimistically drops deleted items before the re-query lands.
  void removeIds(Set<String> ids) {
    final items = state.items.where((e) => !ids.contains(e.id)).toList();
    final removed = state.items.length - items.length;
    state = state.copyWith(
      items: items,
      total: (state.total - removed).clamp(0, 1 << 31),
    );
  }
}
