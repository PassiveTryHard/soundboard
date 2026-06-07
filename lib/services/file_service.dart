import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  // Lets the user browse their device for an audio file
  // Returns the path to a permanent copy of the file, or null if cancelled
  Future<String?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        // Restricts the picker to audio files only
        type: FileType.audio,
        allowMultiple: false,
      );

      // User cancelled the picker
      if (result == null || result.files.isEmpty) return null;

      final pickedFile = result.files.first;
      if (pickedFile.path == null) return null;

      // Copy the file to the app's permanent storage so it's always available
      // even if the original file is moved or deleted by the user
      return await _copyToAppStorage(pickedFile.path!, pickedFile.name);
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  // Copies the picked file into the app's documents directory
  // This is a permanent location that persists between app sessions
  Future<String> _copyToAppStorage(String sourcePath, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();

    // Creates a subfolder called 'sounds' inside the app's documents directory
    final soundsDir = Directory('${appDir.path}/sounds');
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }

    // Destination path for the copied file
    final destPath = '${soundsDir.path}/$fileName';

    // Copy the file from wherever the user picked it to our app's storage
    await File(sourcePath).copy(destPath);

    return destPath;
  }

  // Deletes a sound file from app storage when a button is deleted
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}