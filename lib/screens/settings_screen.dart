import 'package:flutter/material.dart';

// Placeholder for now — fully built out in Phase 9
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Settings — coming in Phase 9',
          style: TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}