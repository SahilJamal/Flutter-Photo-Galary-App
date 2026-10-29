import 'package:shared_preferences/shared_preferences.dart';

/// Typed access to persisted preferences. UI never touches keys directly.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _themeMode = 'theme_mode';
  static const _thumbSize = 'thumb_size';
  static const _density = 'grid_density';
  static const _grouping = 'date_grouping';
  static const _onboarded = 'onboarding_done';
  static const _recent = 'recent_searches';
  static const _localFavorites = 'local_favorites';
  static const _denials = 'permission_denials';

  String? get themeMode => _prefs.getString(_themeMode);
  set themeMode(String? v) => _setString(_themeMode, v);

  String? get thumbSize => _prefs.getString(_thumbSize);
  set thumbSize(String? v) => _setString(_thumbSize, v);

  String? get density => _prefs.getString(_density);
  set density(String? v) => _setString(_density, v);

  String? get grouping => _prefs.getString(_grouping);
  set grouping(String? v) => _setString(_grouping, v);

  bool get onboardingDone => _prefs.getBool(_onboarded) ?? false;
  set onboardingDone(bool v) => _prefs.setBool(_onboarded, v);

  List<String> get recentSearches => _prefs.getStringList(_recent) ?? const [];
  set recentSearches(List<String> v) => _prefs.setStringList(_recent, v);

  Set<String> get localFavorites =>
      (_prefs.getStringList(_localFavorites) ?? const []).toSet();
  set localFavorites(Set<String> v) =>
      _prefs.setStringList(_localFavorites, v.toList());

  int get permissionDenials => _prefs.getInt(_denials) ?? 0;
  set permissionDenials(int v) => _prefs.setInt(_denials, v);

  void _setString(String key, String? v) {
    if (v == null) {
      _prefs.remove(key);
    } else {
      _prefs.setString(key, v);
    }
  }
}
