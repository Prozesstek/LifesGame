import 'package:action_combat/action_combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits/habits_controller.dart';
import '../save/save_providers.dart';

/// Wie weit die Gegnerreihe gegangen ist — die Riverpod-Brücke zum
/// Spielstand.
///
/// **Enthält keine Regeln.** Was ein Sieg wert ist und wann er zählt,
/// steht in `package:combat` (`LadderProgress`, `LadderRewards`); hier
/// steht nur, wo der Wert herkommt und wohin er geht.
class LadderController extends Notifier<LadderProgress> {
  @override
  LadderProgress build() => ref.watch(savedGameProvider).ladder;

  /// Trägt einen Sieg ein. Ein erneuter Sieg gegen einen längst
  /// geschlagenen Gegner ändert nichts (ADR-0032).
  void defeat(int rung) {
    state = state.defeat(rung);
  }

  /// Trägt eine Niederlage ein (ADR-0033).
  ///
  /// **Sie ändert am Fortschritt nichts** — die Reihe kennt nur den
  /// höchsten Sieg. Festgehalten wird sie allein für „der Unbeugsame":
  /// Ohne diese Spur steht eine Niederlage nirgends, und die Bedingung
  /// wäre nicht bestimmbar.
  void recordDefeat(int rung) {
    state = state.recordDefeat(rung);
  }

  /// Trägt einen Lauf durch die Grube ein und sagt, was er eingebracht
  /// hat (ADR-0039).
  ///
  /// **Eine Stelle für Sieg und Niederlage**, damit der Bildschirm nicht
  /// selbst entscheidet, welche der beiden Methoden oben gilt, und die
  /// Differenz nicht selbst ausrechnet. Ob etwas herauskommt, entscheidet
  /// weiterhin `LadderProgress` allein: Eine zweite Räumung derselben
  /// Stufe ändert den Stand nicht, die Differenz ist dann von selbst null.
  ({int xp, int gold}) recordRun(int stage, {required bool won}) {
    final vorher = state;
    if (won) {
      defeat(stage);
    } else {
      recordDefeat(stage);
    }
    return (
      xp: state.earnedXp - vorher.earnedXp,
      gold: state.earnedGold - vorher.earnedGold,
    );
  }

  /// Setzt die Reihe zurück. Nur der Entwicklermodus ruft das.
  void reset() {
    state = const LadderProgress.empty();
  }
}

final ladderProvider = NotifierProvider<LadderController, LadderProgress>(
  LadderController.new,
);

/// Auf welcher Sprosse der nächste Kampf stattfindet, gezählt ab 1.
final nextRungProvider = Provider<int>((ref) {
  return ref.watch(ladderProvider).nextRung;
});

/// Tage seit dem 1.1.1970 — die Zahl, an der die Dailies hängen.
///
/// In UTC gerechnet, wie `Day` selbst: Eine Zeitumstellung darf keinen
/// Tag verschlucken (`gotchas.md`).
int dayNumberOf(Day day) {
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(1970)).inDays;
}

/// Ob die Dailies heute zahlen: **nur an Tagen mit einem Häkchen**
/// (ADR-0040). Der Kampf bleibt so die Auszahlung der Gewohnheiten, nicht
/// ihr Ersatz — wer nichts abhakt, darf trotzdem spielen.
final dailiesUnlockedProvider = Provider<bool>((ref) {
  final heute = ref.watch(todayProvider);
  return ref.watch(habitTrackerProvider).checksOn(heute) > 0;
});

/// Eine Stufe des Tages, wie der Eingang sie zeigt.
typedef DailyStage = ({int stage, bool cleared, int xp, int gold});

/// Die vier Stufen des Tages — **rechnet nicht**, fragt `LadderProgress`
/// und `LadderRewards`.
final todayDailiesProvider = Provider<List<DailyStage>>((ref) {
  final stand = ref.watch(ladderProvider);
  final tag = dayNumberOf(ref.watch(todayProvider));
  return <DailyStage>[
    for (final stufe in stand.dailiesOn(tag))
      (
        stage: stufe,
        cleared: stand.isDailyCleared(tag, stufe),
        xp: LadderRewards.dailyXpFor(stufe),
        gold: LadderRewards.dailyGoldFor(stufe),
      ),
  ];
});
