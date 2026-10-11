import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits/habits_controller.dart';
import '../save/save_providers.dart';
import 'ladder_controller.dart';

/// Die Versuche in der Tagesgrube — die Riverpod-Brücke zum Spielstand
/// (ADR-0072).
///
/// **Enthält keine Regeln.** Was ein Versuch ist, wann er zählt und was
/// er einbringt, steht in `package:action_combat` (`DailyPit`,
/// `DailyPitLog`, `DailyPitRewards`); hier steht nur, wo der Wert
/// herkommt und wohin er geht.
class DailyPitController extends Notifier<DailyPitLog> {
  @override
  DailyPitLog build() => ref.watch(savedGameProvider).dailyPit;

  /// Der Versuch des Tages [day] beginnt — und ist damit gebraucht.
  ///
  /// Gibt zurück, ob er begonnen hat. `false` heißt: An dem Tag ist schon
  /// jemand hinabgestiegen.
  bool start(int day, DailyCondition condition) {
    if (state.hasStarted(day)) return false;
    state = state.start(day, condition: condition);
    return true;
  }

  /// Trägt ein, wie der Versuch von [day] ausging.
  ///
  /// **Der Tag kommt vom Start, nicht von der Uhr**: Wer um 23:59
  /// hinabsteigt und um 00:01 gewinnt, hat gestern gewonnen.
  DailyRun? finish(int day, ActionWorld world) {
    state = state.finish(day, world);
    return state.runOn(day);
  }

  /// Gibt den Versuch von [day] wieder frei. Nur der Entwicklermodus ruft
  /// das.
  void reset(int day) {
    state = state.without(day);
  }
}

final dailyPitProvider = NotifierProvider<DailyPitController, DailyPitLog>(
  DailyPitController.new,
);

/// In welcher Verfassung jemand heute hinabstiege — **rechnet nicht**,
/// fragt `HabitTracker`.
///
/// Ein Tag, an dem nichts fällig ist, ist ein Ruhetag und nicht in Form
/// (ADR-0064); alles Fällige erledigt heißt in Form. Ob das eine
/// Gewohnheit war oder fünf, spielt keine Rolle.
final dailyConditionProvider = Provider<DailyCondition>((ref) {
  final tracker = ref.watch(habitTrackerProvider);
  final heute = ref.watch(todayProvider);
  if (tracker.dueIdsOn(heute).isEmpty) return DailyCondition.ruhetag;
  return tracker.isDayComplete(heute)
      ? DailyCondition.inForm
      : DailyCondition.ohneForm;
});

/// Die Tagesgrube von heute, wie der Eingang sie zeigt.
typedef DailyPitToday = ({
  /// Tage seit dem 1.1.1970 — an ihm hängen Karte und Satz.
  int day,

  /// Die laufende Nummer, „#12“.
  int number,
  DailyLoadout loadout,
  DailyCondition condition,

  /// Wie viele fällige Gewohnheiten heute noch offen sind.
  int open,

  /// Der Versuch von heute, falls es schon einen gibt.
  DailyRun? run,
});

/// Die Tagesgrube von heute — **rechnet nicht**, fragt `DailyPit`,
/// `DailyPitLog` und `HabitTracker`.
final todayDailyPitProvider = Provider<DailyPitToday>((ref) {
  final heute = ref.watch(todayProvider);
  final tag = dayNumberOf(heute);
  final tracker = ref.watch(habitTrackerProvider);
  return (
    day: tag,
    number: DailyPit.numberFor(tag),
    loadout: DailyPit.loadoutFor(tag),
    condition: ref.watch(dailyConditionProvider),
    open: tracker
        .dueIdsOn(heute)
        .where((id) => !tracker.isChecked(id, heute))
        .length,
    run: ref.watch(dailyPitProvider).runOn(tag),
  );
});
