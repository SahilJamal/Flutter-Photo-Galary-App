import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/device_service.dart';
import '../services/media_service.dart';
import '../services/preferences_service.dart';

/// Overridden in `main()` once the instance is loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Overridden in `main()` once the platform has been queried.
final deviceServiceProvider = Provider<DeviceService>(
  (_) => throw UnimplementedError('deviceServiceProvider must be overridden'),
);

final preferencesProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(ref.watch(sharedPreferencesProvider)),
);

final mediaServiceProvider = Provider<MediaService>(
  (ref) => MediaService(ref.watch(deviceServiceProvider)),
);

/// Bumped whenever the library may have changed (resume, system change
/// notification, delete, favourite). Anything that reads media watches it.
final mediaRevisionProvider = NotifierProvider<MediaRevision, int>(
  MediaRevision.new,
);

class MediaRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
