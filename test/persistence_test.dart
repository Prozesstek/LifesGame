import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/identity_controller.dart';
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

  /// Ein Stand mit [tage] Tagen ununterbrochener Kette — genug, um den
  /// ersten Titel zu verdienen.
  SaveData mitStreak(int tage) {
    var tracker = const HabitTracker.empty().activate(habitId);
    var day = tag;
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(habitId, day).tracker;
      day = day.next;
    }
    return SaveData(habits: tracker);
  }

  group('Die gewählten Fähigkeiten überleben einen Neustart', () {
    testWidgets('was gewählt wurde, landet im Speicher', (tester) async {
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
      container
          .read(chosenAbilitiesProvider.notifier)
          .choose(0, Moves.heavyAttack.id);
      await tester.pump();

      // Der eigentliche Test: SaveWatcher hat den fünften Bereich
      // eingetragen. Ohne ihn funktionierte alles, nur gespeichert würde
      // nichts.
      final gespeichert = await store.read();
      expect(gespeichert.abilities.moveIds, <String>[Moves.heavyAttack.id]);
    });

    testWidgets('ein geräumter Platz bleibt geräumt', (tester) async {
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
      final notifier = container.read(chosenAbilitiesProvider.notifier);
      notifier.choose(0, Moves.mend.id);
      await tester.pump();
      notifier.clear(0);
      await tester.pump();

      final gespeichert = await store.read();
      expect(gespeichert.abilities.isEmpty, isTrue);
    });

    test('ein Stand aus der Zeit vor ADR-0017 lädt trotzdem', () {
      // Ein alter Spielstand hat den Abschnitt nicht. Er darf deswegen
      // nicht verloren gehen (ADR-0010).
      final alt = SaveData.fromJson(<String, Object?>{
        'habits': const HabitTracker.empty().activate(habitId).toJson(),
      });

      expect(alt.abilities.isEmpty, isTrue);
      expect(alt.habits.isActive(habitId), isTrue);
    });

    test('der Waffenslot überlebt als Ableitung, nicht als Wert', () {
      // Slot 1 steht bewusst nicht im Spielstand: Er folgt aus der
      // getragenen Waffe (ADR-0017). Nach einem Neustart muss er trotzdem
      // dastehen.
      final container = containerMit(
        const SaveData.empty(),
        InMemorySaveStore(),
      );

      final move = container.read(weaponMoveProvider);

      expect(move.id, AbilityCatalog.fallbackMoveId);
      expect(
        container.read(chosenAbilitiesProvider).contains(move.id),
        isFalse,
      );
    });
  });

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

    test('Name und Titel kommen wieder', () {
      final store = InMemorySaveStore();
      final erste = containerMit(mitStreak(3), store);

      erste.read(identityProvider.notifier).setName('Frederik');
      erste.read(identityProvider.notifier).chooseTitle('entschlossen');

      final stand = SaveData(
        habits: erste.read(habitTrackerProvider),
        identity: erste.read(identityProvider),
      );

      final zweite = containerMit(SaveData.decode(stand.encode()), store);
      final identity = zweite.read(identityProvider);

      expect(identity.name, 'Frederik');
      expect(identity.chosenTitleId, 'entschlossen');
      expect(
        identity.displayLine(zweite.read(titleStatsProvider)),
        'Frederik, der Entschlossene',
      );
    });

    test('ein unverdienter Titel im Stand wird nicht getragen', () {
      // Der Stand ist nur eine Wahl, kein Nachweis: Ein von Hand
      // bearbeiteter Spielstand bringt keinen Titel ein (ADR-0013).
      final container = containerMit(
        const SaveData(identity: Identity(chosenTitleId: 'unbeirrbar')),
        InMemorySaveStore(),
      );

      final identity = container.read(identityProvider);
      final stats = container.read(titleStatsProvider);

      expect(identity.chosenTitleId, 'unbeirrbar');
      expect(identity.titleFor(stats), isNull);
      expect(identity.displayLine(stats), 'Namenlos');
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
