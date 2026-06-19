import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import 'audio_provider.dart';

// Holds all current app settings as a simple data class
class AppSettingsState {
  final String playbackMode;
  final String theme;
  final bool cloudBackupEnabled;

  // Solo mode — when true only one button can play at a time
  final bool soloMode;

  const AppSettingsState({
    this.playbackMode = AppSettings.playbackSimultaneous,
    this.theme = 'dark',
    this.cloudBackupEnabled = false,
    this.soloMode = false,
  });

  // Creates a copy with one or more fields changed
  // This is the standard Flutter pattern for updating immutable state
  AppSettingsState copyWith({
    String? playbackMode,
    String? theme,
    bool? cloudBackupEnabled,
    bool? soloMode,
  }) {
    return AppSettingsState(
      playbackMode: playbackMode ?? this.playbackMode,
      theme: theme ?? this.theme,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      soloMode: soloMode ?? this.soloMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettingsState> {
  SettingsNotifier(this._service, this._ref) : super(const AppSettingsState()) {
    _loadSettings();
  }

  final SettingsService _service;
  final Ref _ref; // Lets us access other providers from within this notifier

  // Loads all saved settings from shared_preferences on startup
  Future<void> _loadSettings() async {
    await _service.initialize();
    state = AppSettingsState(
      playbackMode: _service.getPlaybackMode(),
      theme: _service.getTheme(),
      cloudBackupEnabled: _service.getCloudBackupEnabled(),
      soloMode: _service.getSoloMode(),
    );

    // Sync the audio engine with the saved playback mode
    _syncAudioService();
  }

  // Updates playback mode and notifies the audio service immediately
  Future<void> setPlaybackMode(String mode) async {
    await _service.setPlaybackMode(mode);
    state = state.copyWith(playbackMode: mode);
    _syncAudioService();
  }

  Future<void> setTheme(String theme) async {
    await _service.setTheme(theme);
    state = state.copyWith(theme: theme);
  }

  Future<void> setCloudBackupEnabled(bool enabled) async {
    await _service.setCloudBackupEnabled(enabled);
    state = state.copyWith(cloudBackupEnabled: enabled);
  }

  // Updates solo mode and notifies the audio service immediately
  Future<void> setSoloMode(bool enabled) async {
    await _service.setSoloMode(enabled);
    state = state.copyWith(soloMode: enabled);
    _syncAudioService();
  }

  // Keeps the audio service in sync with the current playback mode setting
  void _syncAudioService() {
    final audioService = _ref.read(audioServiceProvider);
    audioService.setPlaybackMode(
      state.playbackMode == AppSettings.playbackSimultaneous,
    );
    // Pass solo mode to the audio service
    audioService.setSoloMode(state.soloMode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>(
  (ref) => SettingsNotifier(SettingsService(), ref),
);