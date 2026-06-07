import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sound_button.dart';

// Makes a single shared Uuid instance available
const _uuid = Uuid();

// The main provider for the list of sound buttons
// StateNotifier lets us modify the list and automatically notify
// any widgets that are watching it to rebuild
class SoundButtonNotifier extends StateNotifier<List<SoundButton>> {
  SoundButtonNotifier() : super([]) {
    _loadButtons(); // Load saved buttons when the app starts
  }

  // Reference to the Hive box where buttons are stored
  final Box<SoundButton> _box = Hive.box<SoundButton>('sound_buttons');

  // Loads all saved buttons from Hive on startup
  void _loadButtons() {
    state = _box.values.toList();
  }

  // Creates a new button and saves it to Hive
  Future<void> addButton({
    required String label,
    required String audioFilePath,
    required int color,
  }) async {
    final button = SoundButton(
      id: _uuid.v4(), // Generates a unique id like "a3f2c1d4-..."
      label: label,
      audioFilePath: audioFilePath,
      color: color,
      createdAt: DateTime.now(),
    );

    // Save to Hive using the button's id as the key
    await _box.put(button.id, button);

    // Update the state — this triggers any watching widgets to rebuild
    state = _box.values.toList();
  }

  // Deletes a button from Hive by its id
  Future<void> deleteButton(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }

  // Updates an existing button's properties
  Future<void> updateButton(SoundButton button) async {
    await _box.put(button.id, button);
    state = _box.values.toList();
  }
}

// The provider that widgets use to access the button list and its methods
final soundButtonProvider =
    StateNotifierProvider<SoundButtonNotifier, List<SoundButton>>(
  (ref) => SoundButtonNotifier(),
);