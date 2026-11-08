import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundboard/models/instance_record.dart';
import 'package:soundboard/providers/audio_instances_provider.dart';

// A stand-in for AudioPlayer. 'Fake' makes every method throw if called, which is
// fine: the ledger never calls the player, it only keeps track of which object it is.
class FakePlayer extends Fake implements AudioPlayer {}

void main() {
  test('add records an instance that starts unpaused', () {
    final ledger = AudioInstancesNotifier();
    final player = FakePlayer();

    ledger.add('a', player);

    expect(ledger.recordsFor('a').length, 1);
    expect(ledger.recordsFor('a').first.isPaused, isFalse);
  });

  test('remove works, and calling it twice is harmless', () {
    final ledger = AudioInstancesNotifier();
    final player = FakePlayer();
    ledger.add('a', player);

    ledger.remove('a', player);
    ledger.remove('a', player); // second call must be a no-op, not an error

    expect(ledger.allRecords, isEmpty);
  });

  test('setPaused changes only that instance and pauseStateOf follows', () {
    final ledger = AudioInstancesNotifier();
    final p1 = FakePlayer();
    final p2 = FakePlayer();
    ledger.add('a', p1);
    ledger.add('a', p2);
    expect(pauseStateOf(ledger.recordsFor('a')), PauseState.nonePaused);

    ledger.setPaused('a', p1, true);
    expect(pauseStateOf(ledger.recordsFor('a')), PauseState.mixed);

    ledger.setPaused('a', p2, true);
    expect(pauseStateOf(ledger.recordsFor('a')), PauseState.allPaused);
  });

  test("changing one button keeps another button's list the same object", () {
    final ledger = AudioInstancesNotifier();
    ledger.add('a', FakePlayer());
    final listBefore = ledger.recordsFor('a');

    ledger.add('b', FakePlayer());

    // Same object, so a widget watching 'a' would not rebuild
    expect(identical(ledger.recordsFor('a'), listBefore), isTrue);
  });

  test('derived providers calculate from the one ledger', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ledger = container.read(audioInstancesProvider.notifier);

    ledger.add('a', FakePlayer());
    ledger.add('a', FakePlayer());
    ledger.add('b', FakePlayer());

    expect(container.read(totalInstancesProvider), 3);
    expect(container.read(buttonInstancesProvider('a')).length, 2);
    expect(container.read(buttonInstancesProvider('zzz')), isEmpty);
  });
}