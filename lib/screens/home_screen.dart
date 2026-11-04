// Material package for UI components
import 'package:flutter/material.dart';

// Riverpod for watching providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Reorderable grid for drag-to-reorder functionality
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

// Our providers and widgets
import '../providers/sound_button_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/sound_button_widget.dart';
import '../widgets/add_button_dialog.dart';
import '../widgets/record_button_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Changed to StatefulWidget so we can listen to the audio service
// stream and rebuild when playback state changes
class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Tracks total active sound instances across all buttons
  // Driven by the audio service's counter via its stream
  int _activeInstanceCount = 0;

  @override
  void initState() {
    super.initState();
    // Listen to the audio service's instance count stream and rebuild
    // whenever any sound starts or stops anywhere in the app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = ref.read(audioServiceProvider);
      audioService.playbackStateStream.listen((count) {
        if (mounted) {
          setState(() => _activeInstanceCount = count);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watches the button list — rebuilds when buttons are added or removed
    final buttons = ref.watch(soundButtonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundboard'),
        centerTitle: true,
        actions: [
          // Edit mode toggle — pencil icon turns accent color when active
          Consumer(
            builder: (context, ref, _) {
              final isEditMode = ref.watch(editModeProvider);
              return IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: isEditMode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () {
                  ref.read(editModeProvider.notifier).state = !isEditMode;
                },
                tooltip: isEditMode ? 'Exit edit mode' : 'Edit mode',
              );
            },
          ),

          // Add button — opens bottom sheet with import or record options
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.audio_file_rounded),
                        title: const Text('Import audio file'),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => const AddButtonDialog(),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.mic_rounded),
                        title: const Text('Record new sound'),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => const RecordButtonDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // Stack lets us layer the Stop All button on top of the grid
      body: Stack(
        children: [
          // ── Sound Button Grid ──────────────────────────────────────
          buttons.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_off_rounded,
                          size: 64, color: Colors.white24),
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
              : ReorderableGridView.builder(
                  // Extra bottom padding so buttons aren't hidden behind
                  // the Stop All button when it's visible
                  padding: EdgeInsets.fromLTRB(
                  12, 12, 12, _activeInstanceCount > 0 ? 80 : 12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: buttons.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(soundButtonProvider.notifier)
                        .reorderButtons(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    return SoundButtonWidget(
                      key: ValueKey(buttons[index].id),
                      button: buttons[index],
                    );
                  },
                ),

          // ── Stop All Button ────────────────────────────────────────
          // AnimatedPositioned smoothly slides the button into view
          // from below whenever any sound starts playing
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            // Slides in from below when playing, hides below screen when not
            bottom: _activeInstanceCount > 0 ? 16 : -80,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  ref.read(audioServiceProvider).stopAll();
                  setState(() => _activeInstanceCount = 0);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    // Semi-transparent dark background — unintrusive but visible
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stop_rounded,
                        // Uses accent color so it's immediately recognizable
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Stop All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}