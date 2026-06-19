import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recording_service.dart';

// Tracks the current state of the recorder
enum RecordingState {
  idle,       // Not recording
  recording,  // Currently recording
  stopped,    // Recording finished, ready to save or discard
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier() : super(RecordingState.idle);

  final RecordingService _service = RecordingService();
  String? _recordingPath; // Path to the most recent recording

  // Initializes the recorder and requests permission
  Future<bool> initialize() async {
    return await _service.initialize();
  }

  // Fetches available input devices from the recording service
  //Future<List<InputDevice>> getAvailableDevices() async {
  //  return await _service.getAvailableDevices();
  //}

  // Sets the active input device
  //Future<void> setInputDevice(InputDevice device) async {
  //  await _service.setInputDevice(device);
  //}

  // Starts a new recording
  Future<void> startRecording() async {
    _recordingPath = await _service.startRecording();
    state = RecordingState.recording;
  }

  // Stops the current recording
  Future<void> stopRecording() async {
    _recordingPath = await _service.stopRecording();
    state = RecordingState.stopped;
  }

  // Saves the recording to permanent storage with a given name
  Future<String?> saveRecording(String fileName) async {
    if (_recordingPath == null) return null;
    final savedPath = await _service.saveRecording(_recordingPath!, fileName);
    state = RecordingState.idle;
    return savedPath;
  }

  // Discards the current recording and resets state
  void discardRecording() {
    _recordingPath = null;
    state = RecordingState.idle;
  }

  // The path to the current recording for preview playback
  String? get recordingPath => _recordingPath;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

// The provider widgets use to access recording state and controls
final recordingProvider =
    StateNotifierProvider<RecordingNotifier, RecordingState>(
  (ref) => RecordingNotifier(),
);