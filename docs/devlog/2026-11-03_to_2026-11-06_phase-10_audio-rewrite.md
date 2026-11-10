# Phase 10 - Audio architecture rewrite

**Version:** v0.10.2 (in progress)
**Branch:** wip/audio-rewrite (based on v0.10.1)

**Note:** This entry grew across several days of debugging, so the early sections are less organized than the later ones.

## Problems found

### 1. No visual indicators on the first press of a button
- **Status:** In progress (cause confirmed)
- **Symptom:** On the first press of any button, no progress bar, pause strip, or instance counter appears while the audio plays. The indicators only appear after the first instance has finished, and the count only updates when an instance finishes.
- **Hypothesis:** On tap, the button plays the audio, waits for the audio to finish, and only then checks how many instances of that audio are active. The code needs to check for the button's instances after the audio starts but before the first instance finishes.
- **Cause:** `_handleTap` awaits `audioService.playSound(...)`, and `playSound` does not return until the sound has ended. `_loadAndPlay` awaits `player.play()`, whose Future completes only when playback finishes, is paused, or is stopped (just_audio docs), and `_createAndPlay` then waits for `completed`. The widget therefore looks up the new player (`getPlayers(...).last`) only after the sound is over, when the `finally` block has already removed it from the Set. Confirmed by Test 1 (Android, 2026-11-07): `[check1] play() returned` printed after `completed`, just before `[check3] finally ran`. The "second press onward" pattern comes from the same lookup: when the first tap's wait finally resumes, `players.last` can be a still-playing instance from a later tap (explained by reading the code, not tested separately).
- **Fix:** (pending)
- **Lesson:** (pending)

### 2. Instance counts and indicators don't match the audio actually playing
- **Status:** In progress (partial cause)
- **Symptom:** In simultaneous playback mode, the instance count shown on a button doesn't always match the number of sounds actually playing. Indicators (progress bar, pause strip, counter) stay on screen after the audio has ended, as if an instance were still playing.
- **Hypothesis:** The audio instances are registered and counted inconsistently, and the places that track them (the service's Set, the service's counter, and the widget's own tracking) don't stay in sync.
- **Related:** Problems 3, 5, and 6 (may share a cleanup cause)
- **Cause (partial):** (a) Stopped players are never removed from the service's Set or counter, because cleanup waits for `completed`, which never arrives after `stop()` (Test 2). (b) The widget keeps its own copies of the information (`_instanceCount`, `_playerProgress`) and tracks `players.last`, which can be a different instance than the one that was started (code reading, untested). It is not yet confirmed whether (b) accounts for every mismatch.
- **Fix:** (pending)
- **Lesson:** (pending)

### 3. Stop All button doesn't disappear when audio stops
- **Status:** In progress (cause confirmed, effect inferred)
- **Symptom:** The Stop All button appears when a sound starts, as intended. It stays visible after all audio has stopped, and also when no indicators are visible on any button.
- **Hypothesis:** Audio instances aren't being properly deleted after they finish or are stopped, so the global counter never returns to 0.
- **Related:** Problems 2, 5, and 6
- **Cause:** Hypothesis result: partly correct. Instances that finish naturally are cleaned up (Test 1: `finally ran` printed after `completed`). Instances that are *stopped* are not. In Test 2 (Android, 2026-11-07), after Stop All the player went to `idle` with `playing=false`, and neither `completed` nor `[check3] finally ran` printed. `_createAndPlay` removes the player and decrements `_activeInstanceCount` only in its `finally` block, which runs only after `completed`, so a stopped player stays in the Set and the counter is never decremented. Every stop path has this problem: Stop All, exclusive-mode restarts, solo mode (which calls `stopAll`), and remove-latest. The Stop All button vanishing instantly in Test 2 comes from a separate cause: its `onTap` sets `HomeScreen`'s own `_activeInstanceCount` to 0. The stale service count (it emits stale + 1 on the next `playSound`) is inferred from the code and not yet observed directly.
- **Fix:** (pending)
- **Lesson:** (pending)

### 4. Progress bars stack vertically instead of overlapping
- **Status:** Open (cause identified by code reading)
- **Symptom:** In simultaneous playback mode, when a button is pressed multiple times, each instance's progress bar is added below the previous one. This clutters the button with several separate bars instead of layered semi-transparent bars in one spot.
- **Hypothesis:** The layout function automatically corrects for overlap. Check for a library widget that gives the effect I want, otherwise copy its code and rewrite it for overlapping.
- **Cause:** Hypothesis result: partly correct. A layout widget does decide the placement, but nothing "corrects" anything: the bars are children of a `Column`, which by definition lays children out one after another vertically. Layering needs a `Stack`, which the same `build()` method already uses, so no library or copied code is needed. (From code reading; the label padding and pause strip offsets assume the vertical layout and will need rethinking.)
- **Fix:** (pending)
- **Lesson:** (pending)

### 5. Progress bar often stays after audio has finished
- **Status:** Open
- **Symptom:** The progress bar often remains after an audio instance has finished. It persists even after the indicators have disappeared and reappeared, so bars could accumulate indefinitely on a button.
- **Hypothesis:** (not sure yet - I think it's related to Problems 2 and 3, but it's too inconsistent for me to be sure.)
- **Related:** Problems 2, 3, and 6
- **Cause:** (pending)
- **Fix:** (pending)
- **Lesson:** (pending)

### 6. Stop All doesn't get rid of visual indicators
- **Status:** In progress (cause confirmed)
- **Symptom:** When the Stop All button is pressed, all audio stops but the visual indicators on the buttons remain.
- **Hypothesis:** I should check the connection between all the audio tracking and the Stop All button, to make sure they are connected properly.
- **Related:** Problems 2, 3, and 5
- **Cause:** Stop All calls `stop()` on each player, and a stopped player goes to `idle` and never reaches `completed` (Test 2). Each button widget clears its indicators (`_onInstanceEnded`) only when its own listener sees `completed` (or when remove-latest is tapped), and `stopAll` sends the widgets no other signal, so their indicators are never cleared.
- **Fix:** (pending)
- **Lesson:** (pending)

### 7. Pause strip only pauses currently active audio
- **Status:** Open
- **Symptom:** The pause strip pauses the active audio but ignores new instances. [Rewrite as numbered steps, naming the control each time: sound button or pause strip.] Reported sequence: on the second press, the paused instances resume while the currently playing instance is ignored and the pause icon doesn't change. On the third press, the icon changes but all instances are unchanged. From the fourth press onward it works normally, as long as the bug is not repeated.
- **Decision (2026-11-05):** Pause state is derived from per-instance records. The strip shows three states (all paused, none paused, mixed). Pressing it in the mixed state pauses all.
- **Note:** This isn't necessarily a bug. If new instances should be able to join and "catch up" with paused ones, I need to fix the strip's behavior and redesign it to reduce accidental presses, even on small screens.
- **Hypothesis:** The pause function only pauses the active audio instances instead of enforcing a paused state that all instances in the list have to follow.
- **Hypothesis 2 (added 2026-11-07, untested):** `resumeButton` awaits `play()` for each player inside a loop. Because `play()` completes when a sound finishes, pauses, or stops, the loop can stall on the first player and leave the others paused, and the `setState` after it runs late.
- **Related:** Problem 1 (same "await doesn't finish when expected" mechanism)
- **Cause:** (pending)
- **Fix:** (pending)
- **Lesson:** (pending)

## Root cause groups

| Group | Problems | What it is | Evidence |
|---|---|---|---|
| A. Registration timing | 1, part of 2 | The widget learns about a player only when `playSound` returns, which is when the sound ends | Confirmed (Test 1) |
| B. Exit paths not unified | 3, 6, part of 2 | Cleanup happens only if a player reaches `completed`, and stopped players never do | Confirmed (Test 2) |
| C. Duplicated state and unmanaged listeners in the widget | 2, 5 | The widget keeps its own copies of instance data and listeners nobody cancels | Likely (code reading, untested) |
| Independent: layout | 4 | `Column` instead of `Stack` | Code reading |
| Design gap | 7 | Pause state is a stored flag that can disagree with the players; resume loop may stall | Partly untested |

## Session log

### 2026-08-?? (before the break for studies)
**Goal**
- Replace the single-player audio logic with a per-button Set of players, a global instance counter, layered semi-transparent progress bars, a per-button pause strip (pauses all of that button's instances), and an instance badge.

**What I did**
- Rewrote `audio_service.dart`, `sound_button_widget.dart`, and `home_screen.dart`.
- Designed the approach from a flowchart of the old logic, which showed that listeners were being attached on every tap and never removed.

### 2026-11-03
**Goal**
- Study the files related to the problems found when Phase 10 started.
- Catch up on the planned steps.

**What I did**
- Caught up on what had been done and what I had planned:
  - Earlier, I found an issue with how audio playback instances were being handled. I redesigned the part of the audio architecture that creates and removes listeners, and used AI to write most of the code from my understanding of the issue, to patch the bugs.
  - In the process, I found fundamental problems with the audio management architecture as a whole and decided that a full analysis and redesign was needed so it keeps working consistently as features are added or changed (something I hadn't accounted for when I started the project).

### 2026-11-04
**Goal**
- Continue studying the code and find root causes.
- Create documentation to prevent the confusion from 11-03.

**What I did**
- Created the devlog and changelog templates and filled them in as best I could.
- Understood the core problems well enough to hypothesize likely root causes for Problems 1, 2, and 3.
- Created the branch `wip/audio-rewrite` to preserve the uncommitted rewrite.

### 2026-11-05
**Goal**
- Test the known bugs for reproducibility.
- Test for undiscovered bugs, based on what I learned about the architecture problems.
- Redesign the faulty architecture.

**What I did**
- Found Problem 6.
- Reworked the devlog format.
- Started the architecture redesign:
  - Decided on a unidirectional (one-way) data flow: UI actions go to the service, the service reports to the ledger, derived values come from the ledger, and the UI reads them.
  - The service acts and decides. A ledger (a Riverpod notifier) only records what the service reports.
  - Chose a Riverpod provider over per-button streams for delivering state to widgets.
  - All instance cleanup goes through one method, `_endInstance`, owned by the service.
  - Stop All is a full reset: it ends every instance, playing or paused.
  - Pause state is derived from per-instance records (three states).

### 2026-11-06
**Goal**
- Confirm the root causes of the bugs found.
- Use the confirmed information to finish restructuring the data and control flow.
- Create flowcharts to understand the architecture changes better.

**What I did**
- Found Problem 7.
- Studied the relevant code extensively and formed hypotheses about the causes by reading it (not yet confirmed by tests).
- Created the first draft of the flowchart file for all changed data and control flow.
- Decided that the ledger record is added at creation (before the file loads) and that the Stop All safety-net warning stays permanently.

### 2026-11-07
**Goal**
- Finish running diagnostics on the root causes of the bugs.
- Create the finalized flowchart file.
- Build the fix in stages, verifying each stage.

**What I did**
- Ran diagnostic prints (`[check1]` to `[check3]`) on Android and confirmed the causes of Problems 1, 3, and 6 (see those entries). Facts learned:
  - `play()` completes when a sound finishes, pauses, or stops, so its return never means "ended".
  - `stop()` leaves the player at `idle` and never reaches `completed`.
  - `idle` also appears at the start of a player's life, so it can't be an end signal.
- Settled the remaining design decisions:
  - The ledger is passed into the service when it is created.
  - The service detects a natural finish with a stored subscription that `_endInstance` cancels.
  - Deleting a button ends its instances first (a seventh exit path).
  - The glow is flat.
  - A universal pause/play button is planned for after the fixes.
- Finalized `audio_redesign_flowcharts.md` (8 diagrams).
- Stage 1: created `InstanceRecord` (with `pauseStateOf`), the `AudioInstancesNotifier` ledger with derived providers, and 5 unit tests (all pass). `flutter analyze` reports 5 existing deprecation warnings, none in the new files. App behavior is unchanged. Committed to `wip/audio-rewrite`.


## Next
- Stage 2: rewrite `AudioService` (ledger passed in, `_startInstance` / `_endInstance`, subscription-based completion). This also removes the temporary `[check]` prints.
- Stage 3: `HomeScreen` Stop All driven by `totalInstancesProvider`.
- Stage 4: `SoundButtonWidget` reads from the ledger; bars in a `Stack`; badge.
- Stage 5: pause and resume with per-instance flags and the three-state icon.
- Stage 6: Stop All with safety net, remove-latest, and the delete-button path.
- Stage 7: remove leftover prints, update devlog and changelog, commit as v0.10.2.
- Later (not part of this fix): universal pause/play button; fix 5 deprecation warnings (`Color.value`, `RadioListTile`); visual redesign; Windows desktop support and recording input device selection; pauses initiated by the OS; learn the `Ref`-based service wiring (Option B).