import 'combatant.dart';

/// Ausgang eines Kampfes.
enum CombatOutcome { victory, defeat }

/// Grund, warum ein Move nicht ausgefuehrt wurde.
enum MoveFailure { notEnoughEnergy, combatAlreadyOver }

/// Was im Kampf passiert ist — die einzige Schnittstelle zur Darstellung.
///
/// Flame liest diese Events und spielt sie ab. Die Logik weiss nichts von
/// Animationen, Sound oder Timing (ADR-0002). Neue Effekte brauchen ein
/// neues Event, keinen Umweg ueber geteilten Zustand.
sealed class CombatEvent {
  const CombatEvent();
}

final class RoundStarted extends CombatEvent {
  const RoundStarted(this.round);
  final int round;
}

final class MoveUsed extends CombatEvent {
  const MoveUsed({required this.side, required this.moveId});
  final Side side;
  final String moveId;
}

final class MoveFailed extends CombatEvent {
  const MoveFailed({
    required this.side,
    required this.moveId,
    required this.reason,
  });
  final Side side;
  final String moveId;
  final MoveFailure reason;
}

final class DamageDealt extends CombatEvent {
  const DamageDealt({
    required this.target,
    required this.amount,
    required this.timedHitFactor,
  });
  final Side target;
  final int amount;

  /// 1.0 bedeutet kein Bonus. Die Darstellung entscheidet daran, ob ein
  /// Treffer besonders inszeniert wird.
  final double timedHitFactor;

  bool get wasTimedHit => timedHitFactor > 1.0;
}

final class DamageAbsorbed extends CombatEvent {
  const DamageAbsorbed({required this.target, required this.amount});
  final Side target;
  final int amount;
}

final class ShieldBroke extends CombatEvent {
  const ShieldBroke(this.target);
  final Side target;
}

final class Healed extends CombatEvent {
  const Healed({required this.target, required this.amount});
  final Side target;
  final int amount;
}

final class EnergyChanged extends CombatEvent {
  const EnergyChanged({
    required this.side,
    required this.delta,
    required this.current,
  });
  final Side side;
  final int delta;
  final int current;
}

final class StatusApplied extends CombatEvent {
  const StatusApplied({
    required this.target,
    required this.statusId,
    required this.turns,
  });
  final Side target;
  final String statusId;
  final int turns;
}

final class StatusTicked extends CombatEvent {
  const StatusTicked({
    required this.target,
    required this.statusId,
    required this.damage,
  });
  final Side target;
  final String statusId;
  final int damage;
}

final class StatusExpired extends CombatEvent {
  const StatusExpired({required this.target, required this.statusId});
  final Side target;
  final String statusId;
}

final class CombatantDefeated extends CombatEvent {
  const CombatantDefeated(this.side);
  final Side side;
}

final class CombatEnded extends CombatEvent {
  const CombatEnded(this.outcome);
  final CombatOutcome outcome;
}
