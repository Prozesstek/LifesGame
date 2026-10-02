import 'day.dart';
import 'rewards.dart';

/// Was mit einem Tag in einer Kette geschieht.
enum StreakDay {
  /// Abgehakt: Die Kette wächst um eins.
  done,

  /// Trägt die Kette, verlängert sie aber nicht — ein Streak-Eis, ein Tag
  /// außerhalb des Wochenplans, eine Pause.
  carried,

  /// Fällig und nicht erledigt: Die Kette fällt auf die letzte Stufe.
  missed,
}

/// **Wie eine Kette läuft** (ADR-0064) — die einzige Stelle, die das
/// entscheidet.
///
/// Die Kette je Gewohnheit, die Tageskette, die längste Kette und die
/// Erfahrung gehen alle hier durch. Stünde die Regel mehrfach da, zeigte
/// die Kachel irgendwann eine andere Kette an, als die Erfahrung
/// unterstellt.
///
/// Gegangen wird **vorwärts** durch die Tage: Ein verpasster Tag setzt die
/// Kette nicht auf null, sondern auf die Stufe darunter
/// ([HabitRewards.streakAfterMiss]) — und das lässt sich nur sagen, wenn
/// man weiß, wie lang sie vorher war.
abstract final class StreakRule {
  /// Geht von [from] bis [to], beide eingeschlossen, und gibt die Kette
  /// am Ende zurück. [onDone] bekommt jeden erledigten Tag samt der Kette,
  /// die er abschließt.
  static int walk({
    required Day from,
    required Day to,
    required StreakDay Function(Day day) stateOf,
    void Function(Day day, int streak)? onDone,
  }) {
    var streak = 0;
    var cursor = from;
    while (cursor <= to) {
      switch (stateOf(cursor)) {
        case StreakDay.done:
          streak++;
          onDone?.call(cursor, streak);
        case StreakDay.carried:
          break;
        case StreakDay.missed:
          streak = HabitRewards.streakAfterMiss(streak);
      }
      cursor = cursor.next;
    }
    return streak;
  }
}
