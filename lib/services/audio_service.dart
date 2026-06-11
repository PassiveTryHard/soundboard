// dart:io for file handling
import 'dart:io';
import 'dart:async';

// Flutter foundation provides debugPrint for safe console logging
import 'package:flutter/foundation.dart';

// Flutter services for loading bundled asset files
import 'package:flutter/services.dart';

// just_audio is our audio playback engine
import 'package:just_audio/just_audio.dart';

// path_provider finds the correct temp directory on the device
import 'package:path_provider/path_provider.dart';

class AudioService {
  // A map of players — each sound button gets its own dedicated player
  // The key is the button's unique id, the value is its AudioPlayer
  final Map<String, AudioPlayer> _players = {};

  // When true, pressing a button while it's playing adds another instance
  // on top — the sound overlaps with itself
  // When false, pressing a button while it's playing restarts it from
  // the beginning instead of layering
  bool _isSimultaneous = true;

  // Called from the Settings screen when the user changes playback mode
  void setPlaybackMode(bool simultaneous) {
    _isSimultaneous = simultaneous;
  }

  // Main method called when a sound button is tapped
  Future<void> playSound(String buttonId, String filePath) async {
    if (_isSimultaneous) {
      // Simultaneous mode — create a brand new player every time so
      // multiple instances of the same sound can play on top of each other
      final player = AudioPlayer();
      await _loadAndPlay(player, filePath);

      // Store with a unique key so multiple instances don't overwrite each other
      final instanceKey = '$buttonId-${DateTime.now().millisecondsSinceEpoch}';
      _players[instanceKey] = player;

      // Automatically remove the player from the map when it finishes
      // to prevent memory from filling up with completed players
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _players.remove(instanceKey);
          player.dispose();
        }
      });
    } else {
      // Isolated mode — reuse the same player for this button so pressing
      // it again always restarts from the beginning
      if (!_players.containsKey(buttonId)) {
        _players[buttonId] = AudioPlayer();
      }
      final player = _players[buttonId]!;

      // Stop any current playback and restart from the beginning
      await player.stop();
      await _loadAndPlay(player, filePath);
    }

    // Notify any listeners that playback state changed
    _playbackStateController.add(null);
  }

  // Loads the audio file and starts playback — handles both bundled
  // assets and real files on the device storage
  Future<void> _loadAndPlay(AudioPlayer player, String filePath) async {
    try {
      if (filePath.startsWith('assets/')) {
        // Copy the bundled asset to a temp file so Android can read it
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
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  // Stops all currently playing sounds across all players
  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
    _playbackStateController.add(null);
  }

  // Returns true if any sound is currently playing
  // Used by the Stop All button to decide whether to show itself
  bool get isAnythingPlaying {
    return _players.values.any((player) => player.playing);
  }

  // A stream that notifies listeners whenever playback state changes
  // Used by the Stop All button to show/hide itself reactively
  final _playbackStateController = StreamController<void>.broadcast();
  Stream<void> get playbackStateStream => _playbackStateController.stream;

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
    _playbackStateController.close();
  }
}