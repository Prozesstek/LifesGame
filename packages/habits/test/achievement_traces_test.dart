import 'package:habits/habits.dart';
import 'package:test/test.dart';

const Day _tag1 = Day(2026, 8, 10);

/// Tag 1 plus [n] Tage. Von Hand aneinandergereihte `next`-Aufrufe haben
/// beim Schreiben dieser Datei prompt zu einem falschen Test geführt.
Day _plus(int n) {
  var day = _tag1;
  for (var i = 0; i < n; i++) {
    day = day.next;
  }
  return day;
}

/// Die Zahlen, die `package:achievements` aus dem Tracker liest
/// (ADR-0033). Sie stehen hier, weil Streaks und Häkchen laut
/// Schichtregel nur in diesem Package gerechnet werden.
void main() {
  /// Drei Vorlagen mit verschiedenen Charakterwerten — damit sich an
  /// einem Tag mehr als ein Häkchen setzen lässt.
  final vorlagen = <HabitTemplate>[
    for (final stat in HabitStat.values)
      HabitCatalog.all.firstWhere((t) => t.stat == stat),
  ];

  HabitTracker mitAktiven(int anzahl) {
    var tracker = const HabitTracker.empty();
    for (final vorlage in vorlagen.take(anzahl)) {
      tracker = tracker.activate(vorlage.id);
    }
    return tracker;
  }

  /// Hakt an [tage] aufeinanderfolgenden Tagen ab [start] je [proTag]
  /// Gewohnheiten ab.
  HabitTracker abhaken(
    HabitTracker tracker, {
    required Day start,
    required int tage,
    required int proTag,
  }) {
    var current = tracker;
    var day = start;
    for (var i = 0; i < tage; i++) {
      for (final vorlage in vorlagen.take(proTag)) {
        current = current.check(vorlage.id, day).tracker;
      }
      day = day.next;
    }
    return current;
  }

  group('Häkchen je Tag', () {
    test('ein leerer Tracker zählt nichts', () {
      const tracker = HabitTracker.empty();
      expect(tracker.checksOn(_tag1), 0);
      expect(tracker.daysWithAtLeast(3), 0);
      expect(tracker.longestRunWithAtLeast(3), 0);
    });

    test('gezählt wird über alle Gewohnheiten zusammen', () {
      final tracker = abhaken(mitAktiven(3), start: _tag1, tage: 1, proTag: 3);

      expect(tracker.checksOn(_tag1), 3);
      expect(tracker.checksOn(_tag1.next), 0);
    });

    test('zwei Häkchen erfüllen die Marke von drei nicht', () {
      final tracker = abhaken(mitAktiven(3), start: _tag1, tage: 10, proTag: 2);

      expect(tracker.daysWithAtLeast(3), 0);
      expect(tracker.daysWithAtLeast(2), 10);
    });

    test('vierzehn volle Tage ergeben Durchatmen', () {
      final tracker = abhaken(mitAktiven(3), start: _tag1, tage: 14, proTag: 3);

      expect(tracker.daysWithAtLeast(3), 14);
      expect(tracker.longestRunWithAtLeast(3), 14);
    });

    test('eine Lücke trennt die Folge, nicht die Summe', () {
      var tracker = abhaken(mitAktiven(3), start: _tag1, tage: 5, proTag: 3);
      // Ein Tag Pause, dann weitere vier.
      final spaeter = _tag1.next.next.next.next.next.next;
      tracker = abhaken(tracker, start: spaeter, tage: 4, proTag: 3);

      expect(tracker.daysWithAtLeast(3), 9);
      expect(tracker.longestRunWithAtLeast(3), 5);
    });

    test('ein gestopptes Häkchen zählt weiter mit', () {
      var tracker = abhaken(mitAktiven(3), start: _tag1, tage: 4, proTag: 3);
      tracker = tracker.deactivate(vorlagen.first.id);

      // Gestoppt heißt nicht gelöscht: Die Historie bleibt, und damit die
      // Errungenschaft (ADR-0028).
      expect(tracker.daysWithAtLeast(3), 4);
    });
  });

  group('Schwere eigene Gewohnheiten', () {
    CustomHabit eigene(String id, HabitDifficulty grad) {
      return CustomHabit(
        id: id,
        name: 'Eigene $id',
        stat: HabitStat.staerke,
        difficulty: grad,
      );
    }

    test('eine Vorlage zählt nie mit', () {
      final tracker = abhaken(mitAktiven(1), start: _tag1, tage: 5, proTag: 1);

      expect(tracker.checksOnCustomWith(HabitDifficulty.mittel), 0);
      expect(tracker.checksOnCustomWith(HabitDifficulty.schwer), 0);
    });

    test('nur der passende Grad zählt', () {
      var tracker = const HabitTracker.empty();
      tracker = tracker.addCustom(
        eigene('hart', HabitDifficulty.schwer),
        slots: 5,
      );
      tracker = tracker.addCustom(
        eigene('sanft', HabitDifficulty.leicht),
        slots: 5,
      );
      tracker = tracker.activate('hart').activate('sanft');

      var day = _tag1;
      for (var i = 0; i < 6; i++) {
        tracker = tracker.check('hart', day).tracker;
        tracker = tracker.check('sanft', day).tracker;
        day = day.next;
      }

      expect(tracker.checksOnCustomWith(HabitDifficulty.schwer), 6);
      expect(tracker.checksOnCustomWith(HabitDifficulty.leicht), 6);
      expect(tracker.checksOnCustomWith(HabitDifficulty.mittel), 0);
    });

    test('zwei schwere Gewohnheiten summieren sich', () {
      var tracker = const HabitTracker.empty();
      tracker = tracker.addCustom(
        eigene('a', HabitDifficulty.schwer),
        slots: 5,
      );
      tracker = tracker.addCustom(
        eigene('b', HabitDifficulty.schwer),
        slots: 5,
      );
      tracker = tracker.activate('a').activate('b');

      var day = _tag1;
      for (var i = 0; i < 15; i++) {
        tracker = tracker.check('a', day).tracker;
        tracker = tracker.check('b', day).tracker;
        day = day.next;
      }

      expect(tracker.checksOnCustomWith(HabitDifficulty.schwer), 30);
    });
  });

  group('Der Stoiker', () {
    test('eine durchgehende Kette zählt nicht', () {
      final tracker = abhaken(mitAktiven(1), start: _tag1, tage: 20, proTag: 1);

      expect(tracker.comebackStreakAfterPause(3), 0);
    });

    test('eine Pause von zwei Tagen reicht nicht', () {
      // Tage 0 bis 4, dann Pause an 5 und 6, weiter ab 7.
      var tracker = abhaken(mitAktiven(1), start: _tag1, tage: 5, proTag: 1);
      tracker = abhaken(tracker, start: _plus(7), tage: 9, proTag: 1);

      expect(tracker.comebackStreakAfterPause(3), 0);
    });

    test('drei Tage Pause und danach sieben Tage ergeben den Stoiker', () {
      // Tage 0 bis 4, Pause an 5, 6, 7, weiter ab 8.
      var tracker = abhaken(mitAktiven(1), start: _tag1, tage: 5, proTag: 1);
      tracker = abhaken(tracker, start: _plus(8), tage: 7, proTag: 1);

      expect(tracker.comebackStreakAfterPause(3), 7);
    });

    test('die erste Kette zählt nie — vor ihr liegt keine Pause', () {
      final tracker = abhaken(mitAktiven(1), start: _tag1, tage: 30, proTag: 1);

      expect(tracker.longestStreak, 30);
      expect(tracker.comebackStreakAfterPause(3), 0);
    });

    test('die längste Kette nach einer Pause gewinnt', () {
      // 0-1, Pause, 6-9, Pause, 16-26.
      var tracker = abhaken(mitAktiven(1), start: _tag1, tage: 2, proTag: 1);
      tracker = abhaken(tracker, start: _plus(6), tage: 4, proTag: 1);
      tracker = abhaken(tracker, start: _plus(16), tage: 11, proTag: 1);

      expect(tracker.comebackStreakAfterPause(3), 11);
    });

    // Punkt 3 aus ADR-0033: Was einmal galt, gilt weiter.
    test('eine kürzere Kette danach nimmt den Stoiker nicht wieder weg', () {
      // 0-2, Pause, 7-13 (sieben Tage), Pause, 20-21.
      var tracker = abhaken(mitAktiven(1), start: _tag1, tage: 3, proTag: 1);
      tracker = abhaken(tracker, start: _plus(7), tage: 7, proTag: 1);
      expect(tracker.comebackStreakAfterPause(3), 7);

      tracker = abhaken(tracker, start: _plus(20), tage: 2, proTag: 1);
      expect(tracker.comebackStreakAfterPause(3), 7);
    });

    test('eine Kette, die nahtlos weiterläuft, wird länger', () {
      // 0-2, Pause, 7-13 -- und dann ohne Lücke weiter bis 15.
      var tracker = abhaken(mitAktiven(1), start: _tag1, tage: 3, proTag: 1);
      tracker = abhaken(tracker, start: _plus(7), tage: 7, proTag: 1);
      tracker = abhaken(tracker, start: _plus(14), tage: 2, proTag: 1);

      expect(tracker.comebackStreakAfterPause(3), 9);
    });
  });
}
