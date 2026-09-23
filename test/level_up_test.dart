import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/progression/show_level_up.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Der Levelaufstieg wird gefeiert — mit dem, was er bringt.
class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

/// Ein Knopf, der [handlung] ausführt und danach feiert — genau so, wie
/// es die Bildschirme tun: Level vorher lesen, handeln, feiern.
Widget _buehne(void Function(WidgetRef ref) handlung) {
  return MaterialApp(
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Center(
          child: TextButton(
            onPressed: () async {
              final vorher = levelBefore(ref);
              handlung(ref);
              await showLevelUp(context, ref, before: vorher);
            },
            child: const Text('Los'),
          ),
        ),
      ),
    ),
  );
}

void _handbuch(WidgetRef ref) {
  final theorie = ref.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
}

void main() {
  testWidgets('das Blatt nennt, was der Aufstieg bringt', (tester) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LevelUpSheet(levelUp: LevelUp.between(2, 3))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aufgestiegen!'), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('Im Kampf 4 % stärker'), findsOneWidget);
    expect(find.text('+1 Theoriepunkt für den Skillbaum'), findsOneWidget);
    expect(find.text('Fähigkeitsplatz 2 ist offen'), findsOneWidget);
  });

  testWidgets('nach Erfahrung, die ein Level hebt, kommt die Feier', (
    tester,
  ) async {
    useTallView(tester);
    final mitschrift = _Mitschrift();
    final c = ProviderContainer(
      overrides: [soundPlayerProvider.overrideWithValue(mitschrift)],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: _buehne(_handbuch)),
    );

    await tester.tap(find.text('Los'));
    await tester.pumpAndSettle();

    final level = c.read(playerLevelProvider).level;
    expect(level, greaterThan(1), reason: 'das Handbuch hebt das Level');
    expect(find.text('Aufgestiegen!'), findsOneWidget);
    expect(find.text('Level $level'), findsOneWidget);
    expect(mitschrift.gespielt, contains(SoundEffect.errungenschaft));

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Aufgestiegen!'), findsNothing);
  });

  testWidgets('ohne Aufstieg keine Feier', (tester) async {
    useTallView(tester);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: _buehne((_) {})),
    );

    await tester.tap(find.text('Los'));
    await tester.pumpAndSettle();

    expect(find.text('Aufgestiegen!'), findsNothing);
  });
}
