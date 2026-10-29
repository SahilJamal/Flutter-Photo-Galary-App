import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Platform capabilities that change behaviour (favourites, search, copy).
class DeviceService {
  DeviceService._(this.androidSdk);

  /// Android API level, or 0 on other platforms.
  final int androidSdk;

  static Future<DeviceService> create() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return DeviceService._(info.version.sdkInt);
    }
    return DeviceService._(0);
  }

  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;

  /// MediaStore gained IS_FAVORITE in Android 11; iOS has PhotoKit favourites.
  bool get supportsSystemFavorites => isIOS || androidSdk >= 30;

  /// File-name search uses MediaStore's DISPLAY_NAME, which PhotoKit can't query.
  bool get supportsNameSearch => isAndroid;

  /// Android 13+ splits storage access into READ_MEDIA_* permissions.
  bool get usesGranularMediaPermissions => isAndroid && androidSdk >= 33;
}
