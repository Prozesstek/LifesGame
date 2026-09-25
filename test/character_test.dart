import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/character/widgets/ability_slots_row.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/gear/gear_icon.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/ui/holz.dart';
import 'package:lifes_game/ui/pixel_art.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';
import 'gear_helpers.dart';

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
      expect(find.byType(HolzBalken), findsOneWidget);
    });

    testWidgets('ein frischer Charakter hat einen leeren Balken', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final bar = tester.widget<HolzBalken>(find.byType(HolzBalken));

      expect(bar.value, 0.0);
    });
  });

  group('Die Fähigkeiten sind ausgezogen', () {
    testWidgets('der Charakter zeigt keine Plätze mehr', (tester) async {
      // **Sie standen bis zum 25.09. hier** (ADR-0049). Der Abschnitt
      // ist weg, und mit ihm die vier Plätze — nachzuprüfen an dem,
      // was ein leerer Platz beschriftet war.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.byType(AbilitySlotsRow), findsNothing);
      expect(find.text('ab Level 3'), findsNothing);
    });

    testWidgets('der Weg dorthin bleibt trotzdem', (tester) async {
      // Wer seinen Charakter ansieht, sucht sie hier — der Kreis auf
      // der Startseite hilft ihm dabei nicht.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.scrollUntilVisible(
        find.text('Zu den Fähigkeiten'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Zu den Fähigkeiten'));
      await tester.pumpAndSettle();

      expect(find.byType(AbilitiesScreen), findsOneWidget);
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
        // **Mit der höchsten Sprosse.** Ohne sie greift seit ADR-0034 die
        // Sperre, und die drei verdienten Waffen fehlen still im Blatt.
        loadout = loadout.buy(
          angebot(item.id),
          availableGold: item.price,
          highestRung: GearGates.legendaryRung,
        );
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

    testWidgets('das Auswahlblatt zeigt Bild und Set jedes Stücks', (
      tester,
    ) async {
      // **Wer wählt, soll das Stück erkennen** — und wissen, ob das
      // Ablegen ein Set kostet. Der Kurzbogen hat ein Bild und gehört zu
      // „Ruhiger Stand"; die Geschliffene Klinge hat ein Bild und kein
      // Set. Beides kommt aus dem Katalog, nicht aus diesem Test.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitBeidenWaffen()));

      await tester.tap(find.text('Waffe'));
      await tester.pumpAndSettle();

      final mitBild = GearCatalog.all.where(
        (i) => i.slot == GearSlot.waffe && GearIcons.forItemId(i.id) != null,
      );
      expect(mitBild, isNotEmpty, reason: 'Der Test braucht ein Bild');
      expect(
        find.byType(PixelArt),
        findsAtLeastNWidgets(mitBild.length),
        reason: 'Jedes Stück mit Bild zeigt es im Blatt',
      );

      final mitSet = GearCatalog.all.where(
        (i) => i.slot == GearSlot.waffe && i.setId != null,
      );
      for (final item in mitSet) {
        final set = GearSets.byId(item.setId)!;
        expect(find.text('Teil von „${set.name}"'), findsWidgets);
      }
      final ohneSet = GearCatalog.all.where(
        (i) => i.slot == GearSlot.waffe && i.setId == null,
      );
      expect(ohneSet, isNotEmpty);
      // Ein Stück ohne Set bekommt keine leere Set-Zeile.
      expect(find.text('Teil von „"'), findsNothing);
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
      // der Titel bleibt trotzdem tragbar -- das ist der Grund, warum die
      // Bedingung an longestStreak haengt und nicht an der laufenden
      // Kette (konzept.md 3.7). Seit ADR-0033 steht sie im
      // Errungenschaftskatalog statt in `package:identity`.
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(mitStreak(5)),
          todayProvider.overrideWithValue(tag.next.next.next.next.next.next),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(achievementStatsProvider);
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
