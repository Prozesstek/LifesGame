import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Der Wochenrückblick: was eine Woche gebracht hat, aus der Historie
/// gerechnet.
void main() {
  // Mittwoch. Die Woche läuft von Montag, 21.09., bis Sonntag, 27.09.
  const mittwoch = Day(2026, 9, 23);
  const montag = Day(2026, 9, 21);
  const sonntag = Day(2026, 9, 27);

  CustomHabit eigene(String id, HabitStat stat) {
    return CustomHabit(
      id: id,
      name: id,
      stat: stat,
      difficulty: HabitDifficulty.mittel,
      priority: HabitPriority.normal,
    );
  }

  HabitTracker zwei() {
    return const HabitTracker.empty()
        .addCustom(eigene('kraft', HabitStat.staerke), slots: 5)
        .addCustom(eigene('lauf', HabitStat.ausdauer), slots: 5)
        .activate('kraft')
        .activate('lauf');
  }

  HabitTracker abgehakt(HabitTracker t, String id, Iterable<Day> tage) {
    var tracker = t;
    for (final tag in tage) {
      tracker = tracker.check(id, tag).tracker;
    }
    return tracker;
  }

  group('Der Tag', () {
    test('kennt seinen Wochentag und den Montag seiner Woche', () {
      expect(montag.weekday, DateTime.monday);
      expect(sonntag.weekday, DateTime.sunday);
      expect(mittwoch.startOfWeek, montag);
      expect(sonntag.startOfWeek, montag);
      expect(montag.startOfWeek, montag);
    });
  });

  group('Die Woche', () {
    test('läuft von Montag bis Sonntag', () {
      final woche = zwei().weekOf(mittwoch, today: mittwoch);
      expect(woche.start, montag);
      expect(woche.end, sonntag);
      expect(woche.days, hasLength(7));
      expect(woche.days.first.day, montag);
    });

    test('zählt Häkchen und aktive Tage nur in der Woche', () {
      final vorwoche = <Day>[montag.previous, montag.previous.previous];
      var t = abgehakt(zwei(), 'kraft', <Day>[...vorwoche, montag, mittwoch]);
      t = abgehakt(t, 'lauf', <Day>[mittwoch]);
      final woche = t.weekOf(mittwoch, today: mittwoch);

      expect(woche.checks, 3);
      expect(woche.activeDays, 2);
    });

    test('Erfahrung zählt die Kette über die Wochengrenze mit', () {
      // Die Kette läuft seit Samstag. Das Häkchen am Montag ist ihr
      // drittes und bringt deshalb den Multiplikator des dritten Tags.
      final samstag = montag.previous.previous;
      final t = abgehakt(zwei(), 'kraft', <Day>[
        samstag,
        samstag.next,
        montag,
      ]);
      final woche = t.weekOf(montag, today: montag);

      expect(woche.xp, HabitRewards.xpFor(3));
    });

    test('Gold aus Häkchen und Truhen der Woche', () {
      var t = abgehakt(zwei(), 'kraft', <Day>[montag]);
      t = abgehakt(t, 'lauf', <Day>[montag]);
      t = t.openChest(montag).tracker;
      final woche = t.weekOf(mittwoch, today: mittwoch);

      expect(woche.chests, 1);
      expect(
        woche.gold,
        2 * HabitRewards.goldPerCheck + DailyChest.forDay(montag).gold,
      );
    });

    test('gewonnene Punkte sind die Differenz über die Woche', () {
      // Fünf Häkchen Stärke sind ein Punkt (StatCurve), vier davon in der
      // Vorwoche. Das fünfte fällt am Montag.
      var tag = montag;
      final vorher = <Day>[];
      for (var i = 0; i < 4; i++) {
        tag = tag.previous;
        vorher.add(tag);
      }
      final t = abgehakt(zwei(), 'kraft', <Day>[...vorher, montag]);
      final woche = t.weekOf(mittwoch, today: mittwoch);

      expect(woche.gainFor(HabitStat.staerke), 1);
      expect(woche.gainFor(HabitStat.ausdauer), 0);
    });

    test('die Tagespunkte: leer, erledigt, voll mit Truhe, noch nicht', () {
      var t = abgehakt(zwei(), 'kraft', <Day>[montag, montag.next]);
      t = abgehakt(t, 'lauf', <Day>[montag]);
      t = t.openChest(montag).tracker;
      final woche = t.weekOf(mittwoch, today: mittwoch);

      expect(woche.days[0].state, WeekDayState.chest);
      expect(woche.days[1].state, WeekDayState.some);
      expect(woche.days[2].state, WeekDayState.none, reason: 'heute, leer');
      expect(woche.days[3].state, WeekDayState.future);
    });

    test('der Vergleich zur Vorwoche', () {
      final vorwoche = montag.previous;
      final t = abgehakt(zwei(), 'kraft', <Day>[vorwoche, montag, mittwoch]);

      expect(t.weekOf(mittwoch, today: mittwoch).activeDays, 2);
      expect(t.weekOf(vorwoche, today: mittwoch).activeDays, 1);
    });
  });

  test('die Gesamterfahrung ist unverändert die Summe über alles', () {
    final t = abgehakt(zwei(), 'kraft', <Day>[
      montag.previous,
      montag,
      mittwoch,
    ]);
    expect(
      t.totalXp,
      HabitRewards.xpFor(1) + HabitRewards.xpFor(2) + HabitRewards.xpFor(1),
    );
  });
}
