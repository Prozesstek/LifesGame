import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/widgets/lese_haeppchen.dart';
import 'package:lifes_game/theory/widgets/umblaettern.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Eine Seite im Wissensbaum ist ein Buch: Es klappt auf, das Eselsohr
/// und Wischen schlagen das Blatt am Rücken um, mit einem Rascheln, und
/// über die letzte Seite hinaus klappt es wieder zu (03.11.2026).
class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

/// Eine Seite mit mehreren Abschnitten und ohne Rätsel.
final Lesson _seite = habitsBranch.lessons.firstWhere(
  (l) => l.teaser == null && l.sections.length >= 3,
);

String _kopf(int i) => _seite.sections[i].heading;

Future<_Mitschrift> _oeffnen(
  WidgetTester tester, {
  bool ohneBewegung = false,
}) async {
  useTallView(tester);
  final mitschrift = _Mitschrift();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [soundPlayerProvider.overrideWithValue(mitschrift)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: ohneBewegung),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LessonScreen(lesson: _seite),
                  ),
                ),
                child: const Text('Lesen'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Lesen'));
  await tester.pumpAndSettle();
  return mitschrift;
}

void main() {
  final ohr = find.byKey(Umblaettern.ohrVorKey);

  testWidgets('das Buch klappt auf, dann steht die erste Seite', (
    tester,
  ) async {
    useTallView(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: LessonScreen(lesson: _seite)),
      ),
    );
    await tester.pump();
    // Erst liegt der Deckel darüber.
    expect(find.byType(BuchDeckel), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(BuchDeckel), findsNothing);
    expect(find.text(_kopf(0)), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(LeseHaeppchen.seitenKey)).data,
      '1 / ${_seite.sections.length}',
    );
    // Kein Knopf, kein Balken: Wohin es geht, zeigt das Eselsohr.
    expect(find.text('Weiter'), findsNothing);
    expect(ohr, findsOneWidget);
    expect(find.byKey(Umblaettern.ohrZurueckKey), findsNothing);
  });

  testWidgets('das Eselsohr schlägt das Blatt um und raschelt', (tester) async {
    final mitschrift = await _oeffnen(tester);
    mitschrift.gespielt.clear();
    expect(find.text(_kopf(0)), findsOneWidget);

    await tester.tap(ohr);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    // Mitten im Umblättern liegen zwei Blätter übereinander.
    expect(find.byType(BuchPapier), findsNWidgets(2));
    expect(find.text(_kopf(0)), findsOneWidget);
    expect(find.text(_kopf(1)), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(BuchPapier), findsOneWidget);
    expect(find.text(_kopf(0)), findsNothing);
    expect(find.text(_kopf(1)), findsOneWidget);
    expect(mitschrift.gespielt, <SoundEffect>[SoundEffect.blaettern]);
    expect(
      tester.widget<Text>(find.byKey(LeseHaeppchen.seitenKey)).data,
      '2 / ${_seite.sections.length}',
    );

    // Jetzt geht es auch zurück, links unten.
    await tester.tap(find.byKey(Umblaettern.ohrZurueckKey));
    await tester.pumpAndSettle();
    expect(find.text(_kopf(0)), findsOneWidget);
  });

  testWidgets('Wischen blättert vor und zurück', (tester) async {
    await _oeffnen(tester);
    final buch = find.byType(Umblaettern);

    await tester.fling(buch, const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(_kopf(1)), findsOneWidget);

    await tester.fling(buch, const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(_kopf(0)), findsOneWidget);
    expect(find.text(_kopf(1)), findsNothing);

    // Vor der ersten Seite liegt nichts.
    await tester.fling(buch, const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(_kopf(0)), findsOneWidget);
  });

  testWidgets('halb gezogen und langsam losgelassen fällt es zurück', (
    tester,
  ) async {
    await _oeffnen(tester);
    await tester.timedDrag(
      find.byType(Umblaettern),
      const Offset(-80, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.text(_kopf(0)), findsOneWidget);
    expect(find.text(_kopf(1)), findsNothing);
  });

  testWidgets('über die letzte Seite hinaus klappt das Buch zu, dann kommen '
      'die Fragen', (tester) async {
    await _oeffnen(tester);
    for (var i = 1; i < _seite.sections.length; i++) {
      await tester.tap(ohr);
      await tester.pumpAndSettle();
    }
    expect(find.text(_kopf(_seite.sections.length - 1)), findsOneWidget);

    await tester.tap(ohr);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BuchDeckel), findsOneWidget);

    await tester.pumpAndSettle();
    final fragen = _seite.questions.where(
      (q) => find.text(q.prompt).evaluate().isNotEmpty,
    );
    expect(fragen, hasLength(1));
  });

  testWidgets('zurück klappt erst das Buch zu', (tester) async {
    await _oeffnen(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Noch da, der Deckel schließt sich.
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.byType(BuchDeckel), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text('Lesen'), findsOneWidget);
  });

  testWidgets('ohne Bewegung im System blättert es sofort', (tester) async {
    await _oeffnen(tester, ohneBewegung: true);
    expect(find.byType(BuchDeckel), findsNothing);
    await tester.tap(ohr);
    await tester.pump();
    await tester.pump();
    expect(find.byType(BuchPapier), findsOneWidget);
    expect(find.text(_kopf(1)), findsOneWidget);
  });
}
