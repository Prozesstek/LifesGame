import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:progression/progression.dart';
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
    SaveData aufLevel(int level, {Loadout? loadout}) {
      final noetig = LevelCurve.totalXpFor(level);
      var tracker = const HabitTracker.empty().activate(habitId);
      var day = tag;
      while (tracker.totalXp < noetig) {
        tracker = tracker.check(habitId, day).tracker;
        day = day.next;
      }
      return SaveData(
        habits: tracker,
        loadout: loadout ?? const Loadout.empty(),
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
      expect(find.text('keine Waffe'), findsOneWidget);
    });

    testWidgets('der gesperrte Platz nennt sein Ziel', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.textContaining('Nächster Platz ab Level 3'), findsOneWidget);
    });

    testWidgets('auf Level 3 geht der zweite Platz auf', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));

      expect(find.text('ab Level 3'), findsNothing);
      expect(find.text('leer'), findsOneWidget);
      expect(find.text('ab Level 6'), findsOneWidget);
      expect(find.textContaining('Nächster Platz ab Level 6'), findsOneWidget);
    });

    testWidgets('auf Level 10 sind alle vier offen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      expect(find.textContaining('ab Level'), findsNothing);
      // Drei freie Plätze leer, der vierte trägt die Waffe.
      expect(find.text('leer'), findsNWidgets(AbilitySlots.total - 1));
      expect(find.textContaining('Alle vier Plätze offen'), findsOneWidget);
    });

    testWidgets('der Waffenplatz zeigt, was getragen wird', (tester) async {
      useTallView(tester);
      final klinge = GearCatalog.all.firstWhere(
        (i) => i.slot == GearSlot.waffe,
      );
      var loadout = const Loadout.empty();
      loadout = loadout.buy(klinge.id, availableGold: klinge.price);

      await tester.pumpWidget(appMit(aufLevel(1, loadout: loadout)));

      expect(find.text('keine Waffe'), findsNothing);
      expect(find.text(klinge.name), findsNWidgets(2));
    });

    testWidgets('dass die Fähigkeiten noch fehlen, steht da', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      // Ohne diesen Satz sähe ein leerer Platz wie ein Fehler aus.
      expect(
        find.textContaining('Die Fähigkeiten selbst kommen noch'),
        findsOneWidget,
      );
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

      // Zweimal: einmal auf dem Ausrüstungsplatz, einmal im
      // Waffen-Fähigkeitsslot. Genau das ist die Aussage von ADR-0013 --
      // was in Slot 1 liegt, ist keine Wahl, sondern folgt aus der Waffe.
      expect(find.text('Übungsklinge'), findsNWidgets(2));
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
