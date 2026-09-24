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

  /// Was ein Lauf auf [stage] heute noch einbringen kann — der Rest des
  /// Topfs (ADR-0041). Geht in die Welt, die ihn je Gegner ausschüttet.
  Payout potFor(int stage) {
    final tag = dayNumberOf(ref.read(todayProvider));
    return state.potFor(
      tag,
      stage,
      dailyAllowed: ref.read(dailiesUnlockedProvider),
    );
  }

  /// Trägt einen Lauf durch die Grube ein und sagt, was er eingebracht
  /// hat (ADR-0039).
  ///
  /// **Eine Stelle für Sieg und Niederlage**, damit der Bildschirm nicht
  /// selbst entscheidet und die Differenz nicht selbst ausrechnet. Was
  /// zählt, entscheidet `LadderProgress.bookRun` allein:
  ///
  /// - [collected] ist, was die Welt je Gegner ausgeschüttet hat. Ein
  ///   verlorener Lauf behält es (ADR-0041), ein gewonnener bekommt den
  ///   ganzen Topf.
  /// - Ein Sieg auf geschaffter Stufe zählt als Daily (ADR-0040), wenn
  ///   sie heute dazugehört und heute abgehakt wurde. Die vier des Tages
  ///   werden dabei eingefroren — sonst verschöbe ein Erstsieg sie.
  Payout recordRun(
    int stage, {
    required bool won,
    Payout collected = (xp: 0, gold: 0),
    double? seconds,
  }) {
    final vorher = state;
    var neu = state.bookRun(
      dayNumberOf(ref.read(todayProvider)),
      stage,
      won: won,
      collected: collected,
      dailyAllowed: ref.read(dailiesUnlockedProvider),
    );
    // Nur ein Sieg hat eine Zeit, die zählt (ADR-0048).
    if (won && seconds != null) neu = neu.recordTime(stage, seconds);
    state = neu;
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
