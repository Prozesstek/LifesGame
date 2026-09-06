import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/combat/combat_screen.dart';
import 'package:lifes_game/combat/enemy_picker_screen.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Prüft jeden Bildschirm im Zielformat: Handy, Hochformat, 390x844.
///
/// **Warum das ein eigener Test ist.** Die übrigen Widget-Tests laufen im
/// hohen Fenster, damit lange Listen vollständig gebaut werden. Sie prüfen
/// damit *Inhalt*, aber nie die **Breite** — und schmal ist genau die
/// Richtung, in der ein Layout bricht. Ein Überlauf ist in Flutter ein
/// Fehler; er lässt diesen Test von selbst fehlschlagen, ohne dass hier
/// eine Zusicherung dafür stehen muss.
///
/// Der Anlass steht in `docs/context/gotchas.md`: Ein `GridView` mit
/// `childAspectRatio` hatte auf breiten Fenstern eine ganze Knopfreihe
/// verschluckt. Dieselbe Sorte Fehler gibt es in schmal.
/// Wie oft ein Bildschirm nach unten gezogen wird. Zehn mal 400 Pixel
/// reichen für den längsten (Laden) mit Abstand.
const int _scrollSchritte = 10;

void main() {
  /// Ein Stand mit Fortschritt — leere Bildschirme haben nichts, was
  /// überlaufen könnte, und würden nichts beweisen.
  SaveData mitInhalt() {
    var progress = const TheoryProgress.empty();
    for (final branch in theoryTree.branches) {
      for (final lesson in branch.lessons) {
        progress = progress.submit(lesson, <int?>[
          for (final question in lesson.questions) question.correctIndex,
        ]).progress;
      }
    }

    // Vier Vorlagen plus eine eigene: Die eigene ist die vollste Kachel,
    // die es gibt — Ziel, Schwierigkeit und Priorität stehen zusätzlich
    // in einer eigenen Zeile, und neben dem Namen sitzen dann **zwei**
    // Knöpfe statt einem. Die zweite wartet unter „Eigene" und prüft
    // damit auch die ruhende Kachel.
    var tracker = const HabitTracker.empty();
    for (final template in HabitCatalog.all.take(4)) {
      tracker = tracker.activate(template.id);
    }
    tracker = tracker
        .addCustom(
          CustomHabit(
            id: 'eigen-1',
            name: 'Fünf Gläser Wasser über den Tag verteilt trinken',
            stat: HabitStat.ausdauer,
            difficulty: HabitDifficulty.schwer,
            goal: HabitGoal.menge(target: 5, unit: 'Gläser'),
            priority: HabitPriority.hoch,
          ),
          slots: 5,
        )
        .addCustom(
          const CustomHabit(
            id: 'eigen-2',
            name: 'Zwanzig Minuten Krafttraining am Abend',
            stat: HabitStat.staerke,
            difficulty: HabitDifficulty.leicht,
            priority: HabitPriority.niedrig,
            why: 'Weil der Abend sonst im Sessel endet und nichts bleibt.',
          ),
          slots: 5,
        )
        .activate('eigen-1');

    // Jeder Platz belegt. Ein leeres Ausrüstungsraster zeigt sechsmal
    // „leer" -- die echten Namen sind das, was in der schmalen Kachel
    // überläuft, und „Schuppenpanzer" ist der längste davon.
    var loadout = const Loadout.empty();
    for (final item in GearCatalog.all) {
      loadout = loadout.buy(item.id, availableGold: item.price);
    }

    return SaveData(theory: progress, habits: tracker, loadout: loadout);
  }

  Widget appMit(Widget screen) {
    return ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(mitInhalt()),
        todayProvider.overrideWithValue(const Day(2026, 8, 21)),
      ],
      child: MaterialApp(home: screen),
    );
  }

  final screens = <String, Widget>{
    'Start': const HomeScreen(),
    'Skillbaum': const SkillTreeScreen(),
    'Gewohnheiten': const HabitsScreen(),
    'Laden': const ShopScreen(),
    'Charakter': const CharacterScreen(),
    'Gegnerwahl': const EnemyPickerScreen(),
  };

  group('Jeder Bildschirm passt aufs Handy', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} läuft im Hochformat nicht über', (
        tester,
      ) async {
        usePhoneView(tester);
        await tester.pumpWidget(appMit(entry.value));
        await tester.pumpAndSettle();

        // **Einmal durchscrollen, und das ist der Punkt.** Ohne den
        // Scroll prüft dieser Test nur, was über der Falz liegt: Was in
        // einer `ListView` unterhalb steht, wird gar nicht erst gebaut —
        // und was nicht gebaut wird, kann auch nicht überlaufen. Auf 844
        // Pixeln Höhe ist das der größere Teil jedes Bildschirms.
        for (var i = 0; i < _scrollSchritte; i++) {
          await tester.drag(find.byType(Scaffold), const Offset(0, -400));
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('das Formular für eine eigene Gewohnheit passt', (
      tester,
    ) async {
      // Der längste neue Bildschirm: vier Wertekacheln, drei
      // Schwierigkeiten mit Prozentangabe, drei Zielarten, drei
      // Prioritäten und vier Eingabefelder. Die engste Stelle sind die
      // Werte-Kacheln — „Lebenspunkte" neben „Ausdauer" in einem Chip.
      usePhoneView(tester);
      await tester.pumpWidget(appMit(const HabitsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.playlist_add),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();

      // Beide Zielarten aufklappen — sie bringen je zusätzliche Felder
      // mit, und aufgeklappt ist das Blatt am höchsten.
      for (final art in <String>['Menge', 'Zeit']) {
        await tester.tap(find.text(art));
        await tester.pumpAndSettle();
      }

      for (var i = 0; i < _scrollSchritte; i++) {
        await tester.drag(
          find.text('Eigene Gewohnheit'),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Skillbaum läuft auch eine Ebene tiefer nicht über', (
      tester,
    ) async {
      // Der Bildschirm oben zeigt nur die Wurzel. Eine Ebene tiefer
      // stehen **zusätzlich** die Elternleiste und der größere
      // Startknoten — das ist die vollste Fassung, und die engste
      // Stelle ist der Handlungsknopf zwischen beiden (ADR-0026).
      usePhoneView(tester);
      await tester.pumpWidget(appMit(const SkillTreeScreen()));
      await tester.pumpAndSettle();

      final kind = theoryGraph.childrenOf(theoryRootIds.first).first;
      await tester.tap(find.text(kind.name));
      await tester.pumpAndSettle();

      expect(find.textContaining('Zurück zu'), findsOneWidget);

      for (var i = 0; i < _scrollSchritte; i++) {
        await tester.drag(find.byType(Scaffold), const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Charakter läuft auch ohne Fortschritt nicht über', (
      tester,
    ) async {
      // Der Gegenfall zu oben: `mitInhalt` steht auf hohem Level, dort
      // sind alle Fähigkeitsslots offen und sagen kurz „leer". Gesperrt
      // sagen sie „ab Level 10" — die breiteste Beschriftung, die in die
      // schmalste Kachel muss. Vier Slots auf 390 Pixeln ist die engste
      // Stelle des Bildschirms.
      usePhoneView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(const SaveData.empty()),
            todayProvider.overrideWithValue(const Day(2026, 8, 21)),
          ],
          child: const MaterialApp(home: CharacterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Hinscrollen ist hier kein Beiwerk, sondern der Kern: Was in einer
      // `ListView` unterhalb der Falz liegt, wird nicht gebaut -- und was
      // nicht gebaut wird, kann auch nicht überlaufen. Ohne den Scroll
      // prüfte dieser Test nichts (`test/test_view.dart`).
      await tester.dragUntilVisible(
        find.text('ab Level 10'),
        find.byType(ListView),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('ab Level 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kampf läuft im Hochformat nicht über', (tester) async {
      // Eigener Fall: Wo ein Flame-Widget im Baum hängt, gibt es nie einen
      // Frame, nach dem nichts mehr aussteht — `pumpAndSettle` liefe in
      // den Timeout (`docs/context/gotchas.md`).
      usePhoneView(tester);
      await tester.pumpWidget(appMit(const CombatScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}
