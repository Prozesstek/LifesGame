import 'combatant.dart';
import 'environment.dart';
import 'move.dart';
import 'state.dart';
import 'status.dart';
import 'timing_spec.dart';

/// Welche Timing-Werte fuer diesen Zug tatsaechlich gelten.
///
/// **Eine Kampfregel, keine Darstellung.** Die Leiste misst nur; wie
/// schnell sie laeuft und wie breit ihr Fenster ist, entscheidet sich hier
/// (ADR-0002). Sonst muesste der Bildschirm Statuseffekte und Umgebungen
/// auswerten -- und damit Spielregeln kennen.
///
/// Drei Quellen wirken zusammen, **multiplikativ** wie in der Vorlage
/// vorgegeben: die Faehigkeit selbst, Statuseffekte des Ausfuehrenden und
/// die Umgebung. Zwei Effekte, die das Fenster je um ein Viertel kuerzen,
/// lassen etwas mehr als die Haelfte uebrig -- nicht die Haelfte minus
/// etwas.
///
/// Die Grenzen aus [TimingSpec] fangen den Rest ab: Kein Marker wird
/// schneller als [TimingSpec.maxSpeed], kein Fenster schmaler als
/// [TimingSpec.minWindow]. Ohne sie koennten sich Sandsturm, Wurzelgriff
/// und eine legendaere Faehigkeit zu einem unspielbaren Zug summieren.
TimingSpec effectiveTiming({
  required Move move,
  required Combatant actor,
  required Side side,
  Environment? environment,
}) {
  var speedFactor = 1.0;
  var windowFactor = 1.0;

  for (final status in actor.statuses) {
    if (status is WindowShrink) windowFactor *= status.factor;
    if (status is TimeDilation) speedFactor *= status.speedFactor;
  }

  if (environment != null) {
    speedFactor *= environment.speedFactorBoth;
    windowFactor *= environment.windowFactorFor(side);
  }

  return move.timing.scaled(
    speedFactor: speedFactor,
    windowFactor: windowFactor,
  );
}

/// Bequemer Zugriff auf [effectiveTiming] fuer eine Seite des Kampfes.
TimingSpec timingForSide(CombatState state, Side side, Move move) {
  return effectiveTiming(
    move: move,
    actor: state.combatantOf(side),
    side: side,
    environment: state.environment,
  );
}
