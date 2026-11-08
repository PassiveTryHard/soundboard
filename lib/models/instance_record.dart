// just_audio provides AudioPlayer, the object that actually plays one sound
import 'package:just_audio/just_audio.dart';

// One record per active sound instance. The ledger holds these.
// A record only DESCRIBES an instance. It never plays, pauses, or stops anything:
// the AudioService does the acting and then reports the result to the ledger.
class InstanceRecord {
  // The player behind this instance. We identify instances by this object.
  final AudioPlayer player;

  // Whether the service has paused this instance. 
  final bool isPaused;

  // 'const' lets Dart build the object at compile time when its inputs are constants
  const InstanceRecord({required this.player, this.isPaused = false});

  // Returns a NEW record with isPaused changed. The fields are 'final', so a record
  // can never be edited in place. "Changing" one means building a replacement,
  // which is also what lets Riverpod notice that something changed.
  InstanceRecord copyWith({bool? isPaused}) {
    return InstanceRecord(player: player, isPaused: isPaused ?? this.isPaused);
  }
}

// The three states the pause icon can show
enum PauseState {
  nonePaused, // show PAUSE icon
  allPaused, // show PLAY icon
  mixed, // show BOTH icons
}

// Works out the pause state from ANY list of records. 
PauseState pauseStateOf(List<InstanceRecord> records) {
  if (records.isEmpty) return PauseState.nonePaused; // nothing is shown anyway

  final pausedCount = records.where((r) => r.isPaused).length;

  if (pausedCount == 0) return PauseState.nonePaused;
  if (pausedCount == records.length) return PauseState.allPaused;
  return PauseState.mixed;
}