import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../shared/providers.dart';

enum AccessLevel { full, limited, denied }

@immutable
class AccessState {
  const AccessState(this.level, {this.permanentlyDenied = false});

  final AccessLevel level;

  /// The OS won't show the prompt again; only Settings can grant access.
  final bool permanentlyDenied;

  bool get granted => level != AccessLevel.denied;
}

final accessProvider = AsyncNotifierProvider<AccessController, AccessState>(
  AccessController.new,
);

class AccessController extends AsyncNotifier<AccessState> {
  @override
  Future<AccessState> build() => _read();

  Future<AccessState> _read() async {
    final media = ref.read(mediaServiceProvider);
    final state = await media.permissionState();
    return _map(state, await _permanentlyDenied(state));
  }

  AccessState _map(PermissionState s, bool permanent) => switch (s) {
    PermissionState.authorized => const AccessState(AccessLevel.full),
    PermissionState.limited => const AccessState(AccessLevel.limited),
    _ => AccessState(AccessLevel.denied, permanentlyDenied: permanent),
  };

  Future<bool> _permanentlyDenied(PermissionState s) async {
    if (s == PermissionState.authorized || s == PermissionState.limited) {
      return false;
    }
    final device = ref.read(deviceServiceProvider);
    final denials = ref.read(preferencesProvider).permissionDenials;
    // iOS never re-prompts after one denial; Android stops after two.
    if (device.isIOS) return denials >= 1 || s == PermissionState.restricted;
    if (denials >= 2) return true;
    return ref.read(mediaServiceProvider).osReportsPermanentlyDenied();
  }

  /// Shows the system prompt (only ever called from an explained screen).
  Future<AccessState> request() async {
    final prefs = ref.read(preferencesProvider);
    final result = await ref.read(mediaServiceProvider).requestPermission();
    if (result.hasAccess) {
      prefs.permissionDenials = 0;
    } else {
      prefs.permissionDenials = prefs.permissionDenials + 1;
    }
    final next = _map(result, await _permanentlyDenied(result));
    state = AsyncData(next);
    if (next.granted) ref.read(mediaRevisionProvider.notifier).bump();
    return next;
  }

  /// Re-reads the current state silently (e.g. returning from Settings).
  Future<void> recheck() async {
    final previous = state.valueOrNull;
    final next = await _read();
    if (previous == null ||
        previous.level != next.level ||
        previous.permanentlyDenied != next.permanentlyDenied) {
      if (next.granted) ref.read(preferencesProvider).permissionDenials = 0;
      state = AsyncData(next);
    }
  }
}
