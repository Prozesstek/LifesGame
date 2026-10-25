import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/cue_dialog.dart';
import 'package:lifes_game/habits/widgets/gewohnheit_anlegen.dart';
import 'package:lifes_game/habits/widgets/weekday_picker.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Eine neue Gewohnheit, eine Frage nach der anderen
/// ([ADR-0089](../docs/decisions/0089-eine-frage-nach-der-anderen.md)).
///
/// Der Weg geht über drei Stellen — Plus-Knopf, Blatt, Tracker —, und am
/// Ende muss im Tracker stehen, was auf den Blättern gewählt wurde.
const Day _heute = Day(2026, 10, 25); // ein Sonntag

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
  );
  addTearDown(c.dispose);
  // Die Lektionen des Handbuchs: Damit gibt es Vorlagen und Plätze.
  final theorie = c.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
  return c;
}

Future<void> _zeige(WidgetTester tester, ProviderContainer c) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: HabitsScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _tippe(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Plus → Eigene → Name → Weiter.
Future<void> _bisZumGebiet(WidgetTester tester, String name) async {
  await _tippe(tester, HabitsScreen.plusKey);
  await _tippe(tester, GewohnheitAnlegen.eigeneKey);
  await tester.enterText(find.byKey(GewohnheitAnlegen.nameKey), name);
  await tester.pump();
  await _tippe(tester, GewohnheitAnlegen.weiterKey);
}

void main() {
  testWidgets('der Plus-Knopf ist da, die Reiter nicht', (tester) async {
    await _zeige(tester, _container());

    expect(find.byKey(HabitsScreen.plusKey), findsOneWidget);
    expect(find.text('Eigene'), findsNothing);
    expect(find.text('Vorerstellte'), findsNothing);

    await _tippe(tester, HabitsScreen.plusKey);
    expect(find.text('Neue Gewohnheit'), findsOneWidget);
    expect(find.byKey(GewohnheitAnlegen.eigeneKey), findsOneWidget);
    expect(find.byKey(GewohnheitAnlegen.vorlageKey), findsOneWidget);
  });

  testWidgets('eine eigene, Blatt für Blatt — alles landet im Tracker', (
    tester,
  ) async {
    final c = _container();
    await _zeige(tester, c);

    await _bisZumGebiet(tester, 'Freund anrufen');
    expect(find.text('Wo zahlt es ein?'), findsOneWidget);
    // Das Gebiet zeigt den Kampfwert, der daraus folgt (ADR-0088).
    expect(find.text('Leben'), findsOneWidget);

    await _tippe(tester, GewohnheitAnlegen.gebietKey(SkillArea.gesellschaft));
    expect(find.text('Wie schwer fällt es dir?'), findsOneWidget);
    await _tippe(tester, GewohnheitAnlegen.gradKey(HabitDifficulty.schwer));
    expect(find.text('Wie misst du es?'), findsOneWidget);
    await _tippe(tester, GewohnheitAnlegen.zielKey(ZielArt.menge));
    await tester.enterText(find.byKey(GewohnheitAnlegen.mengeKey), '3');
    await tester.pump();
    await _tippe(tester, GewohnheitAnlegen.weiterKey);

    expect(find.text('Wann machst du das?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Nach dem Frühstück'));
    await tester.pump();
    await _tippe(tester, GewohnheitAnlegen.weiterKey);

    expect(find.text('An welchen Tagen?'), findsOneWidget);
    await _tippe(tester, WeekdayPicker.keyFor(6));
    await _tippe(tester, GewohnheitAnlegen.weiterKey);

    expect(find.text('Und danach gönnst du dir?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Musik hören'));
    await tester.pump();
    expect(find.text('Fertig'), findsOneWidget);
    await _tippe(tester, GewohnheitAnlegen.weiterKey);

    final t = c.read(habitTrackerProvider);
    final eigen = t.customHabits.single;
    expect(eigen.name, 'Freund anrufen');
    expect(eigen.area, SkillArea.gesellschaft);
    expect(eigen.stat, HabitStat.ausdauer);
    expect(eigen.difficulty, HabitDifficulty.schwer);
    expect(eigen.goal?.target, 3);
    expect(eigen.priority, HabitPriority.normal, reason: 'nicht mehr gefragt');
    expect(eigen.why, isEmpty, reason: 'nicht mehr gefragt');
    expect(t.isActive(eigen.id), isTrue);
    expect(t.cueFor(eigen.id), 'Nach dem Frühstück');
    expect(t.treatFor(eigen.id), 'Musik hören');
    expect(t.weekdaysFor(eigen.id), <int>{1, 2, 3, 4, 5, 7});
    expect(find.text('Neue Gewohnheit'), findsNothing, reason: 'zu');
  });

  testWidgets('eine Wahl führt mit einem Tipp weiter, zurück behält sie', (
    tester,
  ) async {
    await _zeige(tester, _container());
    await _bisZumGebiet(tester, 'Gitarre üben');

    await _tippe(tester, GewohnheitAnlegen.gebietKey(SkillArea.koerper));
    expect(find.text('Wie schwer fällt es dir?'), findsOneWidget);

    await _tippe(tester, GewohnheitAnlegen.zurueckKey);
    expect(find.text('Wo zahlt es ein?'), findsOneWidget);
    await _tippe(tester, GewohnheitAnlegen.zurueckKey);
    // Der Name steht noch da.
    expect(find.text('Gitarre üben'), findsOneWidget);
  });

  testWidgets('ohne Namen geht es nicht weiter', (tester) async {
    await _zeige(tester, _container());
    await _tippe(tester, HabitsScreen.plusKey);
    await _tippe(tester, GewohnheitAnlegen.eigeneKey);

    final weiter = tester.widget<FilledButton>(
      find.byKey(GewohnheitAnlegen.weiterKey),
    );
    expect(weiter.onPressed, isNull);
  });

  testWidgets('abbrechen legt nichts an', (tester) async {
    final c = _container();
    await _zeige(tester, c);
    await _bisZumGebiet(tester, 'Zehn Liegestütze');
    await _tippe(tester, GewohnheitAnlegen.gebietKey(SkillArea.koerper));

    await tester.tap(find.byTooltip('Abbrechen'));
    await tester.pumpAndSettle();

    expect(c.read(habitTrackerProvider).customHabits, isEmpty);
    expect(find.text('Neue Gewohnheit'), findsNothing);
  });

  testWidgets('eine Vorlage fragt nur noch nach Wann, Tagen und Danach', (
    tester,
  ) async {
    final c = _container();
    await _zeige(tester, c);
    await _tippe(tester, HabitsScreen.plusKey);
    await _tippe(tester, GewohnheitAnlegen.vorlageKey);

    final vorlage = HabitCatalog.starter;
    await _tippe(tester, GewohnheitAnlegen.vorlageEintrag(vorlage.id));

    expect(find.text('Wann machst du das?'), findsOneWidget);
    expect(find.text('„${vorlage.name}“'), findsOneWidget);
    await _tippe(tester, GewohnheitAnlegen.ohneKey);
    await _tippe(tester, GewohnheitAnlegen.weiterKey);
    await _tippe(tester, GewohnheitAnlegen.ohneKey);

    final t = c.read(habitTrackerProvider);
    expect(t.isActive(vorlage.id), isTrue);
    expect(t.cueFor(vorlage.id), isNull);
    expect(t.customHabits, isEmpty);
  });

  testWidgets('koppeln ist dieselbe Frage wie wann', (tester) async {
    final c = _container();
    c.read(habitTrackerProvider.notifier).activate(HabitCatalog.starterId);
    await _zeige(tester, c);

    await _bisZumGebiet(tester, 'Zehn Liegestütze');
    await _tippe(tester, GewohnheitAnlegen.gebietKey(SkillArea.koerper));
    await _tippe(tester, GewohnheitAnlegen.gradKey(HabitDifficulty.mittel));
    await _tippe(tester, GewohnheitAnlegen.zielKey(ZielArt.keins));

    // Erst ein Satz, dann die Kopplung — die Kopplung ersetzt ihn.
    await tester.enterText(find.byKey(cueFieldKey), 'Nach dem Kaffee');
    await tester.pump();
    await _tippe(tester, cueAnchorKey(HabitCatalog.starterId));
    await _tippe(tester, GewohnheitAnlegen.weiterKey);
    await _tippe(tester, GewohnheitAnlegen.weiterKey);
    await _tippe(tester, GewohnheitAnlegen.ohneKey);

    final t = c.read(habitTrackerProvider);
    final eigen = t.customHabits.single;
    expect(t.anchorFor(eigen.id), HabitCatalog.starterId);
    expect(t.cueFor(eigen.id), isNull);
  });

  testWidgets('ohne freien Platz sagt „Eigene“, warum', (tester) async {
    final c = _container();
    final controller = c.read(habitTrackerProvider.notifier);
    for (var i = 0; i < c.read(customSlotsProvider); i++) {
      controller.addCustom(
        name: 'Eigene $i',
        area: SkillArea.koerper,
        difficulty: HabitDifficulty.mittel,
      );
    }
    await _zeige(tester, c);
    await _tippe(tester, HabitsScreen.plusKey);
    await _tippe(tester, GewohnheitAnlegen.eigeneKey);

    expect(find.textContaining('Kein Platz frei'), findsOneWidget);
    expect(find.text('Neue Gewohnheit'), findsOneWidget, reason: 'bleibt');
  });

  testWidgets('bei voller Liste wartet eine neue — ohne Wann und Tage', (
    tester,
  ) async {
    final c = _container();
    // Alles freischalten, damit fünf Vorlagen laufen können.
    final theorie = c.read(theoryProgressProvider.notifier);
    for (final branch in theoryTree.branches) {
      for (final lesson in branch.lessons) {
        theorie.submit(
          lesson,
          lesson.questions.map<int?>((q) => q.correctIndex).toList(),
        );
      }
    }
    final controller = c.read(habitTrackerProvider.notifier);
    for (final vorlage
        in c.read(unlockedHabitsProvider).take(HabitRewards.maxActiveHabits)) {
      controller.activate(vorlage.id);
    }
    expect(c.read(habitTrackerProvider).isFull, isTrue);
    await _zeige(tester, c);

    await _bisZumGebiet(tester, 'Zehn Liegestütze');
    await _tippe(tester, GewohnheitAnlegen.gebietKey(SkillArea.koerper));
    await _tippe(tester, GewohnheitAnlegen.gradKey(HabitDifficulty.mittel));
    await _tippe(tester, GewohnheitAnlegen.zielKey(ZielArt.keins));

    final t = c.read(habitTrackerProvider);
    final eigen = t.customHabits.single;
    expect(t.isActive(eigen.id), isFalse);
    expect(find.text('Wann machst du das?'), findsNothing);

    // Sie steht danach unter „Deine“ bei den Vorlagen.
    await _tippe(tester, HabitsScreen.plusKey);
    await _tippe(tester, GewohnheitAnlegen.vorlageKey);
    expect(find.text('Deine'), findsOneWidget);
    expect(find.byKey(GewohnheitAnlegen.vorlageEintrag(eigen.id)), findsOne);
  });

  testWidgets('eine pausierte mit Auslöser startet mit einem Tipp', (
    tester,
  ) async {
    final c = _container();
    final controller = c.read(habitTrackerProvider.notifier);
    final eigen = controller.addCustom(
      name: 'Zehn Liegestütze',
      area: SkillArea.koerper,
      difficulty: HabitDifficulty.mittel,
    )!;
    controller
      ..setCue(eigen.id, 'Nach dem Kaffee')
      ..deactivate(eigen.id);
    expect(c.read(habitTrackerProvider).isActive(eigen.id), isFalse);
    await _zeige(tester, c);

    await _tippe(tester, HabitsScreen.plusKey);
    await _tippe(tester, GewohnheitAnlegen.vorlageKey);
    await _tippe(tester, GewohnheitAnlegen.vorlageEintrag(eigen.id));

    expect(find.text('Neue Gewohnheit'), findsNothing, reason: 'gleich zu');
    final t = c.read(habitTrackerProvider);
    expect(t.isActive(eigen.id), isTrue);
    expect(t.cueFor(eigen.id), 'Nach dem Kaffee');
  });
}
