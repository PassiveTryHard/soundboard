import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/sound_button_provider.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';

class AddButtonDialog extends ConsumerStatefulWidget {
  const AddButtonDialog({super.key});

  @override
  ConsumerState<AddButtonDialog> createState() => _AddButtonDialogState();
}

class _AddButtonDialogState extends ConsumerState<AddButtonDialog> {
  // Controller lets us read what the user typed in the label field
  final _labelController = TextEditingController();
  final _fileService = FileService();

  String? _selectedFilePath; // Path to the audio file the user picked
  Color _selectedColor = AppTheme.accentColor; // Default to our purple
  bool _isLoading = false; // Shows a spinner while picking/copying a file

  // Opens the file picker and stores the result
  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    final path = await _fileService.pickAudioFile();
    setState(() {
      _selectedFilePath = path;
      _isLoading = false;
    });
  }

  // Opens the color picker dialog
  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: BlockPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) {
            setState(() => _selectedColor = color);
          },
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

  // Validates input and creates the button
  Future<void> _save() async {
    // Make sure the user filled in both required fields
    if (_labelController.text.trim().isEmpty || _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a label and pick a sound file')),
      );
      return;
    }

    // Add the button via the provider
    await ref.read(soundButtonProvider.notifier).addButton(
          label: _labelController.text.trim(),
          audioFilePath: _selectedFilePath!,
          color: _selectedColor.value,
        );

    // Close the dialog
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    // Always dispose controllers to free up memory
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sound Button'),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Dialog only as tall as it needs to be
        children: [
          // Label input field
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Button label',
              hintText: 'e.g. Airhorn',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // File picker button
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.audio_file_rounded),
            title: Text(
              // Shows the file name if picked, otherwise a prompt
              _selectedFilePath != null
                  ? _selectedFilePath!.split('/').last
                  : 'No file selected',
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _isLoading
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _pickFile,
                    child: const Text('Browse'),
                  ),
          ),
          const SizedBox(height: 8),

          // Color picker button
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
                  // Preview of the currently selected color
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}