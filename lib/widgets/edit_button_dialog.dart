// Material package for UI components
import 'package:flutter/material.dart';

// Riverpod for accessing the sound button provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Color picker widget
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// Our data model and providers
import '../models/sound_button.dart';
import '../providers/sound_button_provider.dart';
import '../services/file_service.dart';

class EditButtonDialog extends ConsumerStatefulWidget {
  // The button being edited is passed in when the dialog opens
  final SoundButton button;

  const EditButtonDialog({super.key, required this.button});

  @override
  ConsumerState<EditButtonDialog> createState() => _EditButtonDialogState();
}

class _EditButtonDialogState extends ConsumerState<EditButtonDialog> {
  late TextEditingController _labelController;
  late Color _selectedColor;
  final _fileService = FileService();

  @override
  void initState() {
    super.initState();
    // Pre-fill the label field with the button's current name
    _labelController = TextEditingController(text: widget.button.label);
    // Pre-select the button's current color
    _selectedColor = Color(widget.button.color);
  }

  // Opens the color picker dialog
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

  // Saves the updated button properties
  Future<void> _save() async {
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label')),
      );
      return;
    }

    // Update the button's properties using copyWith pattern
    // We modify only what changed and keep everything else the same
    final updatedButton = SoundButton(
      id: widget.button.id,
      label: _labelController.text.trim(),
      audioFilePath: widget.button.audioFilePath,
      color: _selectedColor.value,
      createdAt: widget.button.createdAt,
      categoryId: widget.button.categoryId,
      isFavorite: widget.button.isFavorite,
    );

    await ref.read(soundButtonProvider.notifier).updateButton(updatedButton);
    if (mounted) Navigator.pop(context);
  }

  // Shows a confirmation dialog before deleting
  Future<void> _delete() async {
    // Ask the user to confirm before permanently deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete button?'),
        content: Text(
          'Are you sure you want to delete "${widget.button.label}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Red color signals a destructive action to the user
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete the audio file from device storage
    await _fileService.deleteAudioFile(widget.button.audioFilePath);

    // Delete the button from Hive
    await ref.read(soundButtonProvider.notifier).deleteButton(widget.button.id);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Button'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label input pre-filled with current name
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Button label',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Color picker row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.color_lens_rounded),
            title: const Text('Button color'),
            trailing: GestureDetector(
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
          ),
          const SizedBox(height: 8),

          // Delete button — separated visually to signal it's destructive
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text(
              'Delete button',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _delete,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}