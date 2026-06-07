import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  String? _currentRecordingPath;

  // Initializes the recorder and requests microphone permission
  Future<bool> initialize() async {
    // Request microphone permission from the user
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false; // User denied permission
    }

    await _recorder.openRecorder();
    _isInitialized = true;
    return true;
  }

  // Starts recording to a temporary file
  Future<String?> startRecording() async {
    if (!_isInitialized) return null;

    // Save the recording to a temp file first
    final tempDir = await getTemporaryDirectory();
    _currentRecordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacADTS, // AAC is widely supported on Android and iOS
    );

    return _currentRecordingPath;
  }

  // Stops recording and returns the path to the recorded file
  Future<String?> stopRecording() async {
    if (!_isInitialized) return null;
    await _recorder.stopRecorder();
    return _currentRecordingPath;
  }

  // Copies the temp recording to permanent app storage
  Future<String> saveRecording(String tempPath, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${appDir.path}/sounds');

    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }

    final destPath = '${soundsDir.path}/$fileName.aac';
    await File(tempPath).copy(destPath);

    return destPath;
  }

  // Whether the recorder is currently recording
  bool get isRecording => _recorder.isRecording;

  // Cleans up the recorder when no longer needed
  Future<void> dispose() async {
    await _recorder.closeRecorder();
  }
}