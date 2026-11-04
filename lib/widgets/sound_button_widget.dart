// dart:async provides StreamSubscription for managing and cancelling
// stream listeners — prevents memory leaks when players are removed
import 'dart:async';

// Material package for UI components
import 'package:flutter/material.dart';

// Services package for haptic feedback
import 'package:flutter/services.dart';

// Riverpod for accessing providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

// just_audio for AudioPlayer and ProcessingState
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
  // Tracks the number of active instances for this button
  int _instanceCount = 0;

  // Tracks whether all instances are currently paused
  bool _isPaused = false;

  // Stores progress values for each active player instance
  // Key is the player object itself, value is progress from 0.0 to 1.0
  final Map<AudioPlayer, double> _playerProgress = {};

  // Subscriptions for each player's streams — stored so we can
  // cancel them when a player is removed, preventing memory leaks
  final Map<AudioPlayer, StreamSubscription> _playerSubscriptions = {};

  // Updates the widget whenever a new sound instance starts
  void _onInstanceStarted(AudioPlayer player) {
    if (!mounted) return;
    setState(() {
      _instanceCount++;
      _playerProgress[player] = 0.0;
    });

    // Subscribe to this player's state stream to track progress
    // and detect when it finishes naturally
    final subscription = player.playerStateStream.listen((playerState) {
      if (!mounted) return;

      // Only start tracking position once the player is truly ready
      if (playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        player.positionStream.listen((position) {
          final duration = player.duration;
          if (duration != null && duration.inMilliseconds > 0 && mounted) {
            setState(() {
              _playerProgress[player] =
                  position.inMilliseconds / duration.inMilliseconds;
            });
          }
        });
      }

      // Clean up this player's tracking data when it completes
      if (playerState.processingState == ProcessingState.completed) {
        _onInstanceEnded(player);
      }
    });

    _playerSubscriptions[player] = subscription;
  }

  // Cleans up tracking data when a player instance ends
  void _onInstanceEnded(AudioPlayer player) {
    if (!mounted) return;
    setState(() {
      _instanceCount = (_instanceCount - 1).clamp(0, 999);
      _playerProgress.remove(player);
    });

    // Cancel and remove the subscription for this player
    _playerSubscriptions[player]?.cancel();
    _playerSubscriptions.remove(player);
  }

  // Handles tap behavior depending on whether edit mode is active
  Future<void> _handleTap(bool isEditMode) async {
    if (isEditMode) {
      showDialog(
        context: context,
        builder: (context) => EditButtonDialog(button: widget.button),
      );
      return;
    }

    // Subtle haptic tap feedback
    HapticFeedback.lightImpact();

    final audioService = ref.read(audioServiceProvider);
    await audioService.playSound(widget.button.id, widget.button.audioFilePath);

    // Get the newly created player and start tracking it
    final players = audioService.getPlayers(widget.button.id);
    if (players.isNotEmpty) {
      _onInstanceStarted(players.last);
    }
  }

  // Toggles pause/resume for all instances of this button
  Future<void> _togglePause() async {
    final audioService = ref.read(audioServiceProvider);
    if (_isPaused) {
      await audioService.resumeButton(widget.button.id);
      setState(() => _isPaused = false);
    } else {
      await audioService.pauseButton(widget.button.id);
      setState(() => _isPaused = true);
    }
  }

  // Removes the most recently started instance of this button's sound
  Future<void> _removeLatestInstance() async {
    final audioService = ref.read(audioServiceProvider);
    final players = audioService.getPlayers(widget.button.id);
    if (players.isEmpty) return;

    final latest = players.last;
    await audioService.removeLatestInstance(widget.button.id);
    _onInstanceEnded(latest);
  }

  @override
  void dispose() {
    // Cancel all active subscriptions to prevent memory leaks
    for (final sub in _playerSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = ref.watch(editModeProvider);
    final isActive = _instanceCount > 0 && !isEditMode;

    return GestureDetector(
      onTap: () => _handleTap(isEditMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Color(widget.button.color),
          borderRadius: BorderRadius.circular(12),
          // Glow effect scales with instance count — more instances
          // means a stronger glow, giving natural visual feedback
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Color(widget.button.color).withValues(
                      alpha: (0.3 * _instanceCount).clamp(0.0, 0.8),
                    ),
                    blurRadius: 8.0 + (4.0 * _instanceCount),
                    spreadRadius: 1.0 + (1.0 * _instanceCount),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // ── Stacked Progress Bars ──────────────────────────────
              // One semi-transparent bar per active instance, stacked
              // from bottom up. Each bar shows that instance's progress
              if (isActive)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _playerProgress.values.map((progress) {
                        return FractionallySizedBox(
                          widthFactor: 1.0,
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: progress,
                              // Semi-transparent white so bars are visible
                              // on any button color
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // ── Pause Strip ────────────────────────────────────────
              // Thin tappable strip just above the progress bars
              // Pauses or resumes all instances of this button at once
              if (isActive)
                Positioned(
                  bottom: (_playerProgress.length * 4.0) + 2,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _togglePause,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 20,
                      color: Colors.black.withValues(alpha: 0.25),
                      child: Center(
                        child: Icon(
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
                  padding: EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
                    // Extra bottom padding when active to make room
                    // for the pause strip and progress bars
                    isActive
                        ? 28.0 + (_playerProgress.length * 4.0)
                        : 8,
                  ),
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

              // ── Instance Counter Badge ─────────────────────────────
              // Shows the number of active instances in the top left
              // Tapping it removes the most recently started instance
              if (isActive && _instanceCount > 0)
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: _removeLatestInstance,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Minus icon signals tap-to-remove behavior
                          const Icon(
                            Icons.remove_rounded,
                            color: Colors.white70,
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_instanceCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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