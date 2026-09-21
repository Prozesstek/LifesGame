import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Merkt sich, was gespielt werden sollte, statt es zu spielen.
class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

void main() {
  group('Jeder Klang ist da', () {
    // `rootBundle` findet nur, was in `pubspec.yaml` steht — der Test
    // prüft Datei **und** Anmeldung in einem Zug, wie bei den Bildern.
    TestWidgetsFlutterBinding.ensureInitialized();

    test('jede Datei lässt sich laden und ist nicht leer', () async {
      for (final effect in SoundEffect.values) {
        final daten = await rootBundle.load('assets/${effect.asset}');
        expect(daten.lengthInBytes, greaterThan(1000), reason: effect.name);
      }
    });

    test('ohne main.dart bleibt es still', () {
      // Der Standard darf keinen Plattformkanal anfassen — sonst fiele
      // jeder Widget-Test um, der zufällig einen Klang auslöst.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(soundPlayerProvider), isA<SilentSoundPlayer>());
    });
  });

  group('Ein Häkchen klingt', () {
    testWidgets('beim Setzen, nicht beim Zurücknehmen', (tester) async {
      final mitschrift = _Mitschrift();
      final container = ProviderContainer(
        overrides: [
          todayProvider.overrideWithValue(const Day(2026, 8, 12)),
          soundPlayerProvider.overrideWithValue(mitschrift),
        ],
      );
      addTearDown(container.dispose);

      final lernen = container.read(theoryProgressProvider.notifier);
      for (final lesson in habitsBranch.lessons) {
        lernen.submit(lesson, <int?>[
          for (final q in lesson.questions) q.correctIndex,
        ]);
      }

      useTallView(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HabitsScreen()),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();
      expect(mitschrift.gespielt.first, SoundEffect.haekchen);

      // Das erste Häkchen überhaupt ist „Erster Schritt" — die Feier
      // kommt einen Bildaufbau später und bringt ihren eigenen Klang.
      await tester.pump();
      expect(mitschrift.gespielt, contains(SoundEffect.errungenschaft));

      // Das Blatt schliessen, dann zurücknehmen: kein neuer Klang.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final vorher = mitschrift.gespielt.length;
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pump();
      expect(mitschrift.gespielt, hasLength(vorher));
    });
  });
}
