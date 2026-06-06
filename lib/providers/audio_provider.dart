import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';

// Makes a single shared AudioService instance available to the entire app
// Any widget can call ref.read(audioServiceProvider) to access it
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();

  // Automatically cleans up the service when it's no longer needed
  ref.onDispose(() => service.dispose());

  return service;
});