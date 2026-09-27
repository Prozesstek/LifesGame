import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Die Tageskette ([ADR-0055](../../../docs/decisions/0055-tageskette-aufgaben-und-wiederholen.md)):
/// Tage am Stück mit mindestens einem Häkchen, egal an welcher Gewohnheit.
void main() {
  const heute = Day(2026, 9, 27);
  final a = HabitCatalog.all[0];
  final b = HabitCatalog.all[1];

  HabitTracker mit(Map<String, List<Day>> tage) {
    var t = const HabitTracker.empty();
    for (final id in tage.keys) {
      t = t.activate(id);
    }
    for (final MapEntry(key: id, value: days) in tage.entries) {
      for (final day in days) {
        t = t.check(id, day).tracker;
      }
    }
    return t;
  }

  test('ohne Häkchen gibt es keine', () {
    expect(const HabitTracker.empty().currentDayStreak(heute), 0);
  });

  test('wechselnde Gewohnheiten tragen die Kette gemeinsam', () {
    // Jede Gewohnheit für sich hat nur Ein-Tages-Ketten — der Tag zählt
    // trotzdem durchgehend.
    final t = mit(<String, List<Day>>{
      a.id: <Day>[heute, heute.previous.previous],
      b.id: <Day>[heute.previous],
    });

    expect(t.currentDayStreak(heute), 3);
    expect(t.currentStreak(a.id, heute), 1);
  });

  test('eine ausgelassene Gewohnheit reißt sie nicht', () {
    final t = mit(<String, List<Day>>{
      a.id: <Day>[heute, heute.previous],
      b.id: <Day>[heute.previous.previous],
    });

    expect(t.currentDayStreak(heute), 3);
  });

  test('sie stirbt erst, wenn der Tag vorbei ist', () {
    final t = mit(<String, List<Day>>{
      a.id: <Day>[heute.previous, heute.previous.previous],
    });

    expect(t.currentDayStreak(heute), 2, reason: 'heute ist noch offen');
    expect(t.currentDayStreak(heute.next), 0, reason: 'gestern verpasst');
  });

  test('ein Streak-Eis trägt sie, ohne sie zu verlängern', () {
    final gestern = heute.previous;
    final vorgestern = gestern.previous;
    final t = mit(<String, List<Day>>{
      a.id: <Day>[heute, vorgestern],
    }).freeze(gestern, today: heute);

    expect(t.isFrozen(gestern), isTrue);
    expect(t.currentDayStreak(heute), 2);
  });

  test('der Bestwert bleibt, wenn die Kette reißt', () {
    final t = mit(<String, List<Day>>{
      a.id: <Day>[
        heute.previous.previous.previous.previous,
        heute.previous.previous.previous,
        heute.previous.previous,
        heute,
      ],
    });

    expect(t.currentDayStreak(heute), 1);
    expect(t.longestDayStreak, 3);
  });
}
