import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/action/hero_power.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/daily_form_card.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Tagesform auf dem ganzen Weg: Häkchen → [dailyFormProvider] →
/// [heroPowerProvider] → die Zahlen, mit denen die Grube rechnet.
const Day _heute = Day(2026, 9, 23);

ProviderContainer _containerMitVorlagen() {
  final container = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
  );
  addTearDown(container.dispose);
  final theorie = container.read(theoryProgressProvider.notifier);
  for (final branch in theoryTree.branches) {
    for (final lesson in branch.lessons) {
      theorie.submit(
        lesson,
        lesson.questions.map<int?>((q) => q.correctIndex).toList(),
      );
    }
  }
  return container;
}

/// Die erste freigeschaltete Vorlage auf [stat].
HabitTemplate _vorlage(ProviderContainer c, HabitStat stat) {
  return c.read(unlockedHabitsProvider).firstWhere((t) => t.stat == stat);
}

void main() {
  test('ein Stärke-Häkchen hebt heute den Angriff, nicht das Leben', () {
    final c = _containerMitVorlagen();
    final kraft = _vorlage(c, HabitStat.staerke);
    final ruhe = _vorlage(c, HabitStat.ausdauer);
    c.read(habitTrackerProvider.notifier)
      ..activate(kraft.id)
      ..activate(ruhe.id);
    final vorher = c.read(heroPowerProvider).stats;
    final punkteVorher = c.read(characterStatsProvider);

    c.read(habitTrackerProvider.notifier).toggle(kraft.id, _heute);
    final nachher = c.read(heroPowerProvider).stats;

    // Der Punkt aus der Stat-Kurve kann dazukommen — gerechnet wird
    // deshalb gegen die neuen Grundwerte, nicht gegen die alten Zahlen.
    final punkte = c.read(characterStatsProvider);
    expect(punkte.maxHp, punkteVorher.maxHp);
    expect(
      nachher.combatAttack / punkte.attack,
      closeTo(
        vorher.combatAttack /
            punkteVorher.attack *
            (1 + HabitRewards.formPerCheck),
        0.5,
      ),
    );
    expect(nachher.combatMaxHp, vorher.combatMaxHp);
  });

  test('alles erledigt: In Form, und alle vier steigen', () {
    final c = _containerMitVorlagen();
    final kraft = _vorlage(c, HabitStat.staerke);
    final ruhe = _vorlage(c, HabitStat.ausdauer);
    final notifier = c.read(habitTrackerProvider.notifier)
      ..activate(kraft.id)
      ..activate(ruhe.id);
    final vorher = c.read(heroPowerProvider).stats;

    notifier
      ..toggle(kraft.id, _heute)
      ..toggle(ruhe.id, _heute);

    final form = c.read(heroPowerProvider).form;
    expect(form.isInForm, isTrue);
    final nachher = c.read(heroPowerProvider).stats;
    expect(nachher.combatDefense, greaterThan(vorher.combatDefense));
    expect(nachher.maxMana, greaterThan(vorher.maxMana));
  });

  test('am nächsten Tag ist die Form weg', () {
    final c = _containerMitVorlagen();
    final kraft = _vorlage(c, HabitStat.staerke);
    c.read(habitTrackerProvider.notifier)
      ..activate(kraft.id)
      ..toggle(kraft.id, _heute);

    final morgen = c.read(habitTrackerProvider).formOn(_heute.next);
    expect(morgen.isActive, isFalse);
  });

  testWidgets('die Karte sagt vorher, was ein Häkchen bringt, und danach, '
      'was es gebracht hat', (tester) async {
    final c = _containerMitVorlagen();
    final kraft = _vorlage(c, HabitStat.staerke);
    c.read(habitTrackerProvider.notifier).activate(kraft.id);

    useTallView(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: HabitsScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(DailyFormCard), findsOneWidget);
    expect(find.textContaining('jedes Häkchen gibt heute'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pump();

    // Eine einzige laufende Gewohnheit: Das Häkchen macht zugleich „In
    // Form", und das ist die grössere Nachricht.
    expect(find.textContaining('In Form!'), findsOneWidget);
    expect(find.text('In Form'), findsOneWidget);
  });
}
