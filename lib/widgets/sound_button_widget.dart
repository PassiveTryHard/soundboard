import 'package:flutter/material.dart';
import '../models/sound_button.dart';

class SoundButtonWidget extends StatelessWidget {
  final SoundButton button;

  const SoundButtonWidget({super.key, required this.button});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Audio playback wired up in Phase 4
      },
      onLongPress: () {
        // Button edit menu wired up in Phase 8
      },
      child: Container(
        decoration: BoxDecoration(
          // Uses the color stored on the SoundButton object
          color: Color(button.color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              button.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}