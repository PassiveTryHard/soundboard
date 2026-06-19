import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// flutter_sound provides InputDevice for microphone selection
//import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/recording_provider.dart';
import '../providers/sound_button_provider.dart';
import '../theme/app_theme.dart';

class RecordButtonDialog extends ConsumerStatefulWidget {
  const RecordButtonDialog({super.key});

  @override
  ConsumerState<RecordButtonDialog> createState() => _RecordButtonDialogState();
}

class _RecordButtonDialogState extends ConsumerState<RecordButtonDialog> {
  final _labelController = TextEditingController();
  Color _selectedColor = AppTheme.accentColor;
  bool _isPlaying = false;
  final AudioPlayer _previewPlayer = AudioPlayer(); // For previewing the recording

  @override
  void initState() {
    super.initState();
    // Initialize the recorder as soon as the dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted =
          await ref.read(recordingProvider.notifier).initialize();
      if (!granted && mounted) {
        // If permission was denied, close the dialog and show a message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is required to record')),
        );
      }
    });
  }

  // Toggles recording on and off
  Future<void> _toggleRecording() async {
    final notifier = ref.read(recordingProvider.notifier);
    final state = ref.read(recordingProvider);

    if (state == RecordingState.recording) {
      await notifier.stopRecording();
    } else {
      await notifier.startRecording();
    }
  }

  // Previews the recorded audio
  Future<void> _previewRecording() async {
    final path = ref.read(recordingProvider.notifier).recordingPath;
    if (path == null) return;

    if (_isPlaying) {
      await _previewPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      await _previewPlayer.setFilePath(path);
      await _previewPlayer.play();
      setState(() => _isPlaying = true);

      // Reset when preview finishes
      _previewPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    }
  }

  // Opens the color picker
  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: BlockPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) => setState(() => _selectedColor = color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Saves the recording as a new sound button
  Future<void> _save() async {
    final recordingState = ref.read(recordingProvider);

    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a label')),
      );
      return;
    }

    if (recordingState != RecordingState.stopped) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a sound first')),
      );
      return;
    }

    // Save the recording to permanent storage
    final savedPath = await ref
        .read(recordingProvider.notifier)
        .saveRecording(_labelController.text.trim());

    if (savedPath == null) return;

    // Create a new sound button with the recording
    await ref.read(soundButtonProvider.notifier).addButton(
          label: _labelController.text.trim(),
          audioFilePath: savedPath,
          color: _selectedColor.value,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _previewPlayer.dispose();
    ref.read(recordingProvider.notifier).discardRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final isRecording = recordingState == RecordingState.recording;
    final hasStopped = recordingState == RecordingState.stopped;

    return AlertDialog(
      title: const Text('Record Sound'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label input
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Button label',
              hintText: 'e.g. Drumroll',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          // Record button — pulses red while recording
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : Colors.red.shade800,
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Status text below the record button
          Text(
            isRecording
                ? 'Recording...'
                : hasStopped
                    ? 'Recording complete'
                    : 'Tap to record',
            style: TextStyle(
              color: isRecording ? Colors.red : Colors.white38,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Preview and color buttons — only shown after recording
          if (hasStopped) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Preview playback button
                TextButton.icon(
                  onPressed: _previewRecording,
                  icon: Icon(_isPlaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(_isPlaying ? 'Stop' : 'Preview'),
                ),

                // Color picker button
                GestureDetector(
                  onTap: _pickColor,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
                // ── Input Device Selector ──────────────────────────────────
          // Only shown when multiple input devices are available
          // On most phones this won't appear — mainly useful on desktop
          //FutureBuilder<List<InputDevice>>(
          //  future: ref.read(recordingProvider.notifier).getAvailableDevices(),
          //  builder: (context, snapshot) {
          //    final devices = snapshot.data ?? [];

              // Hide the selector if there's only one device available
          //    if (devices.length <= 1) return const SizedBox.shrink();

          //    return Column(
          //      crossAxisAlignment: CrossAxisAlignment.start,
          //      children: [
          //        const SizedBox(height: 12),
          //        const Text(
          //          'Input device',
          //          style: TextStyle(color: Colors.white54, fontSize: 12),
          //        ),
          //        const SizedBox(height: 4),
          //        // Dropdown showing all available input devices
          //        DropdownButton<InputDevice>(
          //          isExpanded: true,
          //          hint: const Text('Default microphone'),
          //          items: devices.map((device) {
          //            return DropdownMenuItem<InputDevice>(
          //              value: device,
          //              child: Text(
          //                device.label,
          //                overflow: TextOverflow.ellipsis,
          //              ),
          //            );
          //          }).toList(),
          //          onChanged: (device) {
          //            if (device != null) {
          //              ref
          //                  .read(recordingProvider.notifier)
          //                  .setInputDevice(device);
          //            }
          //          },
          //        ),
          //      ],
          //    );
          //  },
          //),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        // Save button only shown after a recording is complete
        if (hasStopped)
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
      ],
    );
  }
}