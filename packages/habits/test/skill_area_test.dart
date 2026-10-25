import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Das Gebiet einer Gewohnheit und ihr Anteil am Skill
/// ([ADR-0085](../../../docs/decisions/0085-skills-je-gebiet.md)).
///
/// Die Zusage, auf die es ankommt: **Ein Skill kann nur wachsen.** Das
/// Gebiet einer eigenen Gewohnheit lässt sich deshalb genau einmal
/// setzen — und nur, wenn sie noch keins hat.
void main() {
  const heute = Day(2026, 10, 22);

  CustomHabit eigene(String id, SkillArea? area) {
    return CustomHabit(
      id: id,
      name: 'Freund anrufen',
      statOhneGebiet: HabitStat.disziplin,
      area: area,
      difficulty: HabitDifficulty.mittel,
    );
  }

  /// [tage] Tage am Stück abgehakt, bis einschließlich [heute].
  HabitTracker abgehakt(HabitTracker t, String id, int tage) {
    var tag = heute;
    for (var i = 1; i < tage; i++) {
      tag = tag.previous;
    }
    var tracker = t.activate(id);
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(id, tag).tracker;
      tag = tag.next;
    }
    return tracker;
  }

  group('Vorlagen', () {
    test('jede hat ein Gebiet, und jedes Gebiet hat eine Vorlage', () {
      final gebiete = <SkillArea>{
        for (final vorlage in HabitCatalog.all) vorlage.area,
      };
      expect(gebiete, SkillArea.values.toSet());
    });
  });

  group('Erfahrung je Gebiet', () {
    test('ein Gebiet zählt nur seine Gewohnheiten, mit Kette', () {
      final koerper = HabitCatalog.all.firstWhere(
        (h) => h.area == SkillArea.koerper,
      );
      final geist = HabitCatalog.all.firstWhere(
        (h) => h.area == SkillArea.geist,
      );
      var t = abgehakt(const HabitTracker.empty(), koerper.id, 7);
      t = abgehakt(t, geist.id, 2);

      // 2 × 15, 4 × 18, 1 × 21 — derselbe Kettenbonus wie fürs Level.
      expect(t.xpIn(SkillArea.koerper), 30 + 72 + 21);
      expect(t.xpIn(SkillArea.geist), 30);
      expect(t.xpIn(SkillArea.wissenschaft), 0);
      expect(
        SkillArea.values.fold(0, (sum, a) => sum + t.xpIn(a)),
        t.totalXp,
      );
    });

    test('eine eigene ohne Gebiet zählt fürs Level, aber für keinen Skill', () {
      var t = const HabitTracker.empty().addCustom(
        eigene('eigen-1', null),
        slots: 5,
      );
      t = abgehakt(t, 'eigen-1', 3);

      expect(t.totalXp, greaterThan(0));
      for (final area in SkillArea.values) {
        expect(t.xpIn(area), 0);
      }
    });

    test('mit Gebiet zählt ihre ganze Historie — rückwirkend', () {
      var t = const HabitTracker.empty().addCustom(
        eigene('eigen-1', null),
        slots: 5,
      );
      t = abgehakt(t, 'eigen-1', 3);
      final vorher = t.totalXp;

      t = t.assignArea('eigen-1', SkillArea.gesellschaft);

      expect(t.xpIn(SkillArea.gesellschaft), vorher);
      expect(t.totalXp, vorher);
    });
  });

  group('Das Gebiet einer eigenen Gewohnheit', () {
    test('fehlt nur bei alten — und die stehen in der Liste', () {
      final t = const HabitTracker.empty()
          .addCustom(eigene('eigen-1', null), slots: 5)
          .addCustom(eigene('eigen-2', SkillArea.koerper), slots: 5);

      expect(t.customWithoutArea.map((h) => h.id), <String>['eigen-1']);
    });

    test('lässt sich genau einmal setzen', () {
      final t = const HabitTracker.empty()
          .addCustom(eigene('eigen-1', null), slots: 5)
          .assignArea('eigen-1', SkillArea.geist)
          .assignArea('eigen-1', SkillArea.koerper);

      expect(t.definitionFor('eigen-1')?.area, SkillArea.geist);
      expect(t.customWithoutArea, isEmpty);
    });

    test('ein gesetztes bleibt, auch über withArea', () {
      final habit = eigene('eigen-1', SkillArea.koerper);
      expect(habit.withArea(SkillArea.geist).area, SkillArea.koerper);
    });

    test('bleibt beim Nachbessern von Name und Priorität', () {
      final habit = eigene('eigen-1', SkillArea.wissenschaft);
      expect(habit.editable(name: 'Anders').area, SkillArea.wissenschaft);
    });

    test('übersteht das Speichern', () {
      final t = const HabitTracker.empty().addCustom(
        eigene('eigen-1', SkillArea.gesellschaft),
        slots: 5,
      );
      final gelesen = HabitTracker.fromJson(t.toJson());

      expect(gelesen.definitionFor('eigen-1')?.area, SkillArea.gesellschaft);
    });

    test('ein alter Stand ohne Gebiet lädt — und fragt dann', () {
      final json = eigene('eigen-1', SkillArea.koerper).toJson()
        ..remove('area');
      final gelesen = CustomHabit.fromJson(json);

      expect(gelesen, isNotNull);
      expect(gelesen?.area, isNull);
    });

    test('ein unbekanntes Gebiet wird wie ein fehlendes gelesen', () {
      final json = eigene('eigen-1', SkillArea.koerper).toJson()
        ..['area'] = 'gibt-es-nicht-und-soll-es-nie-geben';

      expect(CustomHabit.fromJson(json)?.area, isNull);
    });
  });

  // ADR-0088: Das Gebiet bestimmt den Kampfwert, man wählt ihn nicht.
  group('Der Kampfwert kommt aus dem Gebiet', () {
    test('jedes Gebiet steigert einen anderen Wert', () {
      expect(
        <SkillArea, HabitStat>{
          for (final area in SkillArea.values) area: area.kampfwert,
        },
        <SkillArea, HabitStat>{
          SkillArea.koerper: HabitStat.staerke,
          SkillArea.geist: HabitStat.klarheit,
          SkillArea.wissenschaft: HabitStat.disziplin,
          SkillArea.gesellschaft: HabitStat.ausdauer,
        },
      );
      for (final stat in HabitStat.values) {
        expect(stat.gebiet.kampfwert, stat, reason: stat.label);
      }
    });

    test('heißt, was er in der Grube tut', () {
      expect(HabitStat.values.map((s) => s.label), <String>[
        'Angriff',
        'Leben',
        'Abwehr',
        'Mana',
      ]);
    });

    test('jede Vorlage steigert den Wert ihres Gebiets', () {
      for (final vorlage in HabitCatalog.all) {
        expect(vorlage.stat, vorlage.area.kampfwert, reason: vorlage.name);
      }
    });

    test('eine eigene mit Gebiet ignoriert den alten Wert', () {
      final eigen = eigene('eigen-1', SkillArea.gesellschaft);

      expect(eigen.statOhneGebiet, HabitStat.disziplin);
      expect(eigen.stat, HabitStat.ausdauer);
    });

    test('ohne Gebiet zählt der alte Wert, bis sie eins hat', () {
      var t = abgehakt(
        const HabitTracker.empty().addCustom(eigene('eigen-1', null), slots: 5),
        'eigen-1',
        12,
      );
      expect(t.stats.checksFor(HabitStat.disziplin), 12);

      // Rückwirkend: Die zwölf Häkchen wandern mit in den neuen Wert.
      t = t.assignArea('eigen-1', SkillArea.geist);
      expect(t.stats.checksFor(HabitStat.disziplin), 0);
      expect(t.stats.checksFor(HabitStat.klarheit), 12);
    });

    test('ein neuer Stand ohne „stat“ lädt über das Gebiet', () {
      final json = eigene('eigen-1', SkillArea.wissenschaft).toJson()
        ..remove('stat');
      final gelesen = CustomHabit.fromJson(json);

      expect(gelesen?.stat, HabitStat.disziplin);
    });

    test('ohne Gebiet und ohne Wert wird sie verworfen', () {
      final json = eigene('eigen-1', SkillArea.koerper).toJson()
        ..remove('stat')
        ..remove('area');

      expect(CustomHabit.fromJson(json), isNull);
    });

    test('gespeichert steht der Wert, der gilt', () {
      final json = eigene('eigen-1', SkillArea.gesellschaft).toJson();

      expect(json['stat'], HabitStat.ausdauer.name);
    });
  });
}
