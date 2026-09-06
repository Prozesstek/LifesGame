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
  ///
  /// Hakt **ganz** ab, auch bei halb gefülltem Tagesziel: Das ist der
  /// Griff für „ich hab's gemacht", nicht für „ein Glas mehr" — dafür
  /// gibt es [advance].
  CheckResult? toggle(String habitId, Day day) {
    if (state.isChecked(habitId, day)) {
      state = state.uncheck(habitId, day);
      return null;
    }
    final result = state.check(habitId, day);
    state = result.tracker;
    return result;
  }

  /// Füllt ein Tagesziel um einen Schritt auf.
  ///
  /// Gibt immer ein Ergebnis zurück — auch das unfertige. Die Oberfläche
  /// unterscheidet über [CheckResult.isComplete], ob es etwas zu feiern
  /// gibt.
  CheckResult advance(String habitId, Day day) {
    final result = state.advance(habitId, day);
    state = result.tracker;
    return result;
  }

  /// Legt eine eigene Gewohnheit an und nimmt sie gleich in die
  /// Tagesliste auf, wenn dort noch Platz ist.
  ///
  /// Gibt null zurück, wenn kein Platz für eine eigene Gewohnheit frei
  /// ist — die Oberfläche fragt vorher über [customSlotsLeftProvider].
  ///
  /// Die Id wird hier vergeben, nicht im Formular: Sie muss neben
  /// **allen** bestehenden eindeutig sein, und die kennt nur der Stand.
  CustomHabit? addCustom({
    required String name,
    required HabitStat stat,
    required HabitDifficulty difficulty,
    HabitGoal? goal,
    HabitPriority priority = HabitPriority.normal,
    String why = '',
  }) {
    final slots = HabitRewards.customSlotsFor(
      ref.read(unlockedHabitsProvider).length,
    );
    if (!state.canAddCustom(slots)) return null;

    final habit = CustomHabit(
      id: CustomHabit.nextId(state.customHabits.map((h) => h.id)),
      name: name.trim(),
      stat: stat,
      difficulty: difficulty,
      goal: goal,
      priority: priority,
      why: why.trim(),
    );

    final angelegt = state.addCustom(habit, slots: slots);
    state = angelegt.canActivate(habit.id)
        ? angelegt.activate(habit.id)
        : angelegt;
    return habit;
  }

  /// Bessert Name, Begründung oder Priorität nach. Wert, Schwierigkeit
  /// und Ziel bleiben, wie sie waren (ADR-0028).
  void editCustom(
    String habitId, {
    String? name,
    String? why,
    HabitPriority? priority,
  }) {
    state = state.editCustom(
      habitId,
      name: name?.trim(),
      why: why?.trim(),
      priority: priority,
    );
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

/// Wie viele eigene Gewohnheiten insgesamt erlaubt sind.
///
/// **Ein Platz je freigeschalteter Vorlage** (ADR-0028). Damit hängen
/// eigene Gewohnheiten am Baum, ohne aus ihm zu stammen: Der Weg „erst
/// verstehen, dann verfolgen" bleibt der Motor, aber was am Ende auf der
/// Liste steht, entscheidet der Spieler.
///
/// Die Zahl selbst steht in `package:habits`, nicht hier.
final customSlotsProvider = Provider<int>((ref) {
  return HabitRewards.customSlotsFor(ref.watch(unlockedHabitsProvider).length);
});

/// Wie viele Plätze davon noch frei sind.
final customSlotsLeftProvider = Provider<int>((ref) {
  final frei =
      ref.watch(customSlotsProvider) -
      ref.watch(habitTrackerProvider).customCount;
  return frei < 0 ? 0 : frei;
});

/// Die Kampfwerte, die sich aus den Gewohnheiten ergeben.
final characterStatsProvider = Provider<CharacterStats>((ref) {
  return ref.watch(habitTrackerProvider).stats;
});
