import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sound_button.dart';
import '../providers/audio_provider.dart';

class SoundButtonWidget extends ConsumerStatefulWidget {
  final SoundButton button;

  const SoundButtonWidget({super.key, required this.button});

  @override
  ConsumerState<SoundButtonWidget> createState() => _SoundButtonWidgetState();
}

class _SoundButtonWidgetState extends ConsumerState<SoundButtonWidget> {
  bool _isPlaying = false;

  // Tracks playback progress as a value between 0.0 and 1.0
  double _progress = 0.0;

  Future<void> _handleTap() async {
    final audioService = ref.read(audioServiceProvider);

    if (_isPlaying) {
      await audioService.stopSound(widget.button.id);
      setState(() {
        _isPlaying = false;
        _progress = 0.0; // Reset progress bar when stopped manually
      });
    } else {
      await audioService.playSound(widget.button.id, widget.button.audioFilePath);
      setState(() => _isPlaying = true);

      final player = audioService.getPlayer(widget.button.id);

      // Listen to the position stream to update the progress bar
      player?.positionStream.listen((position) {
        final duration = player.duration;
        if (duration != null && duration.inMilliseconds > 0 && mounted) {
          setState(() {
            // Divides current position by total duration to get 0.0 to 1.0
            _progress = position.inMilliseconds / duration.inMilliseconds;
          });
        }
      });

      // Listen for natural completion and reset the button
      player?.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _progress = 0.0; // Reset progress bar when sound finishes
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: () {
        // Button edit menu wired up in Phase 8
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Color(widget.button.color),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPlaying
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
          // ClipRRect ensures the progress bar respects the button's rounded corners
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Progress bar sits behind everything else in the stack
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    // Heights the bar to 6px at the bottom of the button
                    heightFactor: 0.08,
                    widthFactor: 1.0,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.black26,
                      // Uses a lighter version of the button color for the bar
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),

              // Button content sits on top of the progress bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isPlaying)
                        const Icon(
                          Icons.stop_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        widget.button.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
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