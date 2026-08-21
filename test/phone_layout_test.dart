import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    var tracker = const HabitTracker.empty();
    for (final template in HabitCatalog.all.take(5)) {
      tracker = tracker.activate(template.id);
    }

    return SaveData(theory: progress, habits: tracker);
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

        expect(tester.takeException(), isNull);
      });
    }

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
