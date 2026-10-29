import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../services/media_models.dart';
import '../../shared/providers.dart';
import '../albums/albums_controller.dart';

enum SearchFilter {
  photos('Photos'),
  videos('Videos'),
  screenshots('Screenshots'),
  favorites('Favourites');

  const SearchFilter(this.label);
  final String label;
}

@immutable
class SearchState {
  const SearchState({this.query = '', this.filter});
  final String query;
  final SearchFilter? filter;

  bool get idle => query.trim().isEmpty && filter == null;
}

final searchProvider = NotifierProvider<MediaSearchController, SearchState>(
  MediaSearchController.new,
);

class MediaSearchController extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setQuery(String q) =>
      state = SearchState(query: q, filter: state.filter);

  void toggleFilter(SearchFilter f) => state = SearchState(
    query: state.query,
    filter: state.filter == f ? null : f,
  );
}

/// Persisted recent searches, newest first.
final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

class RecentSearches extends Notifier<List<String>> {
  static const _max = 8;

  @override
  List<String> build() => ref.watch(preferencesProvider).recentSearches;

  void add(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    final next = [
      t,
      ...state.where((s) => s.toLowerCase() != t.toLowerCase()),
    ].take(_max).toList();
    _save(next);
  }

  void remove(String q) => _save(state.where((s) => s != q).toList());

  void clear() => _save(const []);

  void _save(List<String> v) {
    ref.read(preferencesProvider).recentSearches = v;
    state = v;
  }
}

/// A date window understood from free text, e.g. "2023", "march",
/// "mar 2022", "today", "yesterday".
@immutable
class DateMatch {
  const DateMatch(this.from, this.to, this.label);
  final DateTime from;
  final DateTime to;
  final String label;
}

const _months = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

DateMatch? parseDateQuery(String raw, {DateTime? now}) {
  final q = raw.trim().toLowerCase();
  if (q.isEmpty) return null;
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  if (q == 'today') {
    return DateMatch(today, today.add(const Duration(days: 1)), 'Today');
  }
  if (q == 'yesterday') {
    final y = today.subtract(const Duration(days: 1));
    return DateMatch(y, today, 'Yesterday');
  }
  final yearOnly = RegExp(r'^(19|20)\d{2}$');
  if (yearOnly.hasMatch(q)) {
    final y = int.parse(q);
    return DateMatch(DateTime(y), DateTime(y + 1), q);
  }
  final m = RegExp(r'^([a-z]{3,9})\.?\s*((?:19|20)\d{2})?$').firstMatch(q);
  if (m == null) return null;
  final word = m.group(1)!;
  final idx = _months.indexWhere((name) => name.startsWith(word));
  if (idx < 0) return null;
  final month = idx + 1;
  var year = m.group(2) != null ? int.parse(m.group(2)!) : n.year;
  if (m.group(2) == null && month > n.month) year -= 1;
  final from = DateTime(year, month);
  return DateMatch(from, DateTime(year, month + 1), Formatters.month(from));
}

/// What the search tab should show for the current input.
@immutable
class SearchPlan {
  const SearchPlan({
    this.spec,
    this.date,
    this.albums = const [],
    this.nameSearch = false,
  });

  /// Media to list, or null when only album matches apply.
  final MediaQuerySpec? spec;
  final DateMatch? date;
  final List<AlbumInfo> albums;
  final bool nameSearch;
}

const _noResultsAlbum = '__none__';

final searchPlanProvider = Provider<SearchPlan?>((ref) {
  final s = ref.watch(searchProvider);
  if (s.idle) return null;
  final device = ref.watch(deviceServiceProvider);
  final albums = ref.watch(albumsProvider).valueOrNull ?? const <AlbumInfo>[];
  final q = s.query.trim();
  final date = parseDateQuery(q);

  final albumMatches = q.isEmpty
      ? const <AlbumInfo>[]
      : albums
            .where((a) => a.name.toLowerCase().contains(q.toLowerCase()))
            .toList();

  var spec = const MediaQuerySpec();
  switch (s.filter) {
    case SearchFilter.photos:
      spec = spec.copyWith(type: MediaType.image);
    case SearchFilter.videos:
      spec = spec.copyWith(type: MediaType.video);
    case SearchFilter.favorites:
      spec = spec.copyWith(favoritesOnly: true);
    case SearchFilter.screenshots:
      final shots = albums
          .where((a) => a.kind == AlbumKind.screenshots)
          .firstOrNull;
      spec = spec.copyWith(albumId: shots?.id ?? _noResultsAlbum);
    case null:
      break;
  }

  var nameSearch = false;
  if (date != null) {
    spec = spec.copyWith(from: date.from, to: date.to);
  } else if (q.isNotEmpty) {
    if (!device.supportsNameSearch) {
      return SearchPlan(albums: albumMatches);
    }
    spec = spec.copyWith(nameQuery: q);
    nameSearch = true;
  }
  return SearchPlan(
    spec: spec,
    date: date,
    albums: albumMatches,
    nameSearch: nameSearch,
  );
});

final yearsProvider = FutureProvider<List<YearBucket>>((ref) {
  ref.watch(mediaRevisionProvider);
  return ref.read(mediaServiceProvider).years();
});
