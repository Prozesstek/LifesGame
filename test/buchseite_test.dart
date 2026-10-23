import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/widgets/umblaettern.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Eine Seite im Wissensbaum ist ein Buch: „Weiter“ und Wischen
/// schlagen das Blatt am Rücken um, mit einem Rascheln.
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
        home: LessonScreen(lesson: _seite),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return mitschrift;
}

void main() {
  testWidgets('„Weiter“ schlägt das Blatt um und raschelt', (tester) async {
    final mitschrift = await _oeffnen(tester);
    expect(find.text(_kopf(0)), findsOneWidget);

    await tester.tap(find.text('Weiter'));
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

  testWidgets('das letzte Blatt schlägt zu den Fragen um', (tester) async {
    final mitschrift = await _oeffnen(tester);
    for (var i = 1; i < _seite.sections.length; i++) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    final start = find.text('${_seite.questionCount} Fragen beantworten');
    expect(start, findsOneWidget);

    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    // Unter dem letzten Blatt liegt ein leeres.
    expect(find.byKey(const ValueKey<String>('schluss')), findsOneWidget);

    await tester.pumpAndSettle();
    final fragen = _seite.questions.where(
      (q) => find.text(q.prompt).evaluate().isNotEmpty,
    );
    expect(fragen, hasLength(1));
    expect(
      mitschrift.gespielt.where((k) => k == SoundEffect.blaettern),
      hasLength(_seite.sections.length),
    );
  });

  testWidgets('ohne Bewegung im System blättert es sofort', (tester) async {
    await _oeffnen(tester, ohneBewegung: true);
    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(BuchPapier), findsOneWidget);
    expect(find.text(_kopf(1)), findsOneWidget);
  });
}
