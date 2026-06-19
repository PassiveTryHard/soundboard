// AppSettings is stored with shared_preferences (simple key-value)
// so it doesn't need Hive annotations — just plain Dart constants

class AppSettings {
  // Keys used to read/write each setting in shared_preferences
  static const String keyPlaybackMode = 'playback_mode';
  static const String keyCloudBackupEnabled = 'cloud_backup_enabled';
  static const String keyTheme = 'theme';

  // Key for solo mode — only one button plays at a time
  static const String keySoloMode = 'solo_mode';

  // Possible values for playback mode
  static const String playbackSimultaneous = 'simultaneous';
  static const String playbackExclusive = 'exclusive';
}