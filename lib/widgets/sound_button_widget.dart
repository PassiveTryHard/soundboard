// Material package for UI components
import 'package:flutter/material.dart';

// Riverpod for accessing providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

// just_audio for the ProcessingState enum
import 'package:just_audio/just_audio.dart';

// Our data model, providers and edit dialog
import '../models/sound_button.dart';
import '../providers/audio_provider.dart';
import '../providers/sound_button_provider.dart';
import 'edit_button_dialog.dart';

class SoundButtonWidget extends ConsumerStatefulWidget {
  final SoundButton button;

  const SoundButtonWidget({super.key, required this.button});

  @override
  ConsumerState<SoundButtonWidget> createState() => _SoundButtonWidgetState();
}

class _SoundButtonWidgetState extends ConsumerState<SoundButtonWidget> {
  bool _isPlaying = false;
  double _progress = 0.0;

  // Handles tap behavior depending on whether edit mode is active
  Future<void> _handleTap(bool isEditMode) async {
    if (isEditMode) {
      // In edit mode, tapping opens the edit dialog instead of playing
      showDialog(
        context: context,
        builder: (context) => EditButtonDialog(button: widget.button),
      );
      return;
    }

    // Normal mode — play the sound. In simultaneous mode this layers
    // a new instance on top. In isolated mode this restarts the sound
    final audioService = ref.read(audioServiceProvider);
    await audioService.playSound(widget.button.id, widget.button.audioFilePath);

    // Update playing state for visual feedback
    setState(() {
      _isPlaying = true;
      _progress = 0.0;
    });

    final player = audioService.getPlayer(widget.button.id);

    // Update the progress bar as the sound plays
    // Only relevant in isolated mode since simultaneous creates new players
    player?.positionStream.listen((position) {
      final duration = player.duration;
      if (duration != null && duration.inMilliseconds > 0 && mounted) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;
        });
      }
    });

    // Reset the button visuals when the sound finishes naturally
    player?.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _progress = 0.0;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch edit mode so the button rebuilds when it changes
    final isEditMode = ref.watch(editModeProvider);

    return GestureDetector(
      onTap: () => _handleTap(isEditMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Color(widget.button.color),
          borderRadius: BorderRadius.circular(12),
          // Glows when playing in normal mode
          boxShadow: _isPlaying && !isEditMode
              ? [
                  BoxShadow(
                    color: Color(widget.button.color).withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Progress bar at the bottom — only shown during playback
              // in isolated mode where we can track a single player
              if (_isPlaying && !isEditMode)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.08,
                      widthFactor: 1.0,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main button content — label only, no stop icon needed
              // since stopping is now handled by the Stop All button
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.button.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Edit mode indicator — small pencil icon in the top right corner
              if (isEditMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}