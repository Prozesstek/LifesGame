import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/progression/level_roadmap.dart';
import 'package:lifes_game/progression/show_level_up.dart';
import 'package:progression/progression.dart';

/// Die Level-Roadmap und was erst mit einem Level aufgeht (ADR-0098).
void main() {
  group('Roadmap', () {
    test('die Meilensteine: Plätze, Extras, Ultimate, Rahmen, Höchstlevel', () {
      expect(LevelRoadmap.meilensteine, <int>[
        2, 3, 4, 5, 6, 7, 10, 15, 20, 30, 40, 50, //
      ]);
    });

    test('Level 5 bringt das Haustier, Level 10 Platz, Sammlung, Rahmen', () {
      expect(LevelRoadmap.gewinneAuf(5).map((g) => g.name), <String>[
        'Haustier',
      ]);
      expect(LevelRoadmap.gewinneAuf(10).map((g) => g.name), <String>[
        'Fähigkeitsplatz 4',
        'Sammlung',
        'Rahmen: Bronze',
      ]);
      expect(LevelRoadmap.gewinneAuf(9), isEmpty);
    });

    test('der nächste Meilenstein', () {
      expect(LevelRoadmap.naechsterMeilenstein(1), 2);
      expect(LevelRoadmap.naechsterMeilenstein(7), 10);
      expect(LevelRoadmap.naechsterMeilenstein(50), isNull);
    });
  });

  group('Sperren am Level', () {
    const mitGewohnheit = ErsterStartStand(hatGewohnheit: true, haekchen: 3);

    ErsterStart auf(
      int level, {
      bool hatTier = false,
      bool warAmFeuer = false,
      bool versucht = false,
    }) => ErsterStart.aus(
      ErsterStartStand(
        hatGewohnheit: true,
        haekchen: mitGewohnheit.haekchen,
        hatGekaempft: true,
        stufenGeschafft: 1,
        level: level,
        hatTier: hatTier,
        warAmFeuer: warAmFeuer,
        tagesgrubeVersucht: versucht,
      ),
    );

    test('das Lagerfeuer ab Level 3', () {
      expect(auf(2).zeigtTagesaufgaben, isFalse);
      expect(auf(3).zeigtTagesaufgaben, isTrue);
    });

    test('der Tagesdungeon ab Level 4', () {
      expect(auf(3).zeigtTagesgrube, isFalse);
      expect(auf(4).zeigtTagesgrube, isTrue);
    });

    test('das Haustier ab Level 5', () {
      expect(auf(4).zeigtHaustier, isFalse);
      expect(auf(5).zeigtHaustier, isTrue);
    });

    test('die Statistik ab Level 7, die Sammlung ab Level 10', () {
      expect(auf(6).zeigt(Bereich.statistik), isFalse);
      expect(auf(7).zeigt(Bereich.statistik), isTrue);
      expect(auf(9).zeigtSammlung, isFalse);
      expect(auf(10).zeigtSammlung, isTrue);
    });

    test('was ein Stand schon hat, behält er', () {
      expect(auf(1, hatTier: true).zeigtHaustier, isTrue);
      expect(auf(2, warAmFeuer: true).zeigtTagesaufgaben, isTrue);
      expect(auf(2, versucht: true).zeigtTagesgrube, isTrue);
    });

    test('ohne Gewohnheit kein Ei, auch auf hohem Level', () {
      final start = ErsterStart.aus(const ErsterStartStand(level: 9));
      expect(start.zeigtHaustier, isFalse);
    });

    test('allesOffen zeigt alles', () {
      const alles = ErsterStart.allesOffen;
      expect(alles.zeigtTagesaufgaben, isTrue);
      expect(alles.zeigtHaustier, isTrue);
      expect(alles.zeigtSammlung, isTrue);
      expect(alles.zeigtTagesgrube, isTrue);
    });
  });

  testWidgets('die Feier nennt das Haustier und was als Nächstes kommt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LevelUpSheet(levelUp: LevelUp.between(4, 5))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Haustier ist offen'), findsOneWidget);
    expect(find.byKey(LevelUpSheet.ausblickKey), findsOneWidget);
    // Nach Level 5 kommt Level 6 mit dem dritten Platz.
    expect(find.text('Level 6'), findsOneWidget);
  });
}
