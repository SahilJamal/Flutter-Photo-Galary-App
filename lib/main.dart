import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/device_service.dart';
import 'shared/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Grid thumbnails are small; a larger cache keeps fast scrolling smooth.
  PaintingBinding.instance.imageCache
    ..maximumSize = 600
    ..maximumSizeBytes = 160 << 20;

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    DeviceService.create(),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          results[0] as SharedPreferences,
        ),
        deviceServiceProvider.overrideWithValue(results[1] as DeviceService),
      ],
      child: const PhotoGalleryApp(),
    ),
  );
}
