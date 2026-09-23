import 'habit.dart';
import 'rewards.dart';

/// **Die Tagesform** — was heute abgehakt ist, macht heute stärker.
///
/// Jedes Häkchen hebt den Wert, den seine Gewohnheit trägt, um
/// [HabitRewards.formPerCheck]; ist jede laufende Gewohnheit erledigt,
/// kommt [HabitRewards.formAllDone] auf alle vier dazu.
///
/// Abgeleitet, nie gespeichert: [HabitTracker.formOn] zählt sie aus den
/// Häkchen des Tages. Um Mitternacht ist sie weg, ohne dass jemand sie
/// zurücksetzt. Sie kennt keine Kampfzahlen — die App reicht die Faktoren
/// in den Kampf.
class DailyForm {
  const DailyForm({
    required Map<HabitStat, int> checksByStat,
    required this.isInForm,
  }) : _checksByStat = checksByStat;

  /// Ein Tag ohne Häkchen: jeder Faktor 1.
  const DailyForm.none()
      : _checksByStat = const <HabitStat, int>{},
        isInForm = false;

  final Map<HabitStat, int> _checksByStat;

  /// Ob heute jede laufende Gewohnheit erledigt ist.
  final bool isInForm;

  /// Heutige Häkchen auf [stat].
  int checksFor(HabitStat stat) => _checksByStat[stat] ?? 0;

  /// Um wie viel [stat] heute vervielfacht wird, 1 heisst unverändert.
  double factorFor(HabitStat stat) {
    return 1 +
        checksFor(stat) * HabitRewards.formPerCheck +
        (isInForm ? HabitRewards.formAllDone : 0);
  }

  /// Ob die Tagesform überhaupt etwas tut.
  bool get isActive => isInForm || _checksByStat.values.any((n) => n > 0);
}
