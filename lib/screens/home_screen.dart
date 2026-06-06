import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sound_button_widget.dart';
import '../models/sound_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder list — Phase 7 will replace this with real saved buttons
    final List<SoundButton> buttons = [
      SoundButton(
        id: 'test-1',
        label: 'Test Sound',
        // This path format tells just_audio to load from the app's bundled assets
        audioFilePath: 'assets/audio/test_sound.m4a',
        color: 0xFF6C63FF, // Our purple accent color as an integer
        createdAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundboard'),
        centerTitle: true,
        actions: [
          // Add button in the top right — wired up fully in Phase 5 and 6
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {}, // Placeholder for now
          ),
        ],
      ),
      body: buttons.isEmpty
          // Empty state — shown when the user has no sounds yet
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off_rounded, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'No sounds yet',
                    style: TextStyle(color: Colors.white38, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first sound',
                    style: TextStyle(color: Colors.white24, fontSize: 14),
                  ),
                ],
              ),
            )
          // Grid of sound buttons
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 buttons per row
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                return SoundButtonWidget(button: buttons[index]);
              },
            ),
    );
  }
}