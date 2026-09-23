import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/save/save_store.dart';
import 'package:lifes_game/save/save_watcher.dart';
import 'package:lifes_game/theory/review_controller.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/review_card.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Rückfrage des Tages in der App (ADR-0045): wann sie dasteht, was
/// sie einbringt, und dass sie einen Neustart überlebt.
const Day _heute = Day(2026, 9, 23);

ProviderContainer _container({bool handbuch = true}) {
  final c = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
  );
  addTearDown(c.dispose);
  if (handbuch) {
    final theorie = c.read(theoryProgressProvider.notifier);
    for (final lesson in habitsBranch.lessons) {
      theorie.submit(
        lesson,
        lesson.questions.map<int?>((q) => q.correctIndex).toList(),
      );
    }
  }
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

/// Tippt die Antwort mit [index] (in der Lektion) an.
Future<void> _antworte(WidgetTester tester, ReviewQuestion frage, int index) {
  return tester.tap(find.text(frage.question.options[index]));
}

void main() {
  testWidgets('ohne bestandene Seite keine Rückfrage', (tester) async {
    final c = _container(handbuch: false);
    await _pump(tester, c);
    expect(find.byType(ReviewCard), findsNothing);
  });

  testWidgets('richtig: Erfahrung und Gold, und die Karte sagt es', (
    tester,
  ) async {
    final c = _container();
    await _pump(tester, c);
    final frage = c.read(todaysReviewProvider)!;
    final xp = c.read(totalXpProvider);
    final gold = c.read(goldProvider);
    final einkommen = c.read(incomeWithoutAchievementsProvider);

    expect(find.byType(ReviewCard), findsOneWidget);
    expect(find.text(frage.question.prompt), findsOneWidget);

    await _antworte(tester, frage, frage.question.correctIndex);
    await tester.pumpAndSettle();

    expect(find.textContaining('Richtig!'), findsOneWidget);
    expect(c.read(totalXpProvider), xp + TheoryRewards.xpForReview);
    expect(c.read(goldProvider), gold + TheoryRewards.goldForReview);
    expect(
      c.read(incomeWithoutAchievementsProvider),
      einkommen + TheoryRewards.goldForReview,
      reason: 'Der Laden rechnet mit diesem Zufluss — er muss es wissen.',
    );
  });

  testWidgets('falsch: nichts, und sie kommt morgen wieder', (tester) async {
    final c = _container();
    await _pump(tester, c);
    final frage = c.read(todaysReviewProvider)!;
    final xp = c.read(totalXpProvider);

    await _antworte(tester, frage, (frage.question.correctIndex + 1) % 4);
    await tester.pumpAndSettle();

    expect(find.textContaining('Nicht ganz.'), findsOneWidget);
    expect(find.textContaining('morgen wieder'), findsOneWidget);
    expect(c.read(totalXpProvider), xp);
  });

  test('der Spielstand trägt die Antworten durch JSON', () {
    const tag = 20000;
    final frage = const ReviewLog.empty().questionFor(tag, <Lesson>[
      habitsBranch.lessons.first,
    ])!;
    final log = const ReviewLog.empty()
        .answer(tag, frage, frage.question.correctIndex)!
        .log;
    final gelesen = SaveData.decode(SaveData(reviews: log).encode());

    expect(gelesen.reviews.answerOn(tag)?.correct, isTrue);
  });

  testWidgets('der SaveWatcher schreibt die Rückfrage mit', (tester) async {
    useTallView(tester);
    final store = InMemorySaveStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveStoreProvider.overrideWithValue(store),
          todayProvider.overrideWithValue(_heute),
        ],
        child: const SaveWatcher(child: LifesGameApp()),
      ),
    );
    await tester.pump();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(LifesGameApp)),
    );
    final theorie = c.read(theoryProgressProvider.notifier);
    final lesson = habitsBranch.lessons.first;
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
    final frage = c.read(todaysReviewProvider)!;

    c
        .read(reviewLogProvider.notifier)
        .answer(_heute, frage, frage.question.correctIndex);
    await tester.pump();

    final gespeichert = await store.read();
    expect(gespeichert.reviews.correctCount, 1);
  });
}
