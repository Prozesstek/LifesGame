import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Prüft Name und Titel auf dem Charakterbildschirm.
///
/// Der interessante Teil ist nicht die Eingabe, sondern die Bedingung: Ein
/// Titel darf nur wählbar sein, wenn er verdient ist (ADR-0013). Das lässt
/// sich nur hier prüfen, weil erst hier Gewohnheiten, Theorie und Titel
/// zusammenkommen.
void main() {
  const habitId = 'habit-drei-aufgaben';
  const tag = Day(2026, 8, 17);

  /// Ein Stand mit [tage] Tagen ununterbrochener Kette.
  SaveData mitStreak(int tage) {
    var tracker = const HabitTracker.empty().activate(habitId);
    var day = tag;
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(habitId, day).tracker;
      day = day.next;
    }
    return SaveData(habits: tracker);
  }

  Widget appMit(SaveData saved) {
    return ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        todayProvider.overrideWithValue(tag),
      ],
      child: const MaterialApp(home: CharacterScreen()),
    );
  }

  group('Der Name', () {
    testWidgets('ohne Eingabe steht der Platzhalter', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.text('Namenlos'), findsOneWidget);
      expect(find.text('Name geben'), findsOneWidget);
    });

    testWidgets('eingeben und der Bildschirm zeigt ihn', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Name geben'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Frederik');
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      expect(find.text('Frederik'), findsOneWidget);
      expect(find.text('Namenlos'), findsNothing);
      // Aus „Name geben" wird „Name ändern", sobald einer da ist.
      expect(find.text('Name ändern'), findsOneWidget);
    });

    testWidgets('Abbrechen ändert nichts', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Name geben'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Wirdverworfen');
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.text('Namenlos'), findsOneWidget);
      expect(find.text('Wirdverworfen'), findsNothing);
    });
  });

  group('Der Titel', () {
    testWidgets('ein frischer Charakter hat keinen verdient', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();

      // Gesperrte Titel bleiben sichtbar und nennen ihre Bedingung.
      expect(find.text('der Entschlossene'), findsOneWidget);
      expect(find.textContaining('3 Tage am Stück — noch 3'), findsOneWidget);
    });

    testWidgets('ein gesperrter Titel lässt sich nicht wählen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();

      // Der Dialog steht noch, es wurde nichts gewählt.
      expect(find.text('Titel wählen'), findsOneWidget);
    });

    testWidgets('ein verdienter Titel steht neben dem Namen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      await tester.tap(find.text('Name geben'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Brett');
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();

      expect(find.text('Brett'), findsOneWidget);
      expect(find.textContaining('der Entschlossene'), findsOneWidget);
    });

    testWidgets('Titel wieder ablegen geht', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();
      expect(find.textContaining('der Entschlossene'), findsOneWidget);

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kein Titel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('der Entschlossene'), findsNothing);
    });
  });

  group('Beständigkeit', () {
    testWidgets('ein frischer Charakter wird nicht mit Nullen begrüßt', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.text('Beständigkeit'), findsOneWidget);
      expect(
        find.text('Noch kein Häkchen. Der erste Tag ist der ganze Trick.'),
        findsOneWidget,
      );
    });

    testWidgets('die laufende Kette steht auf dem Bildschirm', (tester) async {
      useTallView(tester);
      // mitStreak hakt ab `tag` **vorwärts** ab. Heute muss deshalb der
      // letzte abgehakte Tag sein, sonst läuft die Kette erst einen Tag.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(mitStreak(5)),
            todayProvider.overrideWithValue(tag.next.next.next.next),
          ],
          child: const MaterialApp(home: CharacterScreen()),
        ),
      );

      expect(find.text('5'), findsWidgets);
      expect(find.text('Tage am Stück'), findsOneWidget);
      expect(find.text('So beständig warst du noch nie.'), findsOneWidget);
    });

    testWidgets('eine gerissene Kette liest sich nicht wie ein Verlust', (
      tester,
    ) async {
      useTallView(tester);
      // Genau der Fall, für den die zweite Zahl da ist: laufende Kette 0,
      // Bestwert 5. Ohne den Satz darunter läse sich das wie ein
      // Rückschritt -- und das Konzept schließt Strafe fürs Verpassen aus
      // (3.7).
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(mitStreak(5)),
            todayProvider.overrideWithValue(
              tag.next.next.next.next.next.next.next,
            ),
          ],
          child: const MaterialApp(home: CharacterScreen()),
        ),
      );

      expect(
        find.text(
          'Die Kette ruht gerade. Der Bestwert bleibt — verpasste Tage '
          'nehmen nichts weg.',
        ),
        findsOneWidget,
      );
      expect(find.text('Bestwert'), findsOneWidget);
    });

    testWidgets('der Abstand zum Bestwert wird genannt', (tester) async {
      useTallView(tester);
      // Vier Tage gelaufen, dann Pause, dann zwei neue Tage: Bestwert 4,
      // laufend 2.
      var tracker = const HabitTracker.empty().activate(habitId);
      var day = tag;
      for (var i = 0; i < 4; i++) {
        tracker = tracker.check(habitId, day).tracker;
        day = day.next;
      }
      final neuerStart = day.next.next;
      tracker = tracker.check(habitId, neuerStart).tracker;
      tracker = tracker.check(habitId, neuerStart.next).tracker;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
            todayProvider.overrideWithValue(neuerStart.next),
          ],
          child: const MaterialApp(home: CharacterScreen()),
        ),
      );

      expect(find.text('Noch 2 Tage bis zum Bestwert.'), findsOneWidget);
    });
  });

  group('Der Levelbalken', () {
    testWidgets('zeigt, wie weit es bis zum nächsten Level ist', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(mitStreak(3)),
          todayProvider.overrideWithValue(tag),
        ],
      );
      addTearDown(container.dispose);
      final level = container.read(playerLevelProvider);

      // Die Zahlen kommen aus package:progression -- der Bildschirm rechnet
      // sie nicht nach, er zeigt sie nur.
      expect(
        find.text(
          '${level.xpIntoLevel} / ${level.xpForLevel} bis Level '
          '${level.level + 1}',
        ),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('ein frischer Charakter hat einen leeren Balken', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(bar.value, 0.0);
    });
  });

  group('Die Fähigkeitsslots', () {
    /// Ein Stand, der auf [level] steht. Erfahrung kommt aus Häkchen —
    /// gerechnet wird sie in `package:progression`, hier wird nur genug
    /// davon erzeugt.
    /// Ein Fortschritt, in dem die vier Körperknoten bestanden sind.
    ///
    /// **Seit ADR-0019 hängt jede wählbare Fähigkeit an einem Knoten.**
    /// Ohne Theoriefortschritt gäbe es nichts, was in einen freien Platz
    /// passt — diese Tests wollen aber die Plätze prüfen, nicht das
    /// Freischalten.
    TheoryProgress mitKnoten() {
      var progress = const TheoryProgress.empty();
      for (final ability in AbilityCatalog.choosable) {
        if (ability.source case FromTheory(:final nodeId)) {
          final lesson = theoryGraph.nodeById(nodeId)!.lesson;
          progress = progress.submit(lesson, <int?>[
            for (final q in lesson.questions) q.correctIndex,
          ]).progress;
        }
      }
      return progress;
    }

    SaveData aufLevel(
      int level, {
      Loadout? loadout,
      ChosenAbilities? abilities,
    }) {
      final theory = mitKnoten();
      // Bestandene Seiten bringen selbst Erfahrung mit — sonst läge das
      // Level über dem gewünschten und es wären mehr Plätze offen.
      final noetig = LevelCurve.totalXpFor(level) - theory.totalXp;
      var tracker = const HabitTracker.empty().activate(habitId);
      var day = tag;
      while (tracker.totalXp < noetig) {
        tracker = tracker.check(habitId, day).tracker;
        day = day.next;
      }
      return SaveData(
        theory: theory,
        habits: tracker,
        loadout: loadout ?? const Loadout.empty(),
        abilities: abilities ?? const ChosenAbilities.empty(),
      );
    }

    testWidgets('auf Level 1 ist nur der Waffenplatz offen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.text('Fähigkeiten'), findsOneWidget);
      // Drei gesperrte Plätze nennen ihre Stufe, statt zu fehlen.
      expect(find.text('ab Level 3'), findsOneWidget);
      expect(find.text('ab Level 6'), findsOneWidget);
      expect(find.text('ab Level 10'), findsOneWidget);
    });

    testWidgets('ohne Waffe trägt Slot 1 trotzdem etwas', (tester) async {
      // Der wichtigste Fall: Auf Level 1 ist Slot 1 der einzige offene.
      // Wäre er leer, hätte ein frischer Charakter keinen einzigen Move.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final rueckfall = Moves.byId(AbilityCatalog.fallbackMoveId)!;
      expect(find.text(rueckfall.name), findsOneWidget);
    });

    testWidgets('Slot 1 zeigt die Fähigkeit der Waffe, nicht die Waffe', (
      tester,
    ) async {
      useTallView(tester);
      final klinge = GearCatalog.all.firstWhere(
        (i) => i.slot == GearSlot.waffe,
      );
      final loadout = const Loadout.empty().buy(
        klinge.id,
        availableGold: klinge.price,
      );

      await tester.pumpWidget(appMit(aufLevel(1, loadout: loadout)));

      final move = Moves.byId(AbilityCatalog.weaponMoves[klinge.id]!)!;
      // Der Waffenname steht auf dem Ausrüstungsplatz, der Move-Name im
      // Fähigkeitsslot — zwei verschiedene Dinge.
      expect(find.text(move.name), findsOneWidget);
      expect(find.text(klinge.name), findsOneWidget);
    });

    testWidgets('auf Level 3 geht der zweite Platz auf', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));

      expect(find.text('ab Level 3'), findsNothing);
      expect(find.text('ab Level 6'), findsOneWidget);
      expect(find.text('leer'), findsOneWidget);
      expect(find.textContaining('Ein Platz ist noch frei'), findsOneWidget);
    });

    testWidgets('auf Level 10 sind alle vier offen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      expect(find.textContaining('ab Level'), findsNothing);
      // Drei freie Plätze leer, der vierte trägt die Waffe.
      expect(find.text('leer'), findsNWidgets(AbilitySlots.total - 1));
      expect(find.textContaining('3 Plätze sind noch frei'), findsOneWidget);
    });

    testWidgets('ein gesperrter Platz lässt sich nicht antippen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('ab Level 3'));
      await tester.pumpAndSettle();

      expect(find.text('Fähigkeit wählen'), findsNothing);
    });

    testWidgets('der Waffenplatz lässt sich nicht antippen', (tester) async {
      // Slot 1 folgt aus der Ausrüstung, er ist keine Wahl (ADR-0013).
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final rueckfall = Moves.byId(AbilityCatalog.fallbackMoveId)!;
      await tester.tap(find.text(rueckfall.name));
      await tester.pumpAndSettle();

      expect(find.text('Fähigkeit wählen'), findsNothing);
    });

    testWidgets('einen freien Platz belegen und der Slot zeigt es', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));

      await tester.tap(find.text('leer'));
      await tester.pumpAndSettle();
      expect(find.text('Fähigkeit wählen'), findsOneWidget);

      await tester.tap(find.text(AbilityMoves.funkenstoss.name).last);
      await tester.pumpAndSettle();

      expect(find.text(AbilityMoves.funkenstoss.name), findsOneWidget);
      expect(find.text('leer'), findsNothing);
    });

    testWidgets('einen Platz räumen macht ihn wieder leer', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(
          aufLevel(
            3,
            abilities: const ChosenAbilities.empty().withAt(
              0,
              AbilityMoves.bluetentau.id,
            ),
          ),
        ),
      );

      expect(find.text(AbilityMoves.bluetentau.name), findsOneWidget);

      await tester.tap(find.text(AbilityMoves.bluetentau.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Platz räumen'));
      await tester.pumpAndSettle();

      expect(find.text('leer'), findsOneWidget);
    });

    testWidgets('nur die offenen Plätze gehen in den Kampf', (tester) async {
      // Der eigentliche Zweck der Verkabelung: Was gewählt ist, wirkt sich
      // aus — aber nur so weit, wie Plätze offen sind (ADR-0016).
      useTallView(tester);
      final saved = aufLevel(
        3,
        abilities: const ChosenAbilities.empty()
            .withAt(0, AbilityMoves.funkenstoss.id)
            .withAt(1, AbilityMoves.bluetentau.id),
      );

      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(saved),
          todayProvider.overrideWithValue(tag),
        ],
      );
      addTearDown(container.dispose);

      final moves = container.read(activeMovesProvider);

      // Level 3: Waffenslot plus genau ein freier Platz.
      expect(moves, hasLength(2));
      expect(moves.last.id, AbilityMoves.funkenstoss.id);
    });
  });

  group('Das Ausrüstungsraster', () {
    /// Beide Waffen gekauft — damit gibt es auf einem Platz wirklich
    /// etwas zu wählen. Gekauft wird angelegt, die Klinge liegt also drauf.
    SaveData mitBeidenWaffen() {
      var loadout = const Loadout.empty();
      for (final item in GearCatalog.all.where(
        (i) => i.slot == GearSlot.waffe,
      )) {
        loadout = loadout.buy(item.id, availableGold: item.price);
      }
      return SaveData(loadout: loadout);
    }

    testWidgets('alle sechs Plätze sind sichtbar, auch die leeren', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      for (final slot in GearSlot.values) {
        expect(find.text(slot.label), findsOneWidget);
      }
      // Ohne Gekauftes sagt jede Kachel, warum sie leer ist.
      expect(
        find.text('nichts gekauft'),
        findsNWidgets(GearSlot.values.length),
      );
    });

    testWidgets('ein leerer Platz ohne Auswahl lässt sich nicht antippen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Waffe'));
      await tester.pumpAndSettle();

      // Kein Auswahlblatt: Ein Blatt ohne Einträge wäre eine Sackgasse.
      expect(find.text('Ablegen'), findsNothing);
    });

    testWidgets('antippen öffnet die Auswahl und wechselt das Stück', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitBeidenWaffen()));

      await tester.tap(find.text('Waffe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Übungsklinge').last);
      await tester.pumpAndSettle();

      // Einmal: auf dem Ausrüstungsplatz. Im Fähigkeitsslot steht seit
      // ADR-0017 der Name der *Fähigkeit*, nicht der der Waffe.
      expect(find.text('Übungsklinge'), findsOneWidget);
      expect(find.text('Geschliffene Klinge'), findsNothing);
    });

    testWidgets('Ablegen räumt den Platz', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitBeidenWaffen()));

      await tester.tap(find.text('Waffe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablegen'));
      await tester.pumpAndSettle();

      // Der Platz ist leer, aber nicht „nichts gekauft" -- es liegt nur
      // nichts drauf.
      expect(find.text('leer'), findsOneWidget);
      expect(find.text('Geschliffene Klinge'), findsNothing);
    });

    testWidgets('ein belegter Platz zahlt auf die Werte ein', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitBeidenWaffen()));

      // Die Herkunft der Zahl ist der Zweck des ganzen Bildschirms: Die
      // Klinge muss in „Werte im Kampf" als Ausrüstung auftauchen.
      expect(find.textContaining('Ausrüstung'), findsWidgets);
    });
  });

  group('Verdient bleibt verdient', () {
    test('eine gerissene Kette nimmt den Titel nicht weg', () {
      // Fünf Tage Kette, dann eine Woche Pause. Die laufende Streak ist 0,
      // der Titel bleibt trotzdem tragbar -- das ist der Grund, warum
      // titleStatsProvider longestStreak hereinreicht (konzept.md 3.7).
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(mitStreak(5)),
          todayProvider.overrideWithValue(tag.next.next.next.next.next.next),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(titleStatsProvider);
      final earned = container.read(earnedTitlesProvider);

      expect(
        container
            .read(habitTrackerProvider)
            .currentStreak(habitId, tag.next.next.next.next.next.next),
        0,
      );
      expect(stats.longestStreak, 5);
      expect(earned.map((t) => t.id), contains('entschlossen'));
    });
  });
}
