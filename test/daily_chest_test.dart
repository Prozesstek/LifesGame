import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/daily_chest_card.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Tagestruhe auf dem ganzen Weg (ADR-0044): alles erledigt → Karte
/// → Öffnen → Enthüllung → Gold im Goldstand.
const Day _heute = Day(2026, 9, 23);

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
  );
  addTearDown(c.dispose);
  final theorie = c.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
  final vorlage = c.read(unlockedHabitsProvider).first;
  c.read(habitTrackerProvider.notifier).activate(vorlage.id);
  return c;
}

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: HabitsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('solange etwas offen ist, steht keine Truhe da', (tester) async {
    final c = _container();
    await _pump(tester, c);

    expect(find.byType(DailyChestCard), findsNothing);
    expect(find.textContaining('und die Tagestruhe'), findsOneWidget);
  });

  testWidgets('alles erledigt: öffnen, sehen, einsacken', (tester) async {
    final c = _container();
    final inhalt = DailyChest.forDay(_heute);
    // Abgehakt über den Controller: Das erste Häkchen bringt sonst eine
    // Errungenschaft samt Feier, die über der Liste liegt. Geprüft wird
    // hier die Truhe, nicht die Feier.
    final id = c.read(habitTrackerProvider).activeIds.single;
    c.read(habitTrackerProvider.notifier).toggle(id, _heute);
    final goldVorher = c.read(goldProvider);
    await _pump(tester, c);
    expect(find.text('Deine Tagestruhe'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('+${inhalt.gold} Gold'), findsOneWidget);
    expect(c.read(goldProvider), goldVorher + inhalt.gold);

    await tester.tap(find.widgetWithText(FilledButton, 'Einsacken'));
    await tester.pumpAndSettle();

    expect(find.text('Deine Tagestruhe'), findsNothing);
    expect(
      find.text('Tagestruhe: ${chestSummary(inhalt)}'),
      findsOneWidget,
      reason: 'Die offene Truhe sagt, was drin war.',
    );
    expect(c.read(habitTrackerProvider).canOpenChest(_heute), isFalse);
  });
}
