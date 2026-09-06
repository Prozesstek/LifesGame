import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Eigene Gewohnheiten, Schwierigkeit, Tagesziele und Priorität
/// ([ADR-0028](../../../docs/decisions/0028-eigene-gewohnheiten.md)).
///
/// Die schärfste Zusage steht ganz unten: Die Priorität darf **keine**
/// Zahl bewegen. Sie ist der Teil des Issues, der ausdrücklich „für das
/// Spiel unwichtig" ist — und genau solche Felder wachsen später gern
/// heimlich in die Rechnung hinein.
void main() {
  const heute = Day(2026, 9, 6);
  final vorlage = HabitCatalog.all.first;

  CustomHabit eigene({
    String id = 'eigen-1',
    String name = 'Zehn Liegestütze',
    HabitStat stat = HabitStat.staerke,
    HabitDifficulty difficulty = HabitDifficulty.mittel,
    HabitGoal? goal,
    HabitPriority priority = HabitPriority.normal,
  }) {
    return CustomHabit(
      id: id,
      name: name,
      stat: stat,
      difficulty: difficulty,
      goal: goal,
      priority: priority,
    );
  }

  /// Ein Tracker mit [habit] angelegt und laufend.
  HabitTracker mitEigener(CustomHabit habit) {
    return const HabitTracker.empty()
        .addCustom(habit, slots: 5)
        .activate(habit.id);
  }

  group('Schwierigkeit', () {
    test('wirkt als Faktor auf die Erfahrung', () {
      expect(HabitRewards.xpFor(1, HabitDifficulty.leicht), 12); // 15 * 0,8
      expect(HabitRewards.xpFor(1, HabitDifficulty.mittel), 15);
      expect(HabitRewards.xpFor(1, HabitDifficulty.schwer), 20); // 15 * 1,3
    });

    test('multipliziert sich mit dem Streak-Multiplikator', () {
      // Tag 7 heißt x1,4 — zusammen mit „schwer" also 15 * 1,4 * 1,3.
      expect(HabitRewards.xpFor(7, HabitDifficulty.schwer), 27);
    });

    test('ohne Angabe rechnet alles wie vor ADR-0028', () {
      const mittel = HabitDifficulty.mittel;
      for (final streak in <int>[1, 3, 7, 14, 30, 60, 90]) {
        expect(HabitRewards.xpFor(streak), HabitRewards.xpFor(streak, mittel));
      }
    });

    test('lässt Gold unberührt — wie der Streak auch', () {
      final tracker = mitEigener(
        eigene(difficulty: HabitDifficulty.schwer),
      ).check('eigen-1', heute).tracker;

      expect(tracker.totalGold, HabitRewards.goldPerCheck);
      expect(tracker.totalXp, HabitRewards.xpFor(1, HabitDifficulty.schwer));
    });

    test('eine Vorlage ist immer mittel', () {
      expect(vorlage.difficulty, HabitDifficulty.mittel);
      expect(vorlage.difficulty.xpFactor, 1.0);
    });

    test('lässt sich nachträglich nicht ändern', () {
      final habit = eigene(difficulty: HabitDifficulty.leicht);
      final geaendert = habit.editable(name: 'Anders');

      expect(geaendert.name, 'Anders');
      expect(geaendert.difficulty, HabitDifficulty.leicht);
      expect(geaendert.stat, habit.stat);
      expect(geaendert.goal, habit.goal);
    });
  });

  group('Plätze', () {
    test('ein Platz je freigeschalteter Vorlage', () {
      expect(HabitRewards.customSlotsFor(0), 0);
      expect(HabitRewards.customSlotsFor(3), 3);
      expect(HabitRewards.customSlotsFor(-1), 0);
    });

    test('ohne Platz kommt nichts dazu', () {
      final tracker = const HabitTracker.empty().addCustom(eigene(), slots: 0);

      expect(tracker.customHabits, isEmpty);
      expect(tracker.canAddCustom(0), isFalse);
    });

    test('der letzte Platz lässt sich noch belegen', () {
      final tracker = const HabitTracker.empty().addCustom(eigene(), slots: 1);

      expect(tracker.customHabits, hasLength(1));
      expect(tracker.canAddCustom(1), isFalse);
    });

    test('dieselbe Id kommt kein zweites Mal hinein', () {
      final tracker = const HabitTracker.empty()
          .addCustom(eigene(), slots: 5)
          .addCustom(eigene(name: 'Anders'), slots: 5);

      expect(tracker.customHabits, hasLength(1));
      expect(tracker.customHabits.single.name, 'Zehn Liegestütze');
    });

    test('eine Id einer Vorlage wird nicht überschrieben', () {
      final tracker = const HabitTracker.empty()
          .addCustom(eigene(id: vorlage.id), slots: 5);

      expect(tracker.customHabits, isEmpty);
    });
  });

  group('Ids', () {
    test('zählen hoch', () {
      expect(CustomHabit.nextId(const <String>[]), 'eigen-1');
      expect(CustomHabit.nextId(const <String>['eigen-1']), 'eigen-2');
    });

    test('werden nie wiederverwendet', () {
      // „eigen-2" ist weg, die nächste ist trotzdem die 3: Sonst erbte
      // eine neue Gewohnheit die Häkchen der alten.
      expect(
        CustomHabit.nextId(const <String>['eigen-1', 'eigen-3']),
        'eigen-4',
      );
    });

    test('ignorieren fremde Ids', () {
      expect(CustomHabit.nextId(<String>[vorlage.id]), 'eigen-1');
    });
  });

  group('Auflösen', () {
    test('findet Vorlagen und Eigene über dieselbe Stelle', () {
      final tracker = mitEigener(eigene());

      expect(tracker.definitionFor(vorlage.id)?.name, vorlage.name);
      expect(tracker.definitionFor('eigen-1')?.name, 'Zehn Liegestütze');
      expect(tracker.definitionFor('gibt-es-nicht'), isNull);
    });

    test('nur Eigene sind isCustom', () {
      final tracker = mitEigener(eigene());

      expect(tracker.definitionFor('eigen-1')!.isCustom, isTrue);
      expect(tracker.definitionFor(vorlage.id)!.isCustom, isFalse);
    });

    test('eine eigene Gewohnheit zahlt auf ihren Wert ein', () {
      final tracker = mitEigener(eigene(stat: HabitStat.klarheit))
          .check('eigen-1', heute)
          .tracker;

      expect(tracker.stats.checksFor(HabitStat.klarheit), 1);
      expect(tracker.stats.checksFor(HabitStat.staerke), 0);
    });

    test('stoppen behält sie und ihre Historie', () {
      final tracker = mitEigener(eigene()).check('eigen-1', heute).tracker;
      final gestoppt = tracker.deactivate('eigen-1');

      expect(gestoppt.isActive('eigen-1'), isFalse);
      expect(gestoppt.customHabits, hasLength(1));
      expect(gestoppt.totalChecks, 1);
      expect(gestoppt.stats.checksFor(HabitStat.staerke), 1);
    });
  });

  group('Nachbessern', () {
    test('ändert Name, Begründung und Priorität', () {
      final tracker = mitEigener(eigene()).editCustom(
        'eigen-1',
        name: 'Zwanzig Liegestütze',
        why: 'Weil der Morgen dann steht.',
        priority: HabitPriority.hoch,
      );

      final habit = tracker.customHabits.single;
      expect(habit.name, 'Zwanzig Liegestütze');
      expect(habit.why, 'Weil der Morgen dann steht.');
      expect(habit.priority, HabitPriority.hoch);
    });

    test('lässt die Historie stehen', () {
      final tracker = mitEigener(eigene())
          .check('eigen-1', heute)
          .tracker
          .editCustom('eigen-1', name: 'Anders');

      expect(tracker.totalChecks, 1);
      expect(tracker.isChecked('eigen-1', heute), isTrue);
    });

    test('eine unbekannte Id ändert nichts', () {
      final tracker = mitEigener(eigene());

      expect(tracker.editCustom('gibt-es-nicht', name: 'X'), same(tracker));
    });
  });

  group('Tagesziel', () {
    test('ohne Ziel reicht ein Schritt', () {
      final result = mitEigener(eigene()).advance('eigen-1', heute);

      expect(result.isComplete, isTrue);
      expect(result.required, 1);
      expect(result.xpGained, greaterThan(0));
    });

    test('eine Menge füllt sich schrittweise', () {
      var tracker = mitEigener(
        eigene(goal: HabitGoal.menge(target: 3, unit: 'Gläser')),
      );

      final erster = tracker.advance('eigen-1', heute);
      expect(erster.progress, 1);
      expect(erster.isComplete, isFalse);
      expect(erster.xpGained, 0, reason: 'halb getan ist nicht getan');

      tracker = erster.tracker;
      expect(tracker.isChecked('eigen-1', heute), isFalse);
      expect(tracker.progressOn('eigen-1', heute), 1);

      tracker = tracker.advance('eigen-1', heute).tracker;
      final letzter = tracker.advance('eigen-1', heute);

      expect(letzter.progress, 3);
      expect(letzter.isComplete, isTrue);
      expect(letzter.xpGained, greaterThan(0));
      expect(letzter.streak, 1);
      expect(letzter.tracker.isChecked('eigen-1', heute), isTrue);
    });

    test('ein Zeitziel geht in Fünf-Minuten-Schritten', () {
      var tracker = mitEigener(eigene(goal: HabitGoal.zeit(target: 10)));

      final erster = tracker.advance('eigen-1', heute);
      expect(erster.progress, HabitGoal.zeitSchritt);
      expect(erster.isComplete, isFalse);

      tracker = erster.tracker;
      expect(tracker.advance('eigen-1', heute).isComplete, isTrue);
    });

    test('ein erledigter Tag meldet das volle Ziel', () {
      final tracker = mitEigener(
        eigene(goal: HabitGoal.menge(target: 5, unit: 'Gläser')),
      ).check('eigen-1', heute).tracker;

      expect(tracker.progressOn('eigen-1', heute), 5);
      expect(tracker.isChecked('eigen-1', heute), isTrue);
    });

    test('Teilfortschritt wandert nicht in den nächsten Tag', () {
      final tracker = mitEigener(
        eigene(goal: HabitGoal.menge(target: 3, unit: 'Gläser')),
      ).advance('eigen-1', heute).tracker;

      final morgen = tracker.advance('eigen-1', heute.next).tracker;

      expect(morgen.progressOn('eigen-1', heute.next), 1);
      expect(
        morgen.progressOn('eigen-1', heute),
        0,
        reason: 'gestern halb voll darf heute nichts schenken',
      );
    });

    test('zurücknehmen räumt auch den Zähler', () {
      final angefangen = mitEigener(
        eigene(goal: HabitGoal.menge(target: 3, unit: 'Gläser')),
      ).advance('eigen-1', heute).tracker;

      final zurueck = angefangen.uncheck('eigen-1', heute);
      expect(zurueck.progressOn('eigen-1', heute), 0);
    });

    test('ein abgehaktes Ziel lässt sich ganz zurücknehmen', () {
      final fertig = mitEigener(
        eigene(goal: HabitGoal.menge(target: 2, unit: 'Gläser')),
      ).check('eigen-1', heute).tracker;

      final zurueck = fertig.uncheck('eigen-1', heute);
      expect(zurueck.isChecked('eigen-1', heute), isFalse);
      expect(zurueck.progressOn('eigen-1', heute), 0);
      expect(zurueck.totalXp, 0);
    });

    test('ein Ziel unter eins gibt es nicht', () {
      expect(HabitGoal.menge(target: 0, unit: 'Gläser').target, 1);
      expect(HabitGoal.zeit(target: -5).target, 1);
    });

    test('ein Ziel ist nach oben gedeckelt', () {
      expect(
        HabitGoal.menge(target: 10000, unit: 'Gläser').target,
        HabitGoal.maxTarget,
      );
    });

    test('eine leere Einheit bekommt ein Wort', () {
      expect(HabitGoal.menge(target: 3, unit: '  ').unit, 'Mal');
      expect(HabitGoal.zeit(target: 10).unit, 'Minuten');
    });

    test('beschriftet sich selbst', () {
      final goal = HabitGoal.menge(target: 5, unit: 'Gläser');

      expect(goal.label, '5 Gläser');
      expect(goal.progressLabel(3), '3 / 5 Gläser');
    });
  });

  group('Priorität', () {
    test('sortiert die Tagesliste, Wichtiges oben', () {
      final nebenbei = eigene(
        id: 'eigen-1',
        name: 'Nebenbei',
        priority: HabitPriority.niedrig,
      );
      final wichtig = eigene(
        id: 'eigen-2',
        name: 'Wichtig',
        priority: HabitPriority.hoch,
      );
      final tracker = const HabitTracker.empty()
          .addCustom(nebenbei, slots: 5)
          .addCustom(wichtig, slots: 5)
          .activate('eigen-1')
          .activate('eigen-2');

      expect(
        tracker.activeHabitsByPriority.map((h) => h.name),
        <String>['Wichtig', 'Nebenbei'],
      );
      expect(
        tracker.activeHabits.map((h) => h.name),
        <String>['Nebenbei', 'Wichtig'],
        reason: 'die ungeordnete Liste bleibt die Reihenfolge des Wählens',
      );
    });

    test('bei gleicher Priorität bleibt die Reihenfolge des Wählens', () {
      final tracker = const HabitTracker.empty()
          .addCustom(eigene(id: 'eigen-1', name: 'Erste'), slots: 5)
          .addCustom(eigene(id: 'eigen-2', name: 'Zweite'), slots: 5)
          .activate('eigen-1')
          .activate('eigen-2');

      expect(
        tracker.activeHabitsByPriority.map((h) => h.name),
        <String>['Erste', 'Zweite'],
      );
    });

    test('bewegt keine einzige Zahl', () {
      // Zwei identische Gewohnheiten, nur die Priorität unterscheidet sie.
      // Erfahrung, Gold und Charakterwert müssen gleich herauskommen.
      HabitTracker gelaufen(HabitPriority priority) {
        var tracker = mitEigener(eigene(priority: priority));
        for (var tag = heute; tag <= heute.next.next; tag = tag.next) {
          tracker = tracker.check('eigen-1', tag).tracker;
        }
        return tracker;
      }

      final nebenbei = gelaufen(HabitPriority.niedrig);
      final wichtig = gelaufen(HabitPriority.hoch);

      expect(wichtig.totalXp, nebenbei.totalXp);
      expect(wichtig.totalGold, nebenbei.totalGold);
      expect(
        wichtig.stats.checksFor(HabitStat.staerke),
        nebenbei.stats.checksFor(HabitStat.staerke),
      );
      expect(wichtig.longestStreak, nebenbei.longestStreak);
    });
  });

  group('Speichern', () {
    test('eine volle eigene Gewohnheit kommt unverändert zurück', () {
      final habit = eigene(
        difficulty: HabitDifficulty.schwer,
        goal: HabitGoal.menge(target: 5, unit: 'Gläser'),
        priority: HabitPriority.hoch,
      ).editable(why: 'Weil es sonst niemand tut.');

      final gelesen = CustomHabit.fromJson(habit.toJson())!;

      expect(gelesen.id, habit.id);
      expect(gelesen.name, habit.name);
      expect(gelesen.stat, habit.stat);
      expect(gelesen.difficulty, HabitDifficulty.schwer);
      expect(gelesen.priority, HabitPriority.hoch);
      expect(gelesen.why, 'Weil es sonst niemand tut.');
      expect(gelesen.goal!.target, 5);
      expect(gelesen.goal!.unit, 'Gläser');
      expect(gelesen.goal!.kind, HabitGoalKind.menge);
    });

    test('ein Zeitziel bekommt seinen Schritt aus der Regel zurück', () {
      final habit = eigene(goal: HabitGoal.zeit(target: 20));
      final gelesen = CustomHabit.fromJson(habit.toJson())!;

      expect(gelesen.goal!.step, HabitGoal.zeitSchritt);
    });

    test('ein ganzer Tracker übersteht die Runde', () {
      var tracker = mitEigener(
        eigene(goal: HabitGoal.menge(target: 3, unit: 'Gläser')),
      );
      tracker = tracker.check('eigen-1', heute.previous).tracker;
      tracker = tracker.advance('eigen-1', heute).tracker;

      final gelesen = HabitTracker.fromJson(tracker.toJson());

      expect(gelesen.customHabits, hasLength(1));
      expect(gelesen.activeIds, <String>['eigen-1']);
      expect(gelesen.isChecked('eigen-1', heute.previous), isTrue);
      expect(gelesen.progressOn('eigen-1', heute), 1);
      expect(gelesen.totalXp, tracker.totalXp);
    });

    test('ohne Eigene und ohne Zähler bleibt der Stand so klein wie vorher',
        () {
      final tracker = const HabitTracker.empty()
          .activate(vorlage.id)
          .check(vorlage.id, heute)
          .tracker;

      expect(tracker.toJson().keys, <String>['activeIds', 'checks']);
    });

    test('eine unlesbare eigene Gewohnheit wird übersprungen', () {
      final gelesen = HabitTracker.fromJson(<String, Object?>{
        'custom': <Object?>[
          <String, Object?>{'id': 'eigen-1', 'name': 'Gut', 'stat': 'staerke'},
          <String, Object?>{'name': 'ohne Id', 'stat': 'staerke'},
          <String, Object?>{'id': 'eigen-9', 'stat': 'staerke'},
          <String, Object?>{'id': 'eigen-8', 'name': 'X', 'stat': 'quatsch'},
          'gar kein Objekt',
        ],
      });

      expect(gelesen.customHabits.map((h) => h.id), <String>['eigen-1']);
    });

    test('unbekannte Schwierigkeit und Priorität fallen auf den Standard', () {
      final gelesen = CustomHabit.fromJson(<String, Object?>{
        'id': 'eigen-1',
        'name': 'Test',
        'stat': 'klarheit',
        'difficulty': 'unmöglich',
        'priority': 'brennend',
      })!;

      expect(gelesen.difficulty, HabitDifficulty.mittel);
      expect(gelesen.priority, HabitPriority.normal);
    });

    test('eine aktive Id ohne Gewohnheit fällt heraus', () {
      final gelesen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>['eigen-1', 'gibt-es-nicht'],
        'custom': <Object?>[
          <String, Object?>{'id': 'eigen-1', 'name': 'Gut', 'stat': 'staerke'},
        ],
      });

      expect(gelesen.activeIds, <String>['eigen-1']);
    });

    test('ein Zähler auf einem erledigten Tag wird verworfen', () {
      final gelesen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[vorlage.id],
        'checks': <String, Object?>{
          vorlage.id: <Object?>[heute.toString()],
        },
        'progress': <String, Object?>{
          vorlage.id: <String, Object?>{heute.toString(): 2},
        },
      });

      expect(gelesen.progressOn(vorlage.id, heute), 1);
      expect(gelesen.toJson().containsKey('progress'), isFalse);
    });
  });
}
