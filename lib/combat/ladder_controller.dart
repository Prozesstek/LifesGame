import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Setzt die Reihe zurück. Nur der Entwicklermodus ruft das.
  void reset() {
    state = const LadderProgress.empty();
  }
}

final ladderProvider = NotifierProvider<LadderController, LadderProgress>(
  LadderController.new,
);

/// Der Gegner, der als Nächstes ansteht.
///
/// **Die einzige Stelle, an der „welcher Gegner" beantwortet wird.** Der
/// Bildschirm zeigt ihn, der Kampf tritt gegen ihn an, und das Blatt am
/// Ende meldet ihn zurück — alle drei fragen hier. Zwei Stellen, die
/// dieselbe Frage beantworten, driften auseinander (`gotchas.md`).
final nextEnemyProvider = Provider<EnemyBlueprint>((ref) {
  return ref.watch(ladderProvider).nextEnemy;
});

/// Auf welcher Sprosse der nächste Kampf stattfindet, gezählt ab 1.
final nextRungProvider = Provider<int>((ref) {
  return ref.watch(ladderProvider).nextRung;
});
