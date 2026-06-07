import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  late SharedPreferences _prefs;

  // Must be called once at app startup before anything else reads settings
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Playback mode — defaults to simultaneous if never set before
  String getPlaybackMode() {
    return _prefs.getString(AppSettings.keyPlaybackMode) ??
        AppSettings.playbackSimultaneous;
  }

  Future<void> setPlaybackMode(String mode) async {
    await _prefs.setString(AppSettings.keyPlaybackMode, mode);
  }

  // Theme — defaults to dark if never set before
  String getTheme() {
    return _prefs.getString(AppSettings.keyTheme) ?? 'dark';
  }

  Future<void> setTheme(String theme) async {
    await _prefs.setString(AppSettings.keyTheme, theme);
  }

  // Cloud backup enabled — defaults to false if never set before
  bool getCloudBackupEnabled() {
    return _prefs.getBool(AppSettings.keyCloudBackupEnabled) ?? false;
  }

  Future<void> setCloudBackupEnabled(bool enabled) async {
    await _prefs.setBool(AppSettings.keyCloudBackupEnabled, enabled);
  }
}