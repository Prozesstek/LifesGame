import 'dart:math' as math;

import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/stat_icon.dart';
import 'package:lifes_game/haustier/widgets/haustier_schmuck.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/skills/gebiet_farbe.dart';
import 'package:lifes_game/skills/gebiet_zeichen.dart';
import 'package:lifes_game/skills/widgets/gebiet_streifen.dart';
import 'package:lifes_game/skills/widgets/gebiets_kacheln.dart';
import 'package:lifes_game/statistik/statistik_screen.dart';
import 'package:lifes_game/statistik/statistik_text.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/widgets/node_bubble.dart';
import 'package:lifes_game/theory/widgets/seiten_farbe.dart';
import 'package:lifes_game/ui/anschlagtafel.dart';
import 'package:lifes_game/ui/beute_flug.dart';
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

  group('Bei den Gewohnheiten', () {
    Color? farbeVonZeichen(WidgetTester tester, Finder finder) =>
        tester.widget<Icon>(finder).color;

    testWidgets('jede Kachel oben trägt die Farbe ihres Gebiets', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: GebietsKacheln())),
        ),
      );

      for (final area in SkillArea.values) {
        expect(
          farbeVonZeichen(tester, find.byIcon(gebietZeichen(area))),
          GebietFarbe.leder(area),
        );
      }
    });

    testWidgets('ohne Gebiet ist der Streifen durchsichtig, nicht weg', (
      tester,
    ) async {
      // Gleich breit, damit ihr Name nicht weiter links steht.
      await tester.pumpWidget(
        const MaterialApp(
          home: GebietStreifen(area: null, child: SizedBox(height: 20)),
        ),
      );
      final box = tester.widget<Container>(find.byType(Container));
      final rand = (box.decoration! as BoxDecoration).border! as Border;
      expect(rand.left.width, GebietStreifen.breite);
      expect(rand.left.color, Colors.transparent);
    });

    testWidgets('„Heute“ zeigt Streifen und Zeichen in der Farbe des Gebiets', (
      tester,
    ) async {
      useTallView(tester);
      const start = Day(2026, 1, 1);
      final vorlage = HabitCatalog.all.firstWhere(
        (v) => v.area == SkillArea.koerper,
      );
      final c = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(
            SaveData(
              habits: const HabitTracker.empty().activate(
                vorlage.id,
                today: start,
              ),
            ),
          ),
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
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

      const koerper = SkillArea.koerper;
      expect(
        farbeVonZeichen(tester, find.byKey(TodayCard.gebietKey(vorlage.id))),
        GebietFarbe.pergament(koerper),
      );
      final zettel = tester
          .widgetList<Steckbrief>(find.byType(Steckbrief))
          .where((s) => s.streifen != null);
      expect(zettel.map((s) => s.streifen), <Color>[
        GebietFarbe.pergament(koerper),
      ]);
    });

    test('die Funken zum Gebiet fliegen in seiner Farbe', () {
      final flug = BeuteFlug()
        ..wirf(
          von: Offset.zero,
          ziel: FlugZiel.gebiet,
          nach: const Offset(100, 0),
          betrag: 30,
          farbe: GebietFarbe.leder(SkillArea.wissenschaft),
        );

      expect(flug.stuecke, isNotEmpty);
      for (final stueck in flug.stuecke) {
        expect(stueck.farbe, GebietFarbe.leder(SkillArea.wissenschaft));
      }
    });
  });

  group('Charakter, Errungenschaften, Haustier, Statistik', () {
    test('jeder Kampfwert trägt die Farbe seines Gebiets', () {
      // Seit ADR-0088 gehört jeder Wert zu genau einem Gebiet.
      for (final stat in HabitStat.values) {
        expect(StatIcons.colorOf(stat), GebietFarbe.pergament(stat.gebiet));
        expect(StatIcons.colorOnDarkOf(stat), GebietFarbe.leder(stat.gebiet));
      }
    });

    test('jeder Titel der Gebiete nennt ein Gebiet, das es gibt', () {
      // Die Naht zu `package:achievements`: Dort steht nur die Id.
      final gebiete = AchievementCatalog.inArea(AchievementArea.gebiete);
      expect(gebiete, isNotEmpty);
      for (final a in gebiete) {
        expect(SkillArea.tryParse(a.skillAreaId), isNotNull, reason: a.id);
      }
    });

    test('die Prägung des Haustiers nimmt dieselbe Tabelle', () {
      for (final area in SkillArea.values) {
        expect(praegungsFarbe(area), GebietFarbe.leder(area));
      }
    });

    Future<Color> statTon(WidgetTester tester, String? habitId) async {
      useTallView(tester);
      const heute = Day(2026, 10, 26);
      const eigen = CustomHabit(
        id: 'eigen-geist',
        name: 'Meditieren',
        area: SkillArea.geist,
        difficulty: HabitDifficulty.mittel,
      );
      final tracker = const HabitTracker.empty()
          .addCustom(eigen, slots: 5)
          .activate(eigen.id, today: heute.previous)
          .check(eigen.id, heute)
          .tracker;
      final c = ProviderContainer(
        overrides: [
          todayProvider.overrideWithValue(heute),
          savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: StatistikScreen(habitId: habitId)),
        ),
      );
      await tester.pump();
      return StatTon.of(tester.element(find.byType(AppBar)));
    }

    testWidgets(
      'die Statistik einer Gewohnheit trägt die Farbe ihres Gebiets',
      (tester) async {
        expect(
          await statTon(tester, 'eigen-geist'),
          GebietFarbe.pergament(SkillArea.geist),
        );
      },
    );

    testWidgets('über alle bleibt „erledigt“ grün', (tester) async {
      expect(await statTon(tester, null), StatFarbe.erledigt);
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
