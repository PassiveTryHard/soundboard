# Phase 10 - Audio architecture rewrite
**Version:** v0.10.2 (in progress)

**Current version disorganized due to continuous multi-day debugging**


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
- **Related:** Problems 3, 5, & 6 (all may share a cleanup cause)
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 3. Stop All button doesn't disappear when audio stops
- **Status:** Open
- **Symptom:** The Stop All button appears when a sound starts, as intended. It stays visible after all audio has stopped, and also when no indicators are visible on any button.
- **Hypothesis:** Audio instances aren't being properly deleted after they finish or are stopped, so the global counter never returns to 0.
- **Related:** Problems 2, 5, & 6
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
- **Symptom:** It is common for the progress bar not to disappear after an audio instance has finished. This persists even after the visual indicator has been removed and reactivated, causing potential infinite clutter of the sound button.
- **Hypothesis:** (not sure yet - I think it's related to problem 2 and 3 but it's too inconsistent for me to be sure.)
- **Related:** Problems 2, 3, & 6
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 6. Stop All doesn't get rid of visual indicators
- **Status:** Open
- **Symptom:** When Stop All button is pressed, all audio stops but visual indicators continue uninterrupted.
- **Hypothesis:** Should check connection between all audio checks to make sure they're connected to Stop All button properly
- **Related:** Problems 2, 3, & 5
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)

### 7. Pause button only pauses currently active audio
- **Status:** Open
- **Symptom:** The pause button pauses active audio but ignores new instances if the button is pressed for a second time. On second press, paused instances are resumed while currently playing instance is ignored and pause symbol doesn't change. On third press pause symbol changes but all instances are unchanged. Fourth press and onwards function as normal as long as the bug is not repeated.
- **Note:** (Edit: Decided: pause state derived from per-instance records. Strip shows three states (all paused, none paused, mixed). Pressing in the mixed state pauses all.) This isn't necessarily a bad thing. If I want to make it possible to add new instances and have it catch up to the rest I'll need to fix the issue that occurs with the button itself and rework button design to make accidental presses less likely, even in smaller screens.
- **Hypothesis:** Pause function only pauses active audio instances rather than enforcing a paused state that all instances in the list have to abide by.
- **Cause:** (leave blank until confirmed)
- **Fix:** (leave blank until fixed)
- **Lesson:** (what you'd do differently)


**Date:** 2026-8-?? - (This part of development was started before I had to pause for studies)

## Goal
- Replace the single-player audio logic with a per-button Set of players, a global instance counter, stacked progress bars, a pause-all strip, and an instance badge.

## What I did
- Rewrote audio_service.dart, sound_button_widget.dart, and home_screen.dart.
- Designed the approach from a flowchart of the old logic, which showed that listeners were being attached on every tap and never removed.


**Date:** 2026-11-03

## Goal
- Study files related to the problems that were found when phase 10 was started.
- Catch up on planned steps.

## What I did
- Caught up on what had been done and what steps I had planned:
    - Previously found issue with how audio files where being handled and used AI write the bulk of the code after redesigning the part of the audio management architecture that handles creating and removing listeners based on what I understood of the issue to patch the bugs.
    - In the process, I found fundamental problems with the entire audio management architecture and decided that a full analisys and redesign was needed to ensure consistant function even with new features or adjustments. (something I hadn't accounted for when I originally started the project)


**Date:** 2026-11-04

## Goal
- Continue studying code and find root causes.
- Create documentation to prevent confusion from 11-03

## What I did
- Created dev log and change log templates and filled them in as best I could.
- Understood core problems well enough to hypothesize likely root causes for bugs 1, 2, and 3


**Date:** 2026-11-05

## Goal
- Test for reliability of currently known bugs.
- Test for undiscovered bugs based on information learned about architecture problems.
- Redesign faulty architecture.

## What I did
- Found bug 6.
- Reworked dev log format.
- Started redesign of architecture:
    - Decided on linear data flow philosophy to follow
    (Will finish filling out on next commit, too much disorganized documentation to go through)...


**Date:** 2026-11-06

## Goal
- Confirm the root causes for found bugs.
- Use confirmed information to finish restructuring data and control flow.
- Create flowcharts to understand architecture changes better.

## What I did
- Found bug 7.
- Studied relevant code extensively and mostly confirmed the causes of the found bugs.
- Created first draft of flowchart file for all changed data and control flow.


**Date:** 2026-11-07

## Goal
- Finish running diagnostics on bug root causes.
- Create finalized flowchart file.
- Add in staged changes to code based on verifiable functionality.

## What I did


## Next
- Finish fixing the issues above
- Fix 5 deprecation warnings (Color.value, RadioListTile)
- Commit as v0.10.2

