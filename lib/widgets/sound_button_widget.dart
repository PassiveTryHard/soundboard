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
  bool _isPaused = false;
  double _progress = 0.0;

  // Handles tap behavior depending on whether edit mode is active
  Future<void> _handleTap(bool isEditMode) async {
    if (isEditMode) {
      showDialog(
        context: context,
        builder: (context) => EditButtonDialog(button: widget.button),
      );
      return;
    }

    final audioService = ref.read(audioServiceProvider);
    await audioService.playSound(widget.button.id, widget.button.audioFilePath);

    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _progress = 0.0;
    });

    final player = audioService.getPlayer(widget.button.id);

    // Single combined stream listener — waits for the player to be truly
    // ready before tracking position to fix the immediate progress bar bug
    player?.playerStateStream.listen((playerState) {
      if (playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        player.positionStream.listen((position) {
          final duration = player.duration;
          if (duration != null && duration.inMilliseconds > 0 && mounted) {
            setState(() {
              _progress = position.inMilliseconds / duration.inMilliseconds;
            });
          }
        });
      }

      // Reset visuals when the sound finishes naturally
      if (playerState.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
            _progress = 0.0;
          });
        }
      }
    });
  }

  // Toggles pause and resume for this specific button
  Future<void> _togglePause() async {
    final audioService = ref.read(audioServiceProvider);
    final player = audioService.getPlayer(widget.button.id);
    if (player == null) return;

    if (_isPaused) {
      // Resume playback from where it was paused
      await player.play();
      setState(() => _isPaused = false);
    } else {
      // Pause without losing position
      await player.pause();
      setState(() => _isPaused = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = ref.watch(editModeProvider);

    return GestureDetector(
      onTap: () => _handleTap(isEditMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Color(widget.button.color),
          borderRadius: BorderRadius.circular(12),
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
              // ── Progress Bar ───────────────────────────────────────
              // Thin strip at the very bottom of the button
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

              // ── Pause Strip ────────────────────────────────────────
              // Thin tappable strip just above the progress bar
              // Only visible while this button is playing
              if (_isPlaying && !isEditMode)
                Positioned(
                  bottom: 6, // Sits just above the progress bar
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    // Pause strip tap is separate from the main button tap
                    onTap: _togglePause,
                    // Absorbs the tap so it doesn't bubble up to the
                    // main GestureDetector and restart the sound
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 20,
                      color: Colors.black.withValues(alpha: 0.25),
                      child: Center(
                        child: Icon(
                          // Shows resume icon when paused, pause icon when playing
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Button Label ───────────────────────────────────────
              Center(
                child: Padding(
                  // Extra bottom padding when playing to make room
                  // for the pause strip without overlapping the label
                  padding: EdgeInsets.fromLTRB(
                      8, 8, 8, _isPlaying && !isEditMode ? 28 : 8),
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

              // ── Edit Mode Indicator ────────────────────────────────
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