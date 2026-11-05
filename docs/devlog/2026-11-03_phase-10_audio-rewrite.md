# Phase 10 - Audio architecture rewrite

**Date:** 2026-11-03
**Version:** v0.10.2 (in progress)

## Goal
Replace the single-player audio logic with a per-button Set of players, a global instance counter, stacked progress bars, a pause-all strip,
and an instance badge.

## What I did
Rewrote audio_service.dart, sound_button_widget.dart, and home_screen.dart.
Designed the approach from a flowchart of the old logic, which showed that listeners were being attached on every tap and never removed.

## Problems found

### 1. No visual indicators on the first press of a button
- **Status:** Open
- **Symptom:** On the first press of any button, no progress bar, pause strip, or instance counter appears while the audio plays. The indicator only appears after the first instance has finished and only updates the count after an instance has finished.
- **Hypothesis:** On tap the button plays the audio, waits for the audio to finish, and then continues to check how many instances of the relevant audio are active only after the first instance has finished. The code needs to check for instances of the current relevant button after the audio starts but before the first instance finishes.
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 2. Instance counts and indicators don't match the audio actually playing
- **Status:** Open
- **Symptom:** In simultaneous playback mode, the instance count shown on a button doesn't always match the number of sounds actually playing. Indicators (progress bar, pause strip, counter) stay on screen after the audio has ended, as if an instance were still playing.
- **Hypothesis:** The audio instances are registered and counted inefficiently, and the different lists tracking them (the service's Set, the service's counter, and the widget's own tracking) don't stay connected properly.
- **Related:** Problem 3, 5, & 6(all may share a cleanup cause)
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 3. Stop All button doesn't disappear when audio stops
- **Status:** Open
- **Symptom:** The Stop All button appears when a sound starts, as intended. It stays visible after all audio has stopped, and also when no indicators are visible on any button.
- **Hypothesis:** Audio instances aren't being properly deleted after they finish or are stopped, so the global counter never returns to 0.
- **Related:** Problem 2, 5, & 6
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 4. Progress bars stack vertically instead of overlapping
- **Status:** Open
- **Symptom:** In simultaneous playback mode, when a button is pressed multiple times, each instance's progress bar is added below the previous one. This clutters the button with several separate bars instead of layered semi-transparent bars in one spot.
- **Hypothesis:** The layout function automatically corrects for overlap. Check for a library widget that gives the effect I want, otherwise copy its code and rewrite it for overlapping.
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 5. Progress bar often stays after audio has finished
- **Status:** Open
- **Symptom:** It is common for progress bar to not delete after an audio instance has finished. This persists even after visual indicator has been removed and reactivated, causing potential infinite clutter of the sound button.
- **Hypothesis:** (not sure yet - I think it's related problem 2 and 3 but it's too inconsistent for me to be sure.)
- **Related:** Problem 2, 3, & 6
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 6. Stop All doesn't get rid of visual indicators
- **Status:** Open
- **Symptom:** When Stop All button is pressed, all audio stops but visual indicators continue uninterrupted.
- **Hypothesis:** (not sure yet - Should check connection between all audio checks to make sure they're connected to Stop All button properly)
- **Related:** Problem 2, 3, & 5
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

## Next
- Finish fixing the issues above
- Commit as v0.10.2