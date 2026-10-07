import 'package:achievements/achievements.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

/// Antworten, die alle Fragen richtig treffen.
List<int?> _perfect(Lesson lesson) {
  return lesson.questions.map<int?>((q) => q.correctIndex).toList();
}

void main() {
  _goldZuflussPasstZuDenPreisen();

  group('Level aus Theorie', () {
    test('ohne Fortschritt ist der Spieler Level 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(playerLevelProvider).level, 1);
      expect(container.read(totalXpProvider), 0);
      expect(container.read(goldProvider), 0);
    });

    test('bestandene Lektionen heben das Level', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(theoryProgressProvider.notifier);

      for (final lesson in habitsBranch.lessons) {
        controller.submit(lesson, _perfect(lesson));
      }

      final level = container.read(playerLevelProvider);
      expect(container.read(totalXpProvider), greaterThan(0));
      expect(level.level, greaterThan(1));
      // **Seit ADR-0033 zahlt der fuenfte Zufluss mit.** Fuenf Lektionen
      // sind genau „der Wissbegierige"; sein Gold steht neben dem der
      // Lektionen und nicht statt seiner.
      expect(
        container.read(goldProvider),
        habitsBranch.lessonCount * TheoryRewards.goldForPass +
            container.read(achievementGoldProvider),
      );
      expect(
        container.read(earnedAchievementIdsProvider),
        contains('wissbegierig'),
      );
    });
  });

  // Dritte Naht: `habits` liefert Erfahrung, `progression` macht Level
  // daraus, `theory` hängt seine Zweige daran. Keines der drei Packages
  // kann diese Kette allein prüfen.
  group('Gewohnheiten und Levelkurve passen zusammen', () {
    test('Häkchen zahlen auf dasselbe Level ein wie Lektionen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final habits = container.read(habitTrackerProvider.notifier);

      final template = HabitCatalog.all.first;
      habits.activate(template.id);
      habits.toggle(template.id, const Day(2026, 1, 1));

      // Ein einziges Haekchen loest „Erster Schritt" aus (ADR-0033) --
      // die Errungenschaften stehen deshalb als eigener Summand da.
      final ersterSchritt = AchievementCatalog.byId('erster-schritt')!;
      expect(container.read(earnedAchievementIdsProvider), <String>{
        'erster-schritt',
      });
      expect(
        container.read(totalXpProvider),
        HabitRewards.xpPerCheck + ersterSchritt.tier.xp,
      );
      expect(
        container.read(goldProvider),
        HabitRewards.goldPerCheck + ersterSchritt.tier.gold,
      );
    });

    test('Erfahrung aus beiden Quellen addiert sich', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final lesson = habitsBranch.lessons.first;
      container
          .read(theoryProgressProvider.notifier)
          .submit(lesson, _perfect(lesson));
      final nurTheorie = container.read(totalXpProvider);

      final habits = container.read(habitTrackerProvider.notifier);
      final template = HabitCatalog.all.first;
      habits.activate(template.id);
      habits.toggle(template.id, const Day(2026, 1, 1));

      final ersterSchritt = AchievementCatalog.byId('erster-schritt')!;
      expect(
        container.read(totalXpProvider),
        nurTheorie + HabitRewards.xpPerCheck + ersterSchritt.tier.xp,
      );
    });

    test('das Maximallevel bleibt ein Fernziel', () {
      // Die Kurve ist laut ADR-0006 bewusst linear, damit späte Stufen
      // erreichbar bleiben — aber nicht in einem Monat.
      final tage = _daysToLevel(LevelCurve.maxLevel);

      expect(tage, greaterThan(120), reason: 'Level 50 nach $tage Tagen.');
    });

    test('die Schwierigkeit verbiegt die Kurve nicht (ADR-0028)', () {
      // **Der Grund, warum die Spanne schmal ist.** Der Spieler setzt den
      // Schwierigkeitsgrad selbst; er spricht sich damit einen Faktor auf
      // die Erfahrung zu. Solange fünf „schwere" Gewohnheiten dieselbe
      // Kurve gehen wie fünf Vorlagen, ist das eine Farbe und kein
      // Schlupfloch. Gemessen am 06.09.2026:
      //
      //   Vorlagen / mittel  240 Tage bis Level 50, 18 bis Level 10
      //   nur „leicht"       297 Tage             , 22
      //   nur „schwer"       188 Tage             , 15
      final schwer = _daysToLevel(
        LevelCurve.maxLevel,
        difficulty: HabitDifficulty.schwer,
      );
      final leicht = _daysToLevel(
        LevelCurve.maxLevel,
        difficulty: HabitDifficulty.leicht,
      );

      expect(
        schwer,
        greaterThan(120),
        reason:
            'Fünf schwere eigene Gewohnheiten bringen Level 50 in $schwer '
            'Tagen. Unter 120 wäre der selbst gesetzte Grad eine Abkürzung.',
      );
      expect(
        leicht,
        greaterThan(schwer),
        reason:
            'Leicht muss langsamer sein als schwer, sonst ist der Grad '
            'verdreht.',
      );

      // Auch der schnellste Weg darf den Baum nicht überrennen: Der
      // zweite Fähigkeitsslot auf Level 3 soll erarbeitet sein.
      expect(
        _daysToLevel(3, difficulty: HabitDifficulty.schwer),
        greaterThanOrEqualTo(2),
      );
    });
  });
}

/// Wie viele Tage tägliches Abhaken bis zum Level [target] brauchen.
///
/// [difficulty] ist der schnellste denkbare Weg seit ADR-0028: Die
/// Tagesliste besteht dann aus fünf **selbst angelegten** Gewohnheiten mit
/// diesem Grad. Ohne Angabe rechnet sie mit Vorlagen, und die sind immer
/// mittel — das ist die Zahl, die seit ADR-0008 gilt.
int _daysToLevel(int target, {HabitDifficulty? difficulty}) {
  var tracker = const HabitTracker.empty();
  final chosen = <String>[];

  if (difficulty == null) {
    for (final template in HabitCatalog.all.take(
      HabitRewards.maxActiveHabits,
    )) {
      chosen.add(template.id);
    }
  } else {
    for (var i = 0; i < HabitRewards.maxActiveHabits; i++) {
      final habit = CustomHabit(
        id: 'eigen-$i',
        name: 'Eigene $i',
        stat: HabitStat.values[i % HabitStat.values.length],
        difficulty: difficulty,
      );
      tracker = tracker.addCustom(habit, slots: HabitRewards.maxActiveHabits);
      chosen.add(habit.id);
    }
  }

  for (final id in chosen) {
    tracker = tracker.activate(id);
  }

  var day = const Day(2026, 1, 1);
  for (var tag = 1; tag <= 365; tag++) {
    for (final id in chosen) {
      tracker = tracker.check(id, day).tracker;
    }
    if (LevelCurve.levelFor(tracker.totalXp).level >= target) return tag;
    day = day.next;
  }
  return -1;
}

/// Der vierte Fadenschluss: Passen die Preise im Laden zum Gold, das
/// tatsächlich hereinkommt?
///
/// `packages/gear/test/catalog_test.dart` prüft die Preise gegen eine
/// **angenommene** Tageseinnahme — es muss annehmen, weil `package:gear`
/// und `package:habits` einander bewusst nicht kennen. Hier steht die
/// Gegenprobe: Nur die App sieht beide Seiten. Ohne diesen Test könnte
/// jemand `HabitRewards.goldPerCheck` halbieren, und der Laden wäre
/// unbemerkt doppelt so teuer.
void _goldZuflussPasstZuDenPreisen() {
  group('Preise und Gold-Zufluss', () {
    /// Was ein Tag mit vollem Häkchen-Satz einbringt.
    final goldProTag = HabitRewards.goldPerCheck * HabitRewards.maxActiveHabits;

    test('die Annahme im Gear-Package stimmt noch', () {
      // Steht diese Zahl in `packages/gear/test/catalog_test.dart` als
      // `goldProTag`. Ändert sich die eine, muss die andere mit.
      expect(goldProTag, 25);
    });

    test('der erste Satz Ausrüstung ist in etwa einem Monat tragbar', () {
      final tage = GearCatalog.cheapestFullSetPrice / goldProTag;

      expect(
        tage,
        greaterThan(20),
        reason: 'Der Laden ist leer gekauft, bevor er interessant wird.',
      );
      expect(
        tage,
        lessThan(60),
        reason: 'Bis dahin hat niemand mehr Lust — der Laden bleibt Deko.',
      );
    });

    test('der ganze Skillbaum allein kauft den Laden nicht leer', () {
      // Theorie ist einmalig, Gewohnheiten sind täglich. Käme der ganze
      // Laden schon aus dem Lesen, hätte das Abhaken keinen Zweck mehr —
      // und das Konzept stellt Gewohnheiten ausdrücklich an die erste
      // Stelle.
      var progress = const TheoryProgress.empty();
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          progress = progress.submit(lesson, _perfect(lesson)).progress;
        }
      }

      final alles = GearCatalog.all.fold<int>(0, (sum, i) => sum + i.price);

      expect(
        progress.totalGold,
        lessThan(alles),
        reason: 'Der Skillbaum allein finanziert den kompletten Laden.',
      );
    });
  });

  group('Die Grundlagen führen zum zweiten Platz (ADR-0070)', () {
    // **Der Zusammenhang, der die alte Kette ersetzt.** Bis ADR-0070
    // gab das Handbuch kostenlos 275 Erfahrung und damit Level 3, die
    // Stufe des zweiten Fähigkeitsplatzes (ADR-0018). Jetzt kosten seine
    // Seiten Punkte, und der Weg zu ihnen ist neun Knoten lang.
    //
    // Was gelten muss, damit daraus keine Sackgasse wird: Wer diesen Weg
    // liest und sonst nichts tut, hat danach den zweiten Platz offen
    // **und** einen Punkt übrig, für den es eine Fähigkeit gibt. Wer an
    // TheoryRewards, der Levelkurve, den Startpunkten oder dem Weg
    // dreht, soll es hier merken.

    TheoryProgress gelesen(Iterable<String> ids) {
      var progress = const TheoryProgress.empty();
      for (final id in ids) {
        final lesson = theoryGraph.nodeById(id)!.lesson;
        progress = progress.openNode(id);
        progress = progress.submit(lesson, _perfect(lesson)).progress;
      }
      return progress;
    }

    test('wer den Weg der Grundlagen liest, hat den zweiten Platz', () {
      final xp = gelesen(theoryBasicsPath).totalXp;
      final level = LevelCurve.levelFor(xp).level;

      expect(
        level,
        greaterThanOrEqualTo(AbilitySlots.levelForSlot(2)!),
        reason:
            'Die Grundlagen geben $xp Erfahrung und damit nur Level '
            '$level. Der zweite Fähigkeitsplatz braucht Level '
            '${AbilitySlots.levelForSlot(2)}.',
      );
    });

    test('und danach einen Punkt übrig, für den es eine Fähigkeit gibt', () {
      final stand = gelesen(theoryBasicsPath);
      final level = LevelCurve.levelFor(stand.totalXp).level;
      final frei = TheoryPoints.availableAt(
        level: level,
        spent: stand.spentPointsIn(theoryGraph),
      );

      final zuHaben = theoryGraph.nodes.where(
        (node) =>
            node.unlocksAbility != null &&
            stand.canOpenNode(node.id, theoryGraph, availablePoints: frei),
      );

      expect(frei, greaterThan(0));
      expect(
        zuHaben,
        isNotEmpty,
        reason:
            'Nach den Grundlagen sind $frei Punkte frei, aber kein Knoten '
            'mit Fähigkeit ist dafür zu haben.',
      );
    });

    test('die Punkte reichen auf dem ganzen Weg, Seite für Seite', () {
      // Niemand soll mitten in den Grundlagen ohne Punkt dastehen: Vor
      // jedem Schritt muss der nächste Knoten bezahlbar sein, allein aus
      // den Startpunkten und dem, was die gelesenen Seiten an Leveln
      // gebracht haben.
      for (var i = 0; i < theoryBasicsPath.length; i++) {
        final stand = gelesen(theoryBasicsPath.take(i));
        final frei = TheoryPoints.availableAt(
          level: LevelCurve.levelFor(stand.totalXp).level,
          spent: stand.spentPointsIn(theoryGraph),
        );

        expect(
          stand.canOpenNode(
            theoryBasicsPath[i],
            theoryGraph,
            availablePoints: frei,
          ),
          isTrue,
          reason: 'Schritt ${i + 1}: ${theoryBasicsPath[i]}',
        );
      }
    });
  });
}
