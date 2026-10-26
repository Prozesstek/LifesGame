import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/skills/gebiet_farbe.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/widgets/node_bubble.dart';
import 'package:lifes_game/theory/widgets/seiten_farbe.dart';
import 'package:lifes_game/ui/palette.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Jedes Gebiet trägt eine Farbe, überall dieselbe (26.10.2026).
void main() {
  double kontrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  group('Die Tabelle', () {
    test('jede Farbe ist auf ihrem Grund lesbar', () {
      // Dieselben Grenzen wie in `palette_test.dart`: Die Farbe steht
      // als Schrift da — betonte Wörter, Zahlen, Namen.
      for (final area in SkillArea.values) {
        final pergament = GebietFarbe.pergament(area);
        final leder = GebietFarbe.leder(area);
        expect(
          kontrast(pergament, Palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${area.label} auf Pergament',
        );
        expect(
          kontrast(pergament, Palette.papier),
          greaterThanOrEqualTo(4.5),
          reason: '${area.label} auf dem Buchpapier',
        );
        expect(
          kontrast(leder, Palette.background),
          greaterThanOrEqualTo(4.5),
          reason: '${area.label} auf Leder',
        );
      }
    });

    test('vier Gebiete, vier Farben — auf jedem Grund', () {
      final pergament = SkillArea.values.map(GebietFarbe.pergament).toSet();
      final leder = SkillArea.values.map(GebietFarbe.leder).toSet();
      expect(pergament, hasLength(SkillArea.values.length));
      expect(leder, hasLength(SkillArea.values.length));
    });

    test('kein Gebiet trägt Grün, Rot oder Gold', () {
      // Die heißen schon erledigt, Gegner und Gold. Ein Häkchen aus
      // Gesellschaft sähe sonst aus wie „erledigt“.
      final belegt = <Color>{
        Palette.success,
        Palette.successOnDark,
        Palette.enemy,
        Palette.enemyOnDark,
        Palette.gold,
        Palette.goldOnDark,
        Palette.accent,
        Palette.accentOnDark,
      };
      for (final area in SkillArea.values) {
        expect(belegt, isNot(contains(GebietFarbe.pergament(area))));
        expect(belegt, isNot(contains(GebietFarbe.leder(area))));
      }
    });

    test('Geist trägt auf Leder das Blau des Manas', () {
      // Geist steigert das Mana (ADR-0088).
      expect(GebietFarbe.leder(SkillArea.geist), Palette.manaOnDark);
    });
  });

  group('Welches Gebiet eine Seite hat', () {
    test('eine Seite mit zwei Eltern: wo man sie sieht, sonst zu Hause', () {
      // *Stress* hängt zuerst an Schlaf & Regeneration (Körper), dann an
      // Geist.
      expect(gebietVon(theoryGraph, 'koerper-stress'), SkillArea.koerper);
      expect(
        gebietVon(theoryGraph, 'koerper-stress', bevorzugt: SkillArea.geist),
        SkillArea.geist,
      );
      expect(
        gebietVon(
          theoryGraph,
          'koerper-stress',
          bevorzugt: SkillArea.wissenschaft,
        ),
        SkillArea.koerper,
        reason: 'In Wissenschaft steht sie nicht.',
      );
    });

    test('jede Seite im Baum hat ein Gebiet', () {
      for (final node in theoryGraph.nodes) {
        expect(
          gebietDerSeite(theoryGraph, node.lesson.id),
          isNotNull,
          reason: node.id,
        );
      }
    });

    test('eine Id, die es nicht gibt, hat keins', () {
      expect(gebietVon(theoryGraph, 'gibt-es-nicht-und-soll-es-nie'), isNull);
    });
  });

  group('Im Baum', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          playerLevelProvider.overrideWithValue(
            LevelCurve.levelFor(LevelCurve.totalXpFor(10)),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Color farbeVon(WidgetTester tester, String nodeId) {
      return tester
          .widget<NodeBubble>(
            find.byWidgetPredicate(
              (w) => w is NodeBubble && w.node.id == nodeId,
            ),
          )
          .farbe;
    }

    testWidgets('jeder Knoten trägt die Farbe des Gebiets, in dem er steht', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container(),
          child: const MaterialApp(home: SkillTreeScreen()),
        ),
      );
      await tester.pump();

      expect(farbeVon(tester, 'koerper'), GebietFarbe.leder(SkillArea.koerper));

      // Nach Geist: *Stress* hängt dort direkt — und ist dort blau, obwohl
      // sein Zuhause Körper ist.
      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pumpAndSettle();

      expect(farbeVon(tester, 'geist'), GebietFarbe.leder(SkillArea.geist));
      expect(
        farbeVon(tester, 'koerper-stress'),
        GebietFarbe.leder(SkillArea.geist),
      );
    });
  });

  group('Auf der Seite', () {
    Future<Color> seitenFarbe(WidgetTester tester, LessonScreen seite) async {
      useTallView(tester);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: seite),
        ),
      );
      await tester.pump();
      return SeitenFarbe.of(tester.element(find.byType(AppBar)));
    }

    final stress = theoryGraph.nodeById('koerper-stress')!.lesson;

    testWidgets('ohne Angabe die Farbe ihres Zuhauses', (tester) async {
      expect(
        await seitenFarbe(tester, LessonScreen(lesson: stress)),
        GebietFarbe.pergament(SkillArea.koerper),
      );
    });

    testWidgets('aus dem Baum die des Gebiets, aus dem man kommt', (
      tester,
    ) async {
      expect(
        await seitenFarbe(
          tester,
          LessonScreen(lesson: stress, gebiet: SkillArea.geist),
        ),
        GebietFarbe.pergament(SkillArea.geist),
      );
    });
  });
}
