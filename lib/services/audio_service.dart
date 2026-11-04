// dart:async for StreamController
import 'dart:async';

// dart:io for file handling
import 'dart:io';

// Flutter foundation for debugPrint
import 'package:flutter/foundation.dart';

// Flutter services for loading bundled asset files
import 'package:flutter/services.dart';

// just_audio is our audio playback engine
import 'package:just_audio/just_audio.dart';

// path_provider finds the correct temp directory on the device
import 'package:path_provider/path_provider.dart';

class AudioService {
  // Per-button Sets of active players — each button tracks its own
  // instances independently. Key is buttonId, value is the Set of
  // all currently active AudioPlayers for that button
  final Map<String, Set<AudioPlayer>> _buttonPlayers = {};

  // Global counter tracking total active sound instances across all buttons
  // When this reaches 0 the Stop All button hides itself
  int _activeInstanceCount = 0;

  // Stream that notifies the UI whenever the instance count changes
  // Used by HomeScreen to show/hide the Stop All button
  final _playbackStateController = StreamController<int>.broadcast();
  Stream<int> get playbackStateStream => _playbackStateController.stream;

  // Current value of the instance counter — used for initial UI state
  int get activeInstanceCount => _activeInstanceCount;

  // Whether any sound is currently playing across all buttons
  bool get isAnythingPlaying => _activeInstanceCount > 0;

  // Playback mode — simultaneous layers instances, exclusive restarts
  bool _isSimultaneous = true;

  // Solo mode — only one button can play at a time across the board
  bool _isSoloMode = false;

  void setPlaybackMode(bool simultaneous) {
    _isSimultaneous = simultaneous;
  }

  void setSoloMode(bool solo) {
    _isSoloMode = solo;
  }

  // Ensures a button's Set exists before we try to use it
  void _ensureSetExists(String buttonId) {
    _buttonPlayers.putIfAbsent(buttonId, () => {});
  }

  // Main method called when a sound button is tapped
  Future<void> playSound(String buttonId, String filePath) async {
    // Solo mode — stop all other buttons before playing
    if (_isSoloMode) {
      await stopAll();
    }

    _ensureSetExists(buttonId);

    if (_isSimultaneous) {
      // Simultaneous mode — create a new player instance every tap
      // so the sound layers on top of itself
      await _createAndPlay(buttonId, filePath);
    } else {
      // Exclusive mode — clear this button's existing instances first
      // then start fresh, effectively restarting from the beginning
      await _clearButtonInstances(buttonId);
      await _createAndPlay(buttonId, filePath);
    }
  }

  // Creates a new AudioPlayer, plays it, and manages its full lifecycle
  Future<void> _createAndPlay(String buttonId, String filePath) async {
    final player = AudioPlayer();

    // Add the player to this button's Set and increment the global counter
    _buttonPlayers[buttonId]!.add(player);
    _activeInstanceCount++;
    _playbackStateController.add(_activeInstanceCount);

    try {
      await _loadAndPlay(player, filePath);

      // Wait for the player to complete naturally
      await player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Playback error: $e');
    } finally {
      // Always runs regardless of how playback ended — success, error,
      // or manual stop. Removes this instance and decrements the counter
      _buttonPlayers[buttonId]?.remove(player);
      _activeInstanceCount = (_activeInstanceCount - 1).clamp(0, 999);
      _playbackStateController.add(_activeInstanceCount);
      await player.dispose();
    }
  }

  // Loads audio from either a bundled asset or device storage and plays it
  Future<void> _loadAndPlay(AudioPlayer player, String filePath) async {
    if (filePath.startsWith('assets/')) {
      // Copy bundled asset to a temp file so Android can read it reliably
      final byteData = await rootBundle.load(filePath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_sound');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      await player.setFilePath(tempFile.path);
    } else {
      await player.setFilePath(filePath);
    }
    await player.seek(Duration.zero);
    await player.play();
  }

  // Pauses all active instances for a specific button
  Future<void> pauseButton(String buttonId) async {
    final players = _buttonPlayers[buttonId];
    if (players == null || players.isEmpty) return;
    for (final player in players) {
      await player.pause();
    }
  }

  // Resumes all paused instances for a specific button
  Future<void> resumeButton(String buttonId) async {
    final players = _buttonPlayers[buttonId];
    if (players == null || players.isEmpty) return;
    for (final player in players) {
      await player.play();
    }
  }

  // Removes the most recently added instance for a specific button
  Future<void> removeLatestInstance(String buttonId) async {
    final players = _buttonPlayers[buttonId];
    if (players == null || players.isEmpty) return;

    // The last element in the Set is the most recently added instance
    final latest = players.last;
    await latest.stop();
    // Cleanup is handled automatically by the finally block in _createAndPlay
  }

  // Returns the number of active instances for a specific button
  int getInstanceCount(String buttonId) {
    return _buttonPlayers[buttonId]?.length ?? 0;
  }

  // Returns all active players for a button — used by the widget
  // to build one progress bar per active instance
  Set<AudioPlayer> getPlayers(String buttonId) {
    return _buttonPlayers[buttonId] ?? {};
  }

  // Clears all instances for a specific button
  Future<void> _clearButtonInstances(String buttonId) async {
    final players = _buttonPlayers[buttonId];
    if (players == null || players.isEmpty) return;
    for (final player in players.toList()) {
      await player.stop();
      // finally block in _createAndPlay handles removal and counter update
    }
  }

  // Stops all sounds across all buttons
  Future<void> stopAll() async {
    for (final buttonId in _buttonPlayers.keys) {
      await _clearButtonInstances(buttonId);
    }
  }

  // Cleans up everything when the service is no longer needed
  Future<void> dispose() async {
    await stopAll();
    _playbackStateController.close();
  }
}