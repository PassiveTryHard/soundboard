import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  // A map of players — each sound button gets its own dedicated player
  // The key is the button's unique id, the value is its AudioPlayer
  final Map<String, AudioPlayer> _players = {};

  // Playback mode — matches the two modes from our AppSettings model
  bool _isSimultaneous = true;

  // Called from the Settings screen when the user changes playback mode
  void setPlaybackMode(bool simultaneous) {
    _isSimultaneous = simultaneous;
  }

  // Main method called when a sound button is tapped
  Future<void> playSound(String buttonId, String filePath) async {
    // In exclusive mode, stop all currently playing sounds first
    if (!_isSimultaneous) {
      await stopAll();
    }

    // If this button doesn't have a player yet, create one for it
    if (!_players.containsKey(buttonId)) {
      _players[buttonId] = AudioPlayer();
    }

    final player = _players[buttonId]!;

    try {
      if (filePath.startsWith('assets/')) {
        // Copy the asset to a temp file so Android can read it reliably
        final byteData = await rootBundle.load(filePath);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_sound');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List());
        await player.setFilePath(tempFile.path);
      } else {
        await player.setFilePath(filePath); // Load from device storage
      }
      // Play from the beginning
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      // If the file can't be found or played, print the error
      // We'll add proper error handling UI in Phase 9
      print('Error playing sound: $e');
    }
  }

  // Stops a specific button's sound
  Future<void> stopSound(String buttonId) async {
    if (_players.containsKey(buttonId)) {
      await _players[buttonId]!.stop();
    }
  }

  // Stops all currently playing sounds
  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
  }

  // Checks if a specific button is currently playing
  bool isPlaying(String buttonId) {
    if (!_players.containsKey(buttonId)) return false;
    return _players[buttonId]!.playing;
  }

  // Returns the AudioPlayer for a given button so widgets can
  // listen to its state stream and react when playback finishes
  AudioPlayer? getPlayer(String buttonId) {
    return _players[buttonId];
  }

  // Cleans up all players when the service is no longer needed
  // Important for freeing up device memory and audio resources
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}