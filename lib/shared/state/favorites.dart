import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../providers.dart';

@immutable
class FavoritesState {
  const FavoritesState({
    required this.system,
    this.local = const {},
    this.overrides = const {},
  });

  /// True when the OS owns favourites (iOS, Android 11+).
  final bool system;

  /// App-stored favourites (Android 10 and below).
  final Set<String> local;

  /// Optimistic values applied before the library re-query lands.
  final Map<String, bool> overrides;

  bool isFavorite(AssetEntity e) =>
      overrides[e.id] ?? (system ? e.isFavorite : local.contains(e.id));

  FavoritesState copyWith({Set<String>? local, Map<String, bool>? overrides}) =>
      FavoritesState(
        system: system,
        local: local ?? this.local,
        overrides: overrides ?? this.overrides,
      );
}

final favoritesProvider = NotifierProvider<FavoritesController, FavoritesState>(
  FavoritesController.new,
);

class FavoritesController extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => FavoritesState(
    system: ref.watch(deviceServiceProvider).supportsSystemFavorites,
    local: ref.watch(preferencesProvider).localFavorites,
  );

  /// Sets [favorite] on every asset. Returns false if the platform or user
  /// declined the change.
  Future<bool> setFavorite(List<AssetEntity> assets, bool favorite) async {
    if (assets.isEmpty) return true;
    if (state.system) {
      final ok = await ref
          .read(mediaServiceProvider)
          .setSystemFavorite(assets, favorite);
      if (!ok) return false;
      state = state.copyWith(
        overrides: {...state.overrides, for (final a in assets) a.id: favorite},
      );
    } else {
      final local = {...state.local};
      for (final a in assets) {
        favorite ? local.add(a.id) : local.remove(a.id);
      }
      ref.read(preferencesProvider).localFavorites = local;
      state = state.copyWith(local: local);
    }
    ref.read(mediaRevisionProvider.notifier).bump();
    return true;
  }
}
