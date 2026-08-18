import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/save/save_store.dart';
import 'package:lifes_game/save/save_watcher.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Prüft die Schicht, die kein Package allein prüfen kann: dass ein
/// Neustart der App den Fortschritt behält.
///
/// Die Packages prüfen jeweils, dass **ihre** Daten durch JSON und zurück
/// kommen. Hier geht es um die Verdrahtung: Wird überhaupt geschrieben,
/// wird beim Start gelesen, und kommt danach dasselbe heraus.
void main() {
  const habitId = 'habit-drei-aufgaben';
  const itemId = 'gear-lederkappe';
  const tag = Day(2026, 8, 17);

  /// Ein Container, wie ihn die App beim Start aufbaut.
  ProviderContainer containerMit(SaveData saved, SaveStore store) {
    final container = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        saveStoreProvider.overrideWithValue(store),
        todayProvider.overrideWithValue(tag),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Ein Neustart behält den Fortschritt', () {
    test('Häkchen, Lektionen und Ausrüstung kommen wieder', () {
      // Erste Sitzung.
      final store = InMemorySaveStore();
      final erste = containerMit(const SaveData.empty(), store);

      erste.read(habitTrackerProvider.notifier).activate(habitId);

      // Vier Wochen abhaken — genug Gold für das billigste Stück im Laden.
      // Der Umweg ist Absicht: Er prüft den ganzen Weg Häkchen → Gold →
      // Kauf, nicht nur das Speichern eines gesetzten Werts.
      var haken = tag;
      for (var i = 0; i < 28; i++) {
        erste.read(habitTrackerProvider.notifier).toggle(habitId, haken);
        haken = haken.next;
      }

      final lesson = theoryTree.branches.first.lessons.first;
      erste.read(theoryProgressProvider.notifier).submit(lesson, <int?>[
        for (final question in lesson.questions) question.correctIndex,
      ]);

      expect(erste.read(loadoutProvider.notifier).buy(itemId), isNull);

      final stand = SaveData(
        theory: erste.read(theoryProgressProvider),
        habits: erste.read(habitTrackerProvider),
        loadout: erste.read(loadoutProvider),
      );
      final xpVorher = erste.read(totalXpProvider);
      final goldVorher = erste.read(goldProvider);

      // Zweite Sitzung: derselbe Stand, frischer Container.
      final zweite = containerMit(SaveData.decode(stand.encode()), store);

      expect(zweite.read(habitTrackerProvider).isChecked(habitId, tag), isTrue);
      expect(zweite.read(theoryProgressProvider).isPassed(lesson.id), isTrue);
      expect(zweite.read(loadoutProvider).isOwned(itemId), isTrue);
      expect(zweite.read(totalXpProvider), xpVorher);
      expect(zweite.read(goldProvider), goldVorher);
    });

    test('ohne Stand startet alles bei null', () {
      final container = containerMit(
        const SaveData.empty(),
        InMemorySaveStore(),
      );

      expect(container.read(totalXpProvider), 0);
      expect(container.read(goldProvider), 0);
      expect(container.read(playerLevelProvider).level, 1);
      expect(container.read(loadoutProvider).owned, isEmpty);
    });

    test('ein beschädigter Stand kostet den Start nicht', () {
      // Lieber leer starten als gar nicht starten.
      final container = containerMit(
        SaveData.decode('{ das ist kein json'),
        InMemorySaveStore(),
      );

      expect(container.read(totalXpProvider), 0);
      expect(container.read(habitTrackerProvider).activeIds, isEmpty);
    });

    test('der Gesamtstand überlebt Kodieren und Dekodieren', () {
      final tracker = const HabitTracker.empty()
          .activate(habitId)
          .check(habitId, tag)
          .tracker;
      final original = SaveData(
        habits: tracker,
        loadout: const Loadout.empty().buy(itemId, availableGold: 9999),
      );

      final gelesen = SaveData.decode(original.encode());

      expect(gelesen.habits.totalChecks, 1);
      expect(gelesen.loadout.isOwned(itemId), isTrue);
      expect(gelesen.isEmpty, isFalse);
      expect(const SaveData.empty().isEmpty, isTrue);
    });
  });

  group('Es wird auch tatsächlich geschrieben', () {
    testWidgets('ein Häkchen landet im Speicher', (tester) async {
      // Der Fehler, den dieser Test verhindert: Alles serialisiert sauber,
      // aber niemand ruft `write` auf. Das fällt sonst erst beim echten
      // Neustart auf.
      useTallView(tester);
      final store = InMemorySaveStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saveStoreProvider.overrideWithValue(store),
            todayProvider.overrideWithValue(tag),
          ],
          child: const SaveWatcher(child: LifesGameApp()),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LifesGameApp)),
      );
      container.read(habitTrackerProvider.notifier).activate(habitId);
      await tester.pump();

      expect(store.writes, greaterThan(0));
      final gespeichert = await store.read();
      expect(gespeichert.habits.activeIds, contains(habitId));
    });

    testWidgets('ein Kauf landet im Speicher', (tester) async {
      useTallView(tester);
      final store = InMemorySaveStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saveStoreProvider.overrideWithValue(store),
            savedGameProvider.overrideWithValue(
              SaveData(
                theory: _mitAllenLektionen(),
                habits: const HabitTracker.empty(),
              ),
            ),
            todayProvider.overrideWithValue(tag),
          ],
          child: const SaveWatcher(child: LifesGameApp()),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LifesGameApp)),
      );
      container.read(loadoutProvider.notifier).buy(itemId);
      await tester.pump();

      final gespeichert = await store.read();
      expect(gespeichert.loadout.isOwned(itemId), isTrue);
    });
  });
}

/// Ein Fortschritt, der genug Gold eingebracht hat, um etwas zu kaufen.
TheoryProgress _mitAllenLektionen() {
  var progress = const TheoryProgress.empty();
  for (final branch in theoryTree.branches) {
    for (final lesson in branch.lessons) {
      progress = progress.submit(lesson, <int?>[
        for (final question in lesson.questions) question.correctIndex,
      ]).progress;
    }
  }
  return progress;
}
