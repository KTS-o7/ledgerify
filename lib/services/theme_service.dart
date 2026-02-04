import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// App theme mode options
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Extension for display names
extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Convert to Flutter ThemeMode
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

/// Service for managing theme preferences.
///
/// Uses Hive for persistence and ValueNotifier for reactive updates.
///
/// **Lifecycle:** This service is an app-lifetime singleton created in `main()`
/// and should never be disposed. The ValueNotifier is kept alive for the
/// entire app session.
class ThemeService {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  static const String _dynamicColorKey = 'use_dynamic_color';

  late Box _settingsBox;

  /// Notifier for theme changes - listen to this in the UI
  final ValueNotifier<AppThemeMode> themeMode =
      ValueNotifier(AppThemeMode.system);

  /// Notifier for Material You / dynamic color preference (Android 12+)
  final ValueNotifier<bool> useDynamicColor = ValueNotifier(true);

  /// Initialize the service - must be called before use
  Future<void> init() async {
    _settingsBox = await Hive.openBox(_boxName);
    _loadThemePreference();
    _loadDynamicColorPreference();
  }

  /// Load saved theme preference from storage
  void _loadThemePreference() {
    final savedValue = _settingsBox.get(_themeKey, defaultValue: 'system');
    themeMode.value = _stringToThemeMode(savedValue);
  }

  void _loadDynamicColorPreference() {
    final savedValue = _settingsBox.get(_dynamicColorKey, defaultValue: true);
    useDynamicColor.value = savedValue == true;
  }

  /// Set and persist theme preference
  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode.value = mode;
    await _settingsBox.put(_themeKey, mode.name);
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    useDynamicColor.value = enabled;
    await _settingsBox.put(_dynamicColorKey, enabled);
  }

  /// Convert string to AppThemeMode
  AppThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  /// Get the current Flutter ThemeMode
  ThemeMode get currentThemeMode => themeMode.value.themeMode;
}
