import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/daily_quests_provider.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/widgets/aufgaben_streifen.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// **Die Tagesaufgaben kommen kurz von unten** (29.10.2026): Was eine
/// Aufgabe voranbringt, lässt sie hereinfahren, ihren Balken füllen und
/// wieder verschwinden.
void main() {
  const heute = Day(2026, 10, 20);
  final drei = HabitCatalog.all
      .where((t) => t.id != HabitCatalog.starter.id)
      .take(3)
      .toList(growable: false);

  // Gestern alles erledigt: Die Feiern des Anfangs liegen zurück, und
  // nichts blieb liegen.
  HabitTracker mitDreien() {
    var tracker = const HabitTracker.empty();
    for (final h in drei) {
      tracker = tracker.activate(h.id).check(h.id, heute.previous).tracker;
    }
    return tracker;
  }

  DailyQuest quest(QuestKind kind, int progress, int target) => DailyQuest(
    kind: kind,
    text: kind.name,
    progress: progress,
    target: target,
  );

  group('AufgabenSchritt.zwischen', () {
    test('nur, was gestiegen ist', () {
      final schritte = AufgabenSchritt.zwischen(
        <DailyQuest>[
          quest(QuestKind.zweiHaekchen, 0, 2),
          quest(QuestKind.rueckfrage, 0, 1),
        ],
        <DailyQuest>[
          quest(QuestKind.zweiHaekchen, 1, 2),
          quest(QuestKind.rueckfrage, 0, 1),
        ],
      );
      expect(schritte, hasLength(1));
      expect(schritte.single.vorher, 0);
      expect(schritte.single.quest.progress, 1);
      expect(schritte.single.geschafft, isFalse);
    });

    test('ein zurückgenommenes Häkchen zeigt nichts', () {
      expect(
        AufgabenSchritt.zwischen(
          <DailyQuest>[quest(QuestKind.alles, 2, 3)],
          <DailyQuest>[quest(QuestKind.alles, 1, 3)],
        ),
        isEmpty,
      );
    });

    test('der letzte Schritt schafft sie', () {
      final schritt = AufgabenSchritt.zwischen(
        <DailyQuest>[quest(QuestKind.alles, 2, 3)],
        <DailyQuest>[quest(QuestKind.alles, 3, 3)],
      ).single;
      expect(schritt.geschafft, isTrue);
    });
  });

  group('Auf der Startseite', () {
    Future<ProviderContainer> startseite(
      WidgetTester tester, {
      ErsterStart start = ErsterStart.allesOffen,
    }) async {
      useTallView(tester);
      final c = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(habits: mitDreien())),
          todayProvider.overrideWithValue(heute),
          ersterStartProvider.overrideWithValue(start),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      return c;
    }

    final streifen = find.byKey(AufgabenStreifen.streifenKey);

    Future<void> tippe(WidgetTester tester, Habit habit) => tester.tap(
      find.descendant(
        of: find.byType(TodayCard),
        matching: find.text(habit.name),
      ),
    );

    testWidgets('ein Häkchen lässt die Aufgabe hereinfahren und wieder '
        'verschwinden', (tester) async {
      final c = await startseite(tester);
      final aufgabe = c
          .read(dailyQuestsProvider)
          .firstWhere((q) => q.kind.isHabitCount);
      expect(streifen, findsNothing);

      await tippe(tester, drei.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(streifen, findsOneWidget);
      expect(
        find.descendant(of: streifen, matching: find.text(aufgabe.text)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: streifen,
          matching: find.text('1 / ${aufgabe.target}'),
        ),
        findsOneWidget,
        reason: 'der Balken ist gefüllt',
      );

      await tester.pump(AufgabenStreifen.dauer);
      await tester.pumpAndSettle();
      expect(streifen, findsNothing, reason: 'er fährt von selbst hinaus');
    });

    testWidgets('solange die Aufgaben nicht zu sehen sind, kommt nichts', (
      tester,
    ) async {
      await startseite(
        tester,
        start: ErsterStart.aus(const ErsterStartStand(hatGewohnheit: true)),
      );
      await tippe(tester, drei.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(streifen, findsNothing);
      await tester.pumpAndSettle();
    });
  });
}
