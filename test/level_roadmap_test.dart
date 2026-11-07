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
        // Zwei Gewohnheiten: Das Tutorial ist vorbei — darin gibt es kein
        // Schloss (07.11.2026).
        gewohnheitenJe: 2,
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
      expect(auf(6).bereichGesperrt(Bereich.statistik), isTrue);
      expect(auf(7).bereichGesperrt(Bereich.statistik), isFalse);
      expect(auf(9).zeigtSammlung, isFalse);
      expect(auf(10).zeigtSammlung, isTrue);
    });

    test('was noch fehlt, ist zu sehen — mit Schloss', () {
      final start = auf(2);
      // Zu sehen, aber zu: alles, dessen übrige Bedingung erfüllt ist.
      expect(start.zeigt(Bereich.statistik), isTrue);
      expect(start.gesperrt, <LevelExtra>{
        LevelExtra.lagerfeuer,
        LevelExtra.tagesdungeon,
        LevelExtra.haustier,
        LevelExtra.statistik,
        LevelExtra.sammlung,
      });
      // Offen ist davon nichts.
      expect(start.zeigtTagesaufgaben, isFalse);
      expect(start.zeigtTagesgrube, isFalse);
      expect(start.zeigtHaustier, isFalse);
      expect(start.zeigtSammlung, isFalse);
      // Auf Level 10 ist nichts mehr gesperrt.
      expect(auf(10).gesperrt, isEmpty);
    });

    test('im Tutorial kein Schloss, und die Statistik wartet', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 3,
          hatGekaempft: true,
          stufenGeschafft: 1,
          level: 2,
        ),
      );
      expect(start.schritt, Schritt.gebiete);
      expect(start.gesperrt, isEmpty);
      expect(start.zeigt(Bereich.statistik), isFalse);
    });

    test('ohne erfüllte Bedingung kein Schloss: kein Kampf, kein Dungeon', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(hatGewohnheit: true, haekchen: 1),
      );
      expect(start.istGesperrt(LevelExtra.tagesdungeon), isFalse);
      expect(start.zeigtTagesgrube, isFalse);
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
