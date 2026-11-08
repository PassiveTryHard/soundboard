// Riverpod: StateNotifier holds state, Provider derives values from it
import 'package:flutter_riverpod/flutter_riverpod.dart';

// AudioPlayer is the type the records identify instances by
import 'package:just_audio/just_audio.dart';

import '../models/instance_record.dart';

// THE LEDGER. It records what the AudioService reports and decides nothing itself.
// State: for each button id, the list of its active instances.
// No instances = no entry, so the map never fills up with empty lists.
class AudioInstancesNotifier
    extends StateNotifier<Map<String, List<InstanceRecord>>> {
  AudioInstancesNotifier() : super(const {});

  // ---- Read-only views: the service uses these, none of them change state ----

  // All records for one button. Every stored list is unmodifiable, so callers
  // can't change the ledger by accident. Buttons with nothing playing get an empty list.
  List<InstanceRecord> recordsFor(String buttonId) =>
      state[buttonId] ?? const [];

  // Every record across all buttons, as a fresh unmodifiable copy.
  // 'expand' flattens the lists of all buttons into one sequence.
  List<InstanceRecord> get allRecords =>
      List.unmodifiable(state.values.expand((records) => records));

  // Is this exact player currently recorded? This is what makes _endInstance
  // safe to call twice. 'identical' compares object identity, not contents.
  bool contains(String buttonId, AudioPlayer player) =>
      recordsFor(buttonId).any((r) => identical(r.player, player));

  // ---- Reports: the service calls these AFTER it has acted ----

  // A new instance started
  void add(String buttonId, AudioPlayer player) {
    _replace(buttonId, [...recordsFor(buttonId), InstanceRecord(player: player)]);
  }

  // An instance ended. Calling this twice is harmless: the second call finds nothing.
  void remove(String buttonId, AudioPlayer player) {
    if (!contains(buttonId, player)) return;
    _replace(
      buttonId,
      recordsFor(buttonId).where((r) => !identical(r.player, player)).toList(),
    );
  }

  // The service paused (true) or resumed (false) an instance.
  // Only that instance's record is replaced; the others are carried over as they are.
  void setPaused(String buttonId, AudioPlayer player, bool paused) {
    if (!contains(buttonId, player)) return;
    _replace(buttonId, [
      for (final r in recordsFor(buttonId))
        identical(r.player, player) ? r.copyWith(isPaused: paused) : r,
    ]);
  }

  // The ONLY place state is assigned. It builds a NEW map (never edits the old one),
  // because Riverpod only notices a change when `state` points at a different object.
  // The lists for every other button are carried over as the same objects, so
  // widgets watching those buttons don't rebuild.
  void _replace(String buttonId, List<InstanceRecord> records) {
    // If the app is shutting down, this notifier may already be disposed.
    // Assigning state after dispose would throw, so we skip it.
    if (!mounted) return;

    final next = Map<String, List<InstanceRecord>>.of(state); // copy of the map only
    if (records.isEmpty) {
      next.remove(buttonId);
    } else {
      next[buttonId] = List.unmodifiable(records);
    }
    state = next;
  }
}

// The ledger itself.
final audioInstancesProvider = StateNotifierProvider<AudioInstancesNotifier,
    Map<String, List<InstanceRecord>>>((ref) => AudioInstancesNotifier());

// DERIVED: the total number of instances across all buttons.
// Nothing is stored. It is recalculated whenever the ledger changes, so it can't
// disagree with the lists. This replaces the old manually maintained counter.
// fold(0, ...) starts at 0 and adds each button's list length (like std::accumulate).
final totalInstancesProvider = Provider<int>((ref) {
  final all = ref.watch(audioInstancesProvider);
  return all.values.fold(0, (sum, records) => sum + records.length);
});

// DERIVED: one button's records. '.family' lets the provider take a parameter, the button id.
// An unchanged button returns the same list object (or the same const empty list),
// so its widget isn't rebuilt when a different button changes.
final buttonInstancesProvider =
    Provider.family<List<InstanceRecord>, String>((ref, buttonId) {
  return ref.watch(audioInstancesProvider)[buttonId] ?? const [];
});