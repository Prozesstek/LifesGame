import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../save/save_providers.dart';
import '../theory/theory_controller.dart';

/// Der heutige Kalendertag.
///
/// Eigener Provider, damit Tests einen festen Tag setzen können — sonst
/// wäre jeder Streak-Test vom Systemdatum abhängig.
///
/// Achtung: Der Wert wird nicht von selbst neu berechnet. Wer die App über
/// Mitternacht offen lässt, sieht bis zum Neustart den gestrigen Tag —
/// beim nächsten Start stimmt er wieder. Ein Wecker auf Mitternacht wäre
/// die saubere Lösung und steht in `docs/context/state.md`.
final todayProvider = Provider<Day>((ref) => Day.from(DateTime.now()));

/// Bindeglied zwischen dem Gewohnheits-Modell und der Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Was ein Häkchen einbringt, wie lange
/// eine Streak lebt und wie viele Gewohnheiten gleichzeitig laufen dürfen,
/// steht in `package:habits`.
///
/// Der Anfangsstand kommt aus dem Speicher (ADR-0010). Gespeichert wird
/// nicht hier, sondern an einer Stelle für alle drei Bereiche —
/// `lib/save/save_watcher.dart`.
class HabitsController extends Notifier<HabitTracker> {
  @override
  HabitTracker build() => ref.watch(savedGameProvider).habits;

  void activate(String habitId) {
    state = state.activate(habitId);
  }

  void deactivate(String habitId) {
    state = state.deactivate(habitId);
  }

  /// Hakt ab oder nimmt das Häkchen zurück.
  ///
  /// Gibt das Ergebnis zurück, wenn dabei etwas verdient wurde — sonst
  /// null. Die Oberfläche zeigt daraufhin die Rückmeldung an.
  CheckResult? toggle(String habitId, Day day) {
    if (state.isChecked(habitId, day)) {
      state = state.uncheck(habitId, day);
      return null;
    }
    final result = state.check(habitId, day);
    state = result.tracker;
    return result;
  }
}

final habitTrackerProvider = NotifierProvider<HabitsController, HabitTracker>(
  HabitsController.new,
);

/// Die Vorlagen, die der Skillbaum bereits freigeschaltet hat.
///
/// Hier treffen sich zwei Packages, die einander nicht kennen: `theory`
/// liefert Namen freigeschalteter Vorlagen, `habits` löst sie in Vorlagen
/// auf. Dass beide Listen zueinander passen, prüft
/// `test/habits_theory_test.dart`.
final unlockedHabitsProvider = Provider<List<HabitTemplate>>((ref) {
  final progress = ref.watch(theoryProgressProvider);
  final names = <String>[
    for (final branch in theoryTree.branches)
      ...progress.unlockedHabits(branch),
  ];
  return HabitCatalog.byNames(names);
});

/// Die Kampfwerte, die sich aus den Gewohnheiten ergeben.
final characterStatsProvider = Provider<CharacterStats>((ref) {
  return ref.watch(habitTrackerProvider).stats;
});
