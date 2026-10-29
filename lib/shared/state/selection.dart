import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SelectionState {
  const SelectionState({this.active = false, this.ids = const {}});

  final bool active;
  final Set<String> ids;

  int get count => ids.length;
  bool contains(String id) => ids.contains(id);
}

/// Multi-select state, one per grid scope (e.g. `library`, `album:<id>`).
final selectionProvider = NotifierProvider.autoDispose
    .family<SelectionController, SelectionState, String>(
      SelectionController.new,
    );

class SelectionController
    extends AutoDisposeFamilyNotifier<SelectionState, String> {
  @override
  SelectionState build(String arg) => const SelectionState();

  void start(String id) => state = SelectionState(active: true, ids: {id});

  void toggle(String id) {
    final ids = {...state.ids};
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    state = SelectionState(active: true, ids: ids);
  }

  void selectAll(Iterable<String> ids) =>
      state = SelectionState(active: true, ids: ids.toSet());

  void clearSelection() => state = const SelectionState(active: true);

  void exit() => state = const SelectionState();
}
