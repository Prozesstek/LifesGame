import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/stat_summary.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/ui/aufstieg.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Mehr Wucht beim Häkchen: aufsteigende Zahlen, eine Werte-Kachel, die
/// antwortet, ein eigener Klang für einen Punkt, ein Ring auf der
/// Startseite.
const Day _heute = Day(2026, 9, 23);

class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

ProviderContainer _container({SoundPlayer? klang}) {
  final c = ProviderContainer(
    overrides: [
      todayProvider.overrideWithValue(_heute),
      if (klang != null) soundPlayerProvider.overrideWithValue(klang),
    ],
  );
  addTearDown(c.dispose);
  final theorie = c.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
  return c;
}

/// Eine eigene Stärke-Gewohnheit mit vier Häkchen an den Tagen davor —
/// das nächste ist der fünfte und damit ein Punkt (`StatCurve`).
String _vorDemPunkt(ProviderContainer c) {
  final controller = c.read(habitTrackerProvider.notifier);
  final id = controller
      .addCustom(
        name: 'Liegestütze',
        stat: HabitStat.staerke,
        difficulty: HabitDifficulty.mittel,
      )!
      .id;
  var tag = _heute;
  for (var i = 0; i < 4; i++) {
    tag = tag.previous;
    controller.toggle(id, tag);
  }
  return id;
}

Future<void> _pumpHabits(WidgetTester tester, ProviderContainer c) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: HabitsScreen()),
    ),
  );
  await tester.pump();
}

double _skalaVon(WidgetTester tester, String wert) {
  final transform = tester.widget<Transform>(
    find
        .ancestor(
          of: find.descendant(
            of: find.byType(StatSummary),
            matching: find.text(wert),
          ),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  group('Aufsteigende Zahlen', () {
    testWidgets('steigen dort auf, wo getippt wurde, und verschwinden', (
      tester,
    ) async {
      final host = GlobalKey<AufstiegHostState>();
      await tester.pumpWidget(
        MaterialApp(
          home: AufstiegHost(key: host, child: const SizedBox.expand()),
        ),
      );
      await tester.tapAt(const Offset(200, 300));
      host.currentState!.zeige(const <AufstiegZeile>[AufstiegZeile('+15 EP')]);
      await tester.pump();

      final bei = tester.getCenter(find.text('+15 EP'));
      expect(bei.dx, closeTo(200, 1));
      expect(bei.dy, closeTo(300, 40));

      await tester.pumpAndSettle();
      expect(find.text('+15 EP'), findsNothing);
    });

    testWidgets('ein Häkchen lässt Erfahrung und Gold aufsteigen', (
      tester,
    ) async {
      final c = _container();
      _vorDemPunkt(c);
      await _pumpHabits(tester, c);

      await tester.tap(find.text('Liegestütze'));
      await tester.pump();

      // Das fünfte Häkchen einer Kette, also mit ihrem Multiplikator.
      final erfahrung = HabitRewards.xpFor(5);
      expect(
        find.text('+$erfahrung EP  +${HabitRewards.goldPerCheck} G'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });

  group('Ein Punkt fällt', () {
    testWidgets('die Kachel des Werts springt und kommt zurück', (
      tester,
    ) async {
      final c = _container();
      _vorDemPunkt(c);
      await _pumpHabits(tester, c);
      final vorher = c.read(characterStatsProvider).attack;
      expect(_skalaVon(tester, '$vorher'), 1);

      await tester.tap(find.text('Liegestütze'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final nachher = c.read(characterStatsProvider).attack;
      expect(nachher, vorher + 1);
      expect(_skalaVon(tester, '$nachher'), greaterThan(1.05));

      await tester.pumpAndSettle();
      expect(_skalaVon(tester, '$nachher'), 1);
    });

    testWidgets('und klingt anders als ein Häkchen', (tester) async {
      final mitschrift = _Mitschrift();
      final c = _container(klang: mitschrift);
      _vorDemPunkt(c);
      await _pumpHabits(tester, c);

      await tester.tap(find.text('Liegestütze'));
      await tester.pump();

      expect(mitschrift.gespielt.first, SoundEffect.statPunkt);
      await tester.pumpAndSettle();
    });
  });

  group('Der Ring auf der Startseite', () {
    Future<void> kreis(WidgetTester tester, HubProgress p) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HubCircle(
                icon: Icons.check,
                label: 'Gewohnheiten',
                progress: p,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('zählt, was heute erledigt ist', (tester) async {
      await kreis(tester, const HubProgress(done: 3, total: 5));
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('ein voller Tag trägt ein Häkchen statt einer Zahl', (
      tester,
    ) async {
      await kreis(tester, const HubProgress(done: 5, total: 5));
      expect(find.text('5/5'), findsNothing);
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('ohne laufende Gewohnheit gibt es keinen Ring', (tester) async {
      await kreis(tester, const HubProgress(done: 0, total: 0));
      expect(find.text('0/0'), findsNothing);
    });
  });
}
