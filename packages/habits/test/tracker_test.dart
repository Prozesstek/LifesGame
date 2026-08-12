import 'package:habits/habits.dart';
import 'package:test/test.dart';

const Day _tag1 = Day(2026, 8, 10);
final Day _tag2 = _tag1.next;
final Day _tag3 = _tag2.next;

/// Eine Gewohnheit je Charakterwert — damit die Tests nicht davon abhängen,
/// welche Vorlage gerade an welcher Stelle im Katalog steht.
HabitTemplate _templateFor(HabitStat stat) {
  return HabitCatalog.all.firstWhere((t) => t.stat == stat);
}

HabitTracker _withActive(List<String> ids) {
  var tracker = const HabitTracker.empty();
  for (final id in ids) {
    tracker = tracker.activate(id);
  }
  return tracker;
}

/// Hakt [id] an [days] aufeinanderfolgenden Tagen ab Tag 1 ab.
HabitTracker _streak(HabitTracker tracker, String id, int days) {
  var current = tracker;
  var day = _tag1;
  for (var i = 0; i < days; i++) {
    current = current.check(id, day).tracker;
    day = day.next;
  }
  return current;
}

void main() {
  final staerke = _templateFor(HabitStat.staerke);
  final ausdauer = _templateFor(HabitStat.ausdauer);

  group('Gewohnheiten wählen', () {
    test('ein frischer Tracker hat nichts laufen', () {
      const tracker = HabitTracker.empty();

      expect(tracker.activeIds, isEmpty);
      expect(tracker.totalXp, 0);
      expect(tracker.totalGold, 0);
      expect(tracker.stats.attack, 13);
    });

    test('aktivieren fügt hinzu, ohne den alten Stand zu ändern', () {
      const before = HabitTracker.empty();
      final after = before.activate(staerke.id);

      expect(before.activeIds, isEmpty);
      expect(after.activeIds, <String>[staerke.id]);
      expect(after.activeTemplates.single.id, staerke.id);
    });

    test('dieselbe Vorlage lässt sich nicht zweimal aktivieren', () {
      final tracker = _withActive(<String>[staerke.id, staerke.id]);

      expect(tracker.activeIds, hasLength(1));
      expect(tracker.canActivate(staerke.id), isFalse);
    });

    test('unbekannte Vorlagen werden nicht aktiv', () {
      const tracker = HabitTracker.empty();

      expect(tracker.canActivate('gibt-es-nicht'), isFalse);
      expect(tracker.activate('gibt-es-nicht').activeIds, isEmpty);
    });

    test('die Obergrenze hält', () {
      final ids = HabitCatalog.all
          .take(HabitRewards.maxActiveHabits + 1)
          .map((t) => t.id)
          .toList();
      final tracker = _withActive(ids);

      expect(tracker.activeIds, hasLength(HabitRewards.maxActiveHabits));
      expect(tracker.isFull, isTrue);
      expect(tracker.canActivate(ids.last), isFalse);
    });

    test('deaktivieren nimmt aus der Liste, behält aber die Historie', () {
      var tracker = _withActive(<String>[staerke.id]);
      tracker = tracker.check(staerke.id, _tag1).tracker;
      final stopped = tracker.deactivate(staerke.id);

      expect(stopped.activeIds, isEmpty);
      expect(stopped.checksFor(staerke.id), 1);
      expect(stopped.stats.attack, tracker.stats.attack);
      expect(stopped.totalXp, tracker.totalXp);
    });
  });

  group('Abhaken', () {
    test('erstes Häkchen bringt den Grundbetrag', () {
      final tracker = _withActive(<String>[staerke.id]);
      final result = tracker.check(staerke.id, _tag1);

      expect(result.streak, 1);
      expect(result.multiplier, 1.0);
      expect(result.xpGained, HabitRewards.xpPerCheck);
      expect(result.goldGained, HabitRewards.goldPerCheck);
      expect(result.wasAlreadyChecked, isFalse);
      expect(result.tracker.isChecked(staerke.id, _tag1), isTrue);
    });

    test('zweites Häkchen am selben Tag ändert nichts', () {
      var tracker = _withActive(<String>[staerke.id]);
      tracker = tracker.check(staerke.id, _tag1).tracker;
      final again = tracker.check(staerke.id, _tag1);

      expect(again.wasAlreadyChecked, isTrue);
      expect(again.xpGained, 0);
      expect(again.goldGained, 0);
      expect(again.tracker.totalChecks, 1);
    });

    test('eine Gewohnheit, die nicht läuft, lässt sich nicht abhaken', () {
      const tracker = HabitTracker.empty();

      expect(() => tracker.check(staerke.id, _tag1), throwsStateError);
    });

    test('Häkchen zurücknehmen nimmt auch die Erfahrung zurück', () {
      var tracker = _withActive(<String>[staerke.id]);
      tracker = tracker.check(staerke.id, _tag1).tracker;
      final undone = tracker.uncheck(staerke.id, _tag1);

      expect(undone.isChecked(staerke.id, _tag1), isFalse);
      expect(undone.totalXp, 0);
      expect(undone.totalGold, 0);
      expect(undone.stats.attack, 13);
    });

    test('completedOn und isDayComplete sehen nur laufende Gewohnheiten', () {
      var tracker = _withActive(<String>[staerke.id, ausdauer.id]);

      expect(tracker.isDayComplete(_tag1), isFalse);
      tracker = tracker.check(staerke.id, _tag1).tracker;
      expect(tracker.completedOn(_tag1), 1);
      tracker = tracker.check(ausdauer.id, _tag1).tracker;
      expect(tracker.isDayComplete(_tag1), isTrue);
    });

    test('ein leerer Tag ist nicht vollständig', () {
      const tracker = HabitTracker.empty();

      expect(tracker.isDayComplete(_tag1), isFalse);
    });
  });

  group('Streaks', () {
    test('drei Tage am Stück ergeben Streak 3', () {
      final tracker = _streak(_withActive(<String>[staerke.id]), staerke.id, 3);

      expect(tracker.streakEndingAt(staerke.id, _tag3), 3);
      expect(tracker.currentStreak(staerke.id, _tag3), 3);
    });

    test('eine Lücke setzt die Kette zurück', () {
      var tracker = _withActive(<String>[staerke.id]);
      tracker = tracker.check(staerke.id, _tag1).tracker;
      // Tag 2 ausgelassen.
      final result = tracker.check(staerke.id, _tag3);

      expect(result.streak, 1);
      expect(result.xpGained, HabitRewards.xpPerCheck);
    });

    test('ein verpasster Vormittag löscht die Streak noch nicht', () {
      // Die Kette endete gestern, heute ist noch nicht abgehakt. Sie zählt
      // weiter, bis der Tag vorbei ist.
      final tracker = _streak(_withActive(<String>[staerke.id]), staerke.id, 3);
      final heute = _tag3.next;

      expect(tracker.isChecked(staerke.id, heute), isFalse);
      expect(tracker.currentStreak(staerke.id, heute), 3);
      // Das Häkchen von heute wäre der vierte Tag — noch im Band von x1,2.
      expect(tracker.nextMultiplier(staerke.id, heute), 1.2);
    });

    test('zwei verpasste Tage beenden sie', () {
      final tracker = _streak(_withActive(<String>[staerke.id]), staerke.id, 3);
      final uebermorgen = _tag3.next.next;

      expect(tracker.currentStreak(staerke.id, uebermorgen), 0);
      expect(tracker.nextMultiplier(staerke.id, uebermorgen), 1.0);
    });

    test('der Meilenstein wird genau einmal gemeldet', () {
      var tracker = _withActive(<String>[staerke.id]);
      var day = _tag1;
      final gemeldet = <int>[];

      for (var i = 0; i < 8; i++) {
        final result = tracker.check(staerke.id, day);
        final milestone = result.reachedMilestone;
        if (milestone != null) gemeldet.add(milestone.days);
        tracker = result.tracker;
        day = day.next;
      }

      expect(gemeldet, <int>[3, 7]);
    });

    test('Streaks laufen je Gewohnheit getrennt', () {
      var tracker = _withActive(<String>[staerke.id, ausdauer.id]);
      tracker = _streak(tracker, staerke.id, 3);
      tracker = tracker.check(ausdauer.id, _tag3).tracker;

      expect(tracker.currentStreak(staerke.id, _tag3), 3);
      expect(tracker.currentStreak(ausdauer.id, _tag3), 1);
    });
  });

  group('Ertrag', () {
    test('Erfahrung nutzt den Multiplikator des jeweiligen Tages', () {
      final tracker = _streak(_withActive(<String>[staerke.id]), staerke.id, 4);

      // Tage 1 und 2 einfach, ab Tag 3 mit x1,2.
      final erwartet = HabitRewards.xpFor(1) +
          HabitRewards.xpFor(2) +
          HabitRewards.xpFor(3) +
          HabitRewards.xpFor(4);
      expect(tracker.totalXp, erwartet);
      expect(tracker.totalXp, greaterThan(4 * HabitRewards.xpPerCheck));
    });

    test('eine unterbrochene Kette bringt weniger als eine durchgehende', () {
      final durchgehend = _streak(
        _withActive(<String>[staerke.id]),
        staerke.id,
        6,
      );

      var lueckenhaft = _withActive(<String>[staerke.id]);
      var day = _tag1;
      for (var i = 0; i < 11; i++) {
        if (i.isEven) lueckenhaft = lueckenhaft.check(staerke.id, day).tracker;
        day = day.next;
      }

      expect(lueckenhaft.totalChecks, durchgehend.totalChecks);
      expect(lueckenhaft.totalXp, lessThan(durchgehend.totalXp));
    });

    test('Gold hängt nur an der Zahl der Häkchen', () {
      final tracker = _streak(_withActive(<String>[staerke.id]), staerke.id, 5);

      expect(tracker.totalGold, 5 * HabitRewards.goldPerCheck);
    });

    test('die Reihenfolge des Abhakens ändert die Erfahrung nicht', () {
      final vorwaerts = _streak(
        _withActive(<String>[staerke.id]),
        staerke.id,
        3,
      );

      var rueckwaerts = _withActive(<String>[staerke.id]);
      for (final day in <Day>[_tag3, _tag2, _tag1]) {
        rueckwaerts = rueckwaerts.check(staerke.id, day).tracker;
      }

      expect(rueckwaerts.totalXp, vorwaerts.totalXp);
    });
  });

  group('Charakterwerte', () {
    test('Häkchen erhöhen den Wert, den die Vorlage speist', () {
      var tracker = _withActive(<String>[staerke.id]);
      final rule = StatCurve.ruleFor(HabitStat.staerke);
      tracker = _streak(tracker, staerke.id, rule.checksPerPoint);

      expect(tracker.stats.attack, rule.base + rule.pointStep);
      expect(tracker.stats.maxHp, StatCurve.ruleFor(HabitStat.ausdauer).base);
    });

    test('checksToNextPoint zeigt, wie weit es noch ist', () {
      var tracker = _withActive(<String>[staerke.id]);
      tracker = _streak(tracker, staerke.id, 2);

      expect(tracker.stats.checksToNextPoint(HabitStat.staerke), 3);
      expect(tracker.stats.isAtCap(HabitStat.staerke), isFalse);
    });

    test('totalChecks zählt über alle Gewohnheiten', () {
      var tracker = _withActive(<String>[staerke.id, ausdauer.id]);
      tracker = tracker.check(staerke.id, _tag1).tracker;
      tracker = tracker.check(ausdauer.id, _tag1).tracker;

      expect(tracker.stats.totalChecks, 2);
    });
  });
}
