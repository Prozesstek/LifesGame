import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/character/widgets/ability_slots_row.dart';
import 'package:lifes_game/character/widgets/equipment_slot_tile.dart';
import 'package:lifes_game/character/widgets/set_card.dart';
import 'package:lifes_game/gear/equipment_screen.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/ui/holz.dart';
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
      expect(find.bySemanticsLabel('Name geben'), findsOneWidget);
    });

    testWidgets('eingeben und der Bildschirm zeigt ihn', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.bySemanticsLabel('Name geben'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Frederik');
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      expect(find.text('Frederik'), findsOneWidget);
      expect(find.text('Namenlos'), findsNothing);
      // Aus „Name geben" wird „Name ändern", sobald einer da ist.
      expect(find.bySemanticsLabel('Name ändern'), findsOneWidget);
    });

    testWidgets('Abbrechen ändert nichts', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.bySemanticsLabel('Name geben'));
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

      await tester.tap(find.byIcon(Icons.military_tech_outlined));
      await tester.pumpAndSettle();

      // Gesperrte Titel bleiben sichtbar und nennen ihre Bedingung.
      expect(find.text('der Entschlossene'), findsOneWidget);
      expect(find.textContaining('3 Tage am Stück — noch 3'), findsOneWidget);
    });

    testWidgets('ein gesperrter Titel lässt sich nicht wählen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.byIcon(Icons.military_tech_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();

      // Der Dialog steht noch, es wurde nichts gewählt.
      expect(find.text('Titel wählen'), findsOneWidget);
    });

    testWidgets('ein verdienter Titel steht neben dem Namen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      await tester.tap(find.bySemanticsLabel('Name geben'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Brett');
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.military_tech_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();

      expect(find.text('Brett'), findsOneWidget);
      expect(find.textContaining('der Entschlossene'), findsOneWidget);
    });

    testWidgets('Titel wieder ablegen geht', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      await tester.tap(find.byIcon(Icons.military_tech_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();
      expect(find.textContaining('der Entschlossene'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.military_tech_outlined));
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

      expect(
        find.byTooltip('Noch kein Häkchen. Der erste Tag ist der ganze Trick.'),
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
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byTooltip('So beständig warst du noch nie.'), findsOneWidget);
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
        find.byTooltip(
          'Die Kette ruht gerade. Der Bestwert bleibt — verpasste Tage '
          'nehmen nichts weg.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
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

      expect(find.byTooltip('Noch 2 Tage bis zum Bestwert.'), findsOneWidget);
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
        find.text('${level.xpIntoLevel} / ${level.xpForLevel}'),
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
        find.bySemanticsLabel('Zu den Fähigkeiten'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.bySemanticsLabel('Zu den Fähigkeiten'));
      await tester.pumpAndSettle();

      expect(find.byType(AbilitiesScreen), findsOneWidget);
    });
  });

  group('Die Ausrüstung ist ausgezogen', () {
    /// Eine Waffe gekauft und angelegt.
    SaveData mitWaffe() {
      final item = GearCatalog.forSlot(GearSlot.waffe).first;
      return SaveData(
        loadout: const Loadout.empty().buy(
          angebot(item.id),
          availableGold: item.price,
        ),
      );
    }

    testWidgets('der Charakter zeigt keine Plätze mehr', (tester) async {
      // **Sie standen bis zum 28.09. hier** (ADR-0057), die Tests dazu
      // stehen jetzt in `equipment_screen_test.dart`.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitWaffe()));

      expect(find.byType(EquipmentSlotTile), findsNothing);
      expect(find.byType(SetCard), findsNothing);
    });

    testWidgets('der Weg dorthin bleibt', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Zur Ausrüstung'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.bySemanticsLabel('Zur Ausrüstung'));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentScreen), findsOneWidget);
    });

    testWidgets('was sie bringt, steht weiter bei den Werten', (tester) async {
      // **Die Herkunft der Zahl ist der Zweck dieses Bildschirms.** Die
      // Plätze sind weg, der Beitrag der Waffe zu „Werte im Kampf" nicht.
      // Geprüft an der Zeile selbst: Seit es den Knopf „Zur Ausrüstung"
      // gibt, stünde das Wort auch ohne Beitrag auf dem Bildschirm.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitWaffe()));

      expect(find.byIcon(Icons.backpack_outlined), findsWidgets);
    });
  });

  group('Verdient bleibt verdient', () {
    test('eine gerissene Kette nimmt den Titel nicht weg', () {
      // Fuenf Tage Kette, dann eine Woche nichts. Seit ADR-0064 faellt die
      // Kette je verpasstem Tag eine Stufe (5 -> 3 -> 0) statt sofort auf
      // null; nach einer Woche steht sie bei 0. Der Titel bleibt trotzdem
      // tragbar -- das ist der Grund, warum die Bedingung an longestStreak
      // haengt und nicht an der laufenden Kette (konzept.md 3.7). Seit
      // ADR-0033 steht sie im Errungenschaftskatalog statt in
      // `package:identity`.
      var eineWocheSpaeter = tag;
      for (var i = 0; i < 12; i++) {
        eineWocheSpaeter = eineWocheSpaeter.next;
      }
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(mitStreak(5)),
          todayProvider.overrideWithValue(eineWocheSpaeter),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(achievementStatsProvider);
      final earned = container.read(earnedTitlesProvider);

      expect(
        container
            .read(habitTrackerProvider)
            .currentStreak(habitId, eineWocheSpaeter),
        0,
      );
      expect(stats.longestStreak, 5);
      expect(earned.map((t) => t.id), contains('entschlossen'));
    });
  });
}
