import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/ability_unlock.dart';
import 'package:lifes_game/character/widgets/ability_unlock_sheet.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/lesson_result_view.dart';
import 'package:lifes_game/action/pit_text.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Der Freischaltungsscreen (Issue #21, Punkt 7).
///
/// **Der Moment, auf den der ganze Baum hinarbeitet, fand nirgends
/// statt.** Eine Seite bestehen gab still eine Fähigkeit dazu; sehen
/// konnte man sie nur, wenn man von selbst nachsah.
void main() {
  /// Ein Knoten, dessen Seite eine Fähigkeit mitbringt.
  final knoten = theoryGraph.nodes.firstWhere((n) => n.unlocksAbility != null);

  group('Was neu ist', () {
    final a = AbilityCatalog.choosable[0];
    final b = AbilityCatalog.choosable[1];

    test('nichts dazugekommen heisst nichts zu feiern', () {
      expect(newlyUnlocked(before: <Ability>[a], after: <Ability>[a]), isEmpty);
    });

    test('was vorher fehlte, ist neu', () {
      expect(
        newlyUnlocked(
          before: <Ability>[a],
          after: <Ability>[a, b],
        ).map((x) => x.moveId),
        <String>[b.moveId],
      );
    });

    test('was wegfällt, wird nicht gefeiert', () {
      // Kann passieren: Eine Waffe ablegen nimmt ihre Fähigkeit mit.
      expect(
        newlyUnlocked(before: <Ability>[a, b], after: <Ability>[a]),
        isEmpty,
      );
    });
  });

  group('Wohin sie passt', () {
    test('auf Level 1 ist kein freier Platz — Slot 1 gehört der Waffe', () {
      expect(
        firstFreeSlot(chosen: const ChosenAbilities.empty(), level: 1),
        isNull,
      );
    });

    test('auf Level 3 geht der erste freie Platz auf', () {
      expect(firstFreeSlot(chosen: const ChosenAbilities.empty(), level: 3), 0);
    });

    test('ein belegter Platz schiebt den nächsten weiter', () {
      final chosen = const ChosenAbilities.empty().withAt(0, 'funkenstoss');

      expect(firstFreeSlot(chosen: chosen, level: 6), 1);
    });

    test('sind alle offenen belegt, ist keiner mehr frei', () {
      final chosen = const ChosenAbilities.empty().withAt(0, 'funkenstoss');

      expect(firstFreeSlot(chosen: chosen, level: 3), isNull);
    });

    test('und dann nennt der Screen die nächste Stufe', () {
      expect(nextSlotLevel(3), 6);
      expect(nextSlotLevel(10), isNull);
    });
  });

  group('Der Screen erscheint, wenn eine Seite sitzt', () {
    /// Ohne [abwarten] endet es einen Bildaufbau nach „Auswerten“.
    Future<void> bestehen(
      WidgetTester tester,
      ProviderContainer container, {
      bool abwarten = true,
    }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: LessonScreen(lesson: knoten.lesson)),
        ),
      );
      await tester.pump();

      await zuDenFragen(tester, knoten.lesson);

      for (var i = 0; i < knoten.lesson.questionCount; i++) {
        final frage = knoten.lesson.questions.firstWhere(
          (q) => find.text(q.prompt).evaluate().isNotEmpty,
        );

        await tester.tap(find.text(frage.options[frage.correctIndex]));
        await tester.pumpAndSettle();
        final letzte = i == knoten.lesson.questionCount - 1;
        await tester.tap(find.text(letzte ? 'Auswerten' : 'Weiter'));
        if (letzte && !abwarten) {
          await tester.pump();
        } else {
          await tester.pumpAndSettle();
        }
      }
    }

    testWidgets('die Feier wartet, bis Erfahrung und Gold gezählt sind', (
      tester,
    ) async {
      // Sonst deckte sie die Zahl zu, die sie gebracht hat — derselbe
      // Grund wie beim Häkchen, dessen Feier auf die Münzen wartet.
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await bestehen(tester, container, abwarten: false);
      await tester.pump(LessonResultView.zaehlen ~/ 2);
      expect(find.byType(AbilityUnlockSheet), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(AbilityUnlockSheet), findsOneWidget);
    });

    testWidgets('bestanden feiert die Fähigkeit', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await bestehen(tester, container);

      expect(find.byType(AbilityUnlockSheet), findsOneWidget);
      expect(find.text('Herzlichen Glückwunsch'), findsOneWidget);

      final name = pitNameOf(knoten.unlocksAbility!)!;
      expect(find.text('Du hast $name freigeschaltet'), findsOneWidget);
    });

    testWidgets('auf Level 1 ist kein Platz frei — er feiert trotzdem', (
      tester,
    ) async {
      // **Der Fall, den man am ehesten verschluckt.** Ein frischer
      // Charakter steht auf Level 1, dort gehört der einzige Platz der
      // Waffe. Die Feier ausfallen zu lassen hiesse: etwas erreicht,
      // nichts gesehen.
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await bestehen(tester, container);

      expect(find.byType(AbilityUnlockSheet), findsOneWidget);
      expect(find.text('Direkt ausrüsten'), findsNothing);
      expect(find.textContaining('Level 3'), findsOneWidget);
    });

    testWidgets('mit freiem Platz legt „Direkt ausrüsten" sie hin', (
      tester,
    ) async {
      useTallView(tester);

      // Genug Erfahrung für Level 3, ohne den Knoten selbst zu bestehen —
      // sonst gäbe es nichts mehr freizuschalten.
      var progress = const TheoryProgress.empty();
      for (final lesson in habitsBranch.lessons) {
        progress = progress.submit(lesson, <int?>[
          for (final question in lesson.questions) question.correctIndex,
        ]).progress;
      }

      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(theory: progress)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        LevelCurve.levelFor(
          container.read(theoryProgressProvider).totalXp,
        ).level,
        greaterThanOrEqualTo(3),
      );

      await bestehen(tester, container);

      expect(find.text('Direkt ausrüsten'), findsOneWidget);
      await tester.tap(find.text('Direkt ausrüsten'));
      await tester.pumpAndSettle();

      expect(
        container.read(chosenAbilitiesProvider).at(0),
        knoten.unlocksAbility,
      );
    });

    testWidgets('„Ins Inventar" legt nichts hin', (tester) async {
      useTallView(tester);

      var progress = const TheoryProgress.empty();
      for (final lesson in habitsBranch.lessons) {
        progress = progress.submit(lesson, <int?>[
          for (final question in lesson.questions) question.correctIndex,
        ]).progress;
      }

      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(theory: progress)),
        ],
      );
      addTearDown(container.dispose);

      await bestehen(tester, container);
      await tester.tap(find.text('Ins Inventar'));
      await tester.pumpAndSettle();

      // Die Fähigkeit ist verdient — sie liegt nur auf keinem Platz.
      expect(container.read(chosenAbilitiesProvider).isEmpty, isTrue);
      expect(
        container.read(unlockedAbilitiesProvider).map((a) => a.moveId),
        contains(knoten.unlocksAbility),
      );
    });
  });
}
