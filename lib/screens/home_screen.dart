import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sound_button_provider.dart';
import '../widgets/sound_button_widget.dart';
import '../widgets/add_button_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the button list — rebuilds automatically when buttons are added/removed
    final buttons = ref.watch(soundButtonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              // Opens the Add Sound dialog
              showDialog(
                context: context,
                builder: (context) => const AddButtonDialog(),
              );
            },
          ),
        ],
      ),
      body: buttons.isEmpty
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
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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