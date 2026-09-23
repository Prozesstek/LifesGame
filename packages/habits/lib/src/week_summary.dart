import 'day.dart';
import 'habit.dart';

/// Wie ein Tag im Wochenrückblick aussieht.
enum WeekDayState {
  /// Nichts abgehakt.
  none,

  /// Etwas abgehakt.
  some,

  /// Alles erledigt und die Truhe geöffnet — der volle Tag. Die Truhe ist
  /// das Zeichen dafür, weil „alles erledigt" rückwirkend nicht bestimmbar
  /// ist: Die Liste laufender Gewohnheiten ist die von heute.
  chest,

  /// Liegt noch vor uns.
  future,
}

/// Ein Tag der Woche.
class WeekDay {
  const WeekDay({required this.day, required this.checks, required this.state});

  final Day day;
  final int checks;
  final WeekDayState state;
}

/// **Der Wochenrückblick** — was eine Woche gebracht hat, auf einen Blick.
///
/// Aus der Historie gerechnet ([HabitTracker.weekOf]), nie gespeichert.
/// Er zahlt nichts aus: Die Belohnung ist, es zu sehen.
class WeekSummary {
  const WeekSummary({
    required this.start,
    required this.end,
    required this.days,
    required this.checks,
    required this.xp,
    required this.gold,
    required this.chests,
    required this.foundTreasure,
    required this.freezesFound,
    required Map<HabitStat, int> gains,
    required this.bestStreak,
  }) : _gains = gains;

  /// Montag.
  final Day start;

  /// Sonntag.
  final Day end;

  /// Montag bis Sonntag, genau sieben.
  final List<WeekDay> days;

  final int checks;
  final int xp;

  /// Gold aus Häkchen und Truhen der Woche.
  final int gold;

  final int chests;
  final bool foundTreasure;
  final int freezesFound;
  final Map<HabitStat, int> _gains;

  /// Die beste laufende Kette am Ende der Woche, oder heute.
  final int bestStreak;

  /// Um wie viel [stat] in der Woche gestiegen ist.
  int gainFor(HabitStat stat) => _gains[stat] ?? 0;

  /// Tage mit mindestens einem Häkchen.
  int get activeDays => days.where((d) => d.checks > 0).length;
}
