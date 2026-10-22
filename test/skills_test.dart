import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/widgets/habit_check_tile.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/skills/gebiet_zeichen.dart';
import 'package:lifes_game/skills/skill_text.dart';
import 'package:lifes_game/skills/skills.dart';
import 'package:lifes_game/skills/skills_provider.dart';
import 'package:lifes_game/skills/widgets/gebiet_frage_karte.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Skills je Gebiet (ADR-0085): Naht zwischen `habits` und `theory`,
/// das Tempo der Kurve mit echten Häkchen, und die einmalige Frage nach
/// dem Gebiet.
void main() {
  const start = Day(2026, 1, 1);

  /// Eine Vorlage [tage] Tage am Stück abgehakt, ab [start].
  HabitTracker taeglich(HabitTemplate vorlage, int tage) {
    var t = const HabitTracker.empty().activate(vorlage.id, today: start);
    var tag = start;
    for (var i = 0; i < tage; i++) {
      t = t.check(vorlage.id, tag).tracker;
      tag = tag.next;
    }
    return t;
  }

  group('Die Naht zwischen Gewohnheiten und Baum', () {
    test(
      'jedes Gebiet ist eine Wurzel des Baums, und jede Wurzel ein Gebiet',
      () {
        expect(
          SkillArea.values.map((a) => a.name).toSet(),
          theoryGraph.roots.map((r) => r.id).toSet(),
        );
      },
    );

    test('jede Vorlage gehört zum Gebiet ihrer Lektion', () {
      for (final vorlage in HabitCatalog.all) {
        final knoten = theoryGraph.nodes.where(
          (n) => n.lesson.unlocksHabit == vorlage.name,
        );
        expect(knoten, isNotEmpty, reason: vorlage.id);
        final gebiete = <String>{
          for (final wurzel in theoryGraph.roots)
            for (final n in knoten)
              if (theoryGraph
                  .descendantsOf(wurzel.id, includeSelf: true)
                  .any((d) => d.id == n.id))
                wurzel.id,
        };
        expect(gebiete, contains(vorlage.area.name), reason: vorlage.id);
      }
    });
  });

  group('Wie schnell ein Skill steigt', () {
    // Eine Gewohnheit täglich, ohne eine einzige Seite. Mit Seiten und
    // mehreren Gewohnheiten im Gebiet geht es schneller — das hier ist
    // die untere Linie, die ADR-0085 nennt.
    final vorlage = HabitCatalog.all.firstWhere(
      (h) => h.area == SkillArea.koerper,
    );

    int stufeNach(int tage) {
      return SkillCurve.levelFor(
        taeglich(vorlage, tage).xpIn(SkillArea.koerper),
      ).level;
    }

    test('Skill 10 nach knapp zwei Monaten', () {
      expect(stufeNach(40), lessThan(10));
      expect(stufeNach(60), greaterThanOrEqualTo(10));
    });

    test('Skill 25 nach etwa fünf Monaten', () {
      expect(stufeNach(140), lessThan(25));
      expect(stufeNach(180), greaterThanOrEqualTo(25));
    });

    test('Skill 50 nach gut einem Jahr — und nicht vorher', () {
      expect(stufeNach(365), lessThan(50));
      expect(stufeNach(480), greaterThanOrEqualTo(50));
    });

    test('nach 300 Tagen wächst er noch, wo das Level schon am Ende ist', () {
      // Das ist der Spieler, um den es geht: Das Charakter-Level endet
      // bei 50, ein Skill nach einem Jahr ist erst bei gut 40.
      expect(stufeNach(300), lessThan(SkillCurve.maxLevel ~/ 2));
      expect(stufeNach(330), greaterThan(stufeNach(300)));
    });
  });

  group('Skills.aus', () {
    test('Häkchen, Seiten und Rückfragen eines Gebiets zählen zusammen', () {
      final koerper = theoryGraph.nodeById('koerper')!;
      final theorie = const TheoryProgress.empty().submit(
        koerper.lesson,
        <int?>[
          for (final frage in koerper.lesson.questions) frage.correctIndex,
        ],
      ).progress;
      final rueckfrage = ReviewLog(<int, ReviewAnswer>{
        1: ReviewAnswer(
          day: 1,
          lessonId: koerper.lesson.id,
          questionIndex: 0,
          correct: true,
        ),
      });
      final vorlage = HabitCatalog.all.firstWhere(
        (h) => h.area == SkillArea.koerper,
      );
      final habits = taeglich(vorlage, 3);

      final skills = Skills.aus(
        habits: habits,
        theory: theorie,
        graph: theoryGraph,
        reviews: rueckfrage,
      );

      expect(
        skills.of(SkillArea.koerper).totalXp,
        habits.xpIn(SkillArea.koerper) +
            theorie.totalXp +
            TheoryRewards.xpForReview,
      );
      expect(skills.of(SkillArea.geist).totalXp, 0);
      expect(skills.gesamt, greaterThan(SkillArea.values.length));
    });

    test('ein leerer Stand: vier Skills auf 1, Gesamtlevel 4', () {
      final skills = Skills.start();
      expect(skills.gesamt, SkillArea.values.length);
    });

    test('die Errungenschaften sehen dieselben Stufen wie der Charakter', () {
      final vorlage = HabitCatalog.all.firstWhere(
        (h) => h.area == SkillArea.koerper,
      );
      final c = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(
            SaveData(habits: taeglich(vorlage, 60)),
          ),
        ],
      );
      addTearDown(c.dispose);

      final stufe = c.read(skillsProvider).of(SkillArea.koerper).level;
      expect(stufe, greaterThanOrEqualTo(10));
      expect(c.read(achievementStatsProvider).skillKoerper, stufe);
      expect(c.read(earnedTitleIdsProvider), contains('ruestig'));
      expect(AchievementCatalog.byId('ruestig')?.area, AchievementArea.gebiete);
    });
  });

  group('Teilen', () {
    test('der Text nennt Gesamtlevel, alle vier und die längste Kette', () {
      final text = SkillText.teilen(
        skills: Skills.start(),
        longestStreak: 63,
        name: 'Frederik',
        titel: 'der Rüstige',
      );

      expect(text, startsWith('Lifes Game · Frederik, der Rüstige'));
      expect(text, contains('Gesamtlevel 4'));
      for (final area in SkillArea.values) {
        expect(text, contains('${area.label} 1'));
      }
      expect(text, contains('Längste Kette 63 Tage'));
      expect(text, endsWith('prozesstek.de/LifesGame'));
    });

    test('ohne Namen und ohne Kette fehlen nur diese Zeilen', () {
      final text = SkillText.teilen(skills: Skills.start(), longestStreak: 0);

      expect(text.split('\n').first, 'Lifes Game');
      expect(text, isNot(contains('Kette')));
    });
  });

  group('Die einmalige Frage nach dem Gebiet', () {
    const alt = CustomHabit(
      id: 'eigen-1',
      name: 'Freund anrufen',
      stat: HabitStat.disziplin,
      area: null,
      difficulty: HabitDifficulty.mittel,
    );

    Future<ProviderContainer> zeigeStart(
      WidgetTester tester,
      HabitTracker tracker,
    ) async {
      useTallView(tester);
      final c = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
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
      return c;
    }

    testWidgets('steht auf der Startseite und verschwindet nach der Wahl', (
      tester,
    ) async {
      final c = await zeigeStart(
        tester,
        const HabitTracker.empty()
            .addCustom(alt, slots: 5)
            .activate(alt.id, today: start),
      );

      expect(find.byType(GebietFrageKarte), findsOneWidget);
      expect(find.textContaining('Freund anrufen'), findsWidgets);

      await tester.tap(
        find.byKey(GebietFrageKarte.knopf(SkillArea.gesellschaft)),
      );
      await tester.pump();

      expect(
        c.read(habitTrackerProvider).definitionFor(alt.id)?.area,
        SkillArea.gesellschaft,
      );
      expect(find.textContaining('Zu welchem Gebiet'), findsNothing);
    });

    testWidgets('ein neuer Stand sieht sie nie', (tester) async {
      final vorlage = HabitCatalog.all.first;
      await zeigeStart(
        tester,
        const HabitTracker.empty().activate(vorlage.id, today: start),
      );

      expect(find.textContaining('Zu welchem Gebiet'), findsNothing);
    });
  });

  group('Ausgeschildert', () {
    testWidgets('die Kachel zeigt die Erfahrung zweimal: Level und Gebiet', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardLine(xp: 36, gold: 5, area: SkillArea.koerper),
          ),
        ),
      );

      expect(find.text('+36'), findsNWidgets(2));
      expect(find.byIcon(gebietZeichen(SkillArea.koerper)), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('^Bringt 36 Erfahrung fürs Level, 36 für Körper und 5 Gold'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ohne Gebiet steht die Erfahrung einmal da', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RewardLine(xp: 36, gold: 5))),
      );

      expect(find.text('+36'), findsOneWidget);
    });
  });
}
