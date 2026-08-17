import 'dart:math';

import 'balance.dart';
import 'combatant.dart';
import 'enemy_policy.dart';
import 'events.dart';
import 'move.dart';
import 'state.dart';
import 'status.dart';
import 'timed_hit.dart';

/// Fuehrt Kampfrunden aus. Kennt keine Darstellung, keine Zeit, kein Flame.
///
/// Deterministisch bei gleichem Seed: dieselbe Eingabefolge erzeugt dieselbe
/// Ausgabe. Das ist die Voraussetzung dafuer, Balance ueber tausende
/// simulierte Kaempfe zu pruefen statt sie zu erfuehlen (ADR-0002).
class CombatEngine {
  CombatEngine({
    required int seed,
    this.balance = const Balance(),
    this.enemyPolicy = const SimpleEnemyPolicy(),
    this.enemyLoadout = Moves.defaultLoadout,
  }) : _random = Random(seed);

  final Balance balance;
  final EnemyPolicy enemyPolicy;
  final List<Move> enemyLoadout;
  final Random _random;

  /// Eine vollstaendige Runde: Spieler handelt, dann der Gegner, danach
  /// ticken die Statuseffekte.
  CombatStep resolveRound(CombatState state, PlayerAction action) {
    if (state.isOver) {
      return CombatStep(
        state: state,
        events: <CombatEvent>[
          MoveFailed(
            side: Side.player,
            moveId: action.move.id,
            reason: MoveFailure.combatAlreadyOver,
          ),
        ],
      );
    }

    final round = _Round(state.player, state.enemy)
      ..emit(RoundStarted(state.round));

    _act(round, Side.player, action.move, action.timedHit);
    if (!_settleDeaths(round)) {
      _actEnemy(round);
    }
    if (!_settleDeaths(round)) {
      _tickStatuses(round, Side.player);
      _tickStatuses(round, Side.enemy);
      _settleDeaths(round);
    }

    return CombatStep(
      state: state.copyWith(
        player: round.player,
        enemy: round.enemy,
        round: state.round + 1,
        outcome: round.outcome,
      ),
      events: round.events,
    );
  }

  void _actEnemy(_Round round) {
    final move = enemyPolicy.chooseMove(
      self: round.enemy,
      opponent: round.player,
      loadout: enemyLoadout,
    );
    _act(round, Side.enemy, move, TimedHit.none);
  }

  /// Fuehrt einen Move aus: Kosten, Schaden, Zusatzwirkungen.
  void _act(_Round round, Side side, Move move, TimedHit timedHit) {
    final actor = round.of(side);
    if (!move.isAffordableBy(actor.energy)) {
      round.emit(
        MoveFailed(
          side: side,
          moveId: move.id,
          reason: MoveFailure.notEnoughEnergy,
        ),
      );
      return;
    }

    round.emit(MoveUsed(side: side, moveId: move.id));
    _applyEnergy(round, side, move.energyDelta);

    if (move.dealsDamage) {
      _applyDamage(round, side, move, timedHit);
    }
    for (final effect in move.effects) {
      _applyEffect(round, side, effect);
    }
  }

  void _applyEnergy(_Round round, Side side, int delta) {
    if (delta == 0) return;
    final before = round.of(side).energy;
    final updated = round.of(side).withEnergyDelta(delta);
    round.set(side, updated);
    round.emit(
      EnergyChanged(
        side: side,
        delta: updated.energy - before,
        current: updated.energy,
      ),
    );
  }

  void _applyDamage(_Round round, Side side, Move move, TimedHit timedHit) {
    final target = _opposite(side);
    final factor = timedHit.factor(balance);
    final raw = _rawDamage(round.of(side), round.of(target), move, factor);
    _dealDamage(round, target, raw, factor);
  }

  int _rawDamage(
    Combatant attacker,
    Combatant defender,
    Move move,
    double timedHitFactor,
  ) {
    final base = attacker.attack * move.power;
    final softening = balance.defenseSoftening;
    final mitigation = softening / (softening + defender.effectiveDefense);
    final spread = balance.damageVariance;
    final variance = 1.0 + (_random.nextDouble() * 2 - 1) * spread;
    final total = base * mitigation * timedHitFactor * variance;
    return max(balance.minimumDamage, total.round());
  }

  /// Zieht Schaden ab, nachdem ein eventueller Schild ihn gemindert hat.
  void _dealDamage(_Round round, Side target, int amount, double factor) {
    var remaining = amount;
    final shield = round.of(target).activeShield;

    if (shield != null) {
      final absorbed = min(shield.absorb, remaining);
      remaining -= absorbed;
      round.emit(DamageAbsorbed(target: target, amount: absorbed));

      final next = shield.afterAbsorbing(absorbed);
      if (next == null) {
        round.set(target, round.of(target).withoutStatus('shield'));
        round.emit(ShieldBroke(target));
      } else {
        round.set(target, round.of(target).withStatus(next));
      }
    }

    if (remaining <= 0) return;
    round.set(target, round.of(target).withHpDelta(-remaining));
    round.emit(
      DamageDealt(
        target: target,
        amount: remaining,
        timedHitFactor: factor,
      ),
    );
  }

  void _applyEffect(_Round round, Side side, MoveEffect effect) {
    switch (effect) {
      case ApplyPoison():
        final damage =
            (round.of(side).attack * balance.poisonDamageFactor).round();
        _addStatus(
          round,
          _opposite(side),
          Poison(
            damagePerTurn: max(1, damage),
            remainingTurns: balance.poisonDurationTurns,
          ),
        );
      case ApplyDefenseDown():
        _addStatus(
          round,
          _opposite(side),
          DefenseDown(
            factor: balance.defenseDownFactor,
            remainingTurns: balance.defenseDownDurationTurns,
          ),
        );
      case HealSelf():
        _heal(round, side);
      case ShieldSelf():
        final actor = round.of(side);
        _addStatus(
          round,
          side,
          Shield(
            absorb: max(
              1,
              (actor.attack * balance.shieldFactorOfAttack).round(),
            ),
            remainingTurns: balance.shieldDurationTurns,
          ),
        );
    }
  }

  void _heal(_Round round, Side side) {
    final actor = round.of(side);
    final wanted = (actor.attack * balance.healFactorOfAttack).round();
    final healed = actor.withHpDelta(wanted);
    final actual = healed.hp - actor.hp;
    round.set(side, healed);
    if (actual > 0) {
      round.emit(Healed(target: side, amount: actual));
    }
  }

  void _addStatus(_Round round, Side side, StatusEffect effect) {
    round.set(side, round.of(side).withStatus(effect));
    round.emit(
      StatusApplied(
        target: side,
        statusId: effect.id,
        turns: effect.remainingTurns,
      ),
    );
  }

  /// Laesst Statuseffekte wirken und altern.
  void _tickStatuses(_Round round, Side side) {
    final current = round.of(side).statuses;
    if (current.isEmpty) return;

    final survivors = <StatusEffect>[];
    for (final status in current) {
      if (status is Poison) {
        round.set(side, round.of(side).withHpDelta(-status.damagePerTurn));
        round.emit(
          StatusTicked(
            target: side,
            statusId: status.id,
            damage: status.damagePerTurn,
          ),
        );
      }
      final next = status.ticked();
      if (next == null) {
        round.emit(StatusExpired(target: side, statusId: status.id));
      } else {
        survivors.add(next);
      }
    }
    round.set(side, round.of(side).withStatuses(survivors));
  }

  /// Prueft auf Niederlagen und beendet den Kampf. Gibt `true` zurueck,
  /// wenn der Kampf damit vorbei ist.
  bool _settleDeaths(_Round round) {
    if (round.outcome != null) return true;

    if (round.player.isDefeated) {
      round
        ..emit(const CombatantDefeated(Side.player))
        ..finish(CombatOutcome.defeat);
      return true;
    }
    if (round.enemy.isDefeated) {
      round
        ..emit(const CombatantDefeated(Side.enemy))
        ..finish(CombatOutcome.victory);
      return true;
    }
    return false;
  }

  Side _opposite(Side side) => side == Side.player ? Side.enemy : Side.player;
}

/// Veraenderlicher Sammler waehrend **einer** Rundenberechnung.
///
/// Bewusst lokal und privat: nach aussen bleibt alles unveraenderlich. Ohne
/// diesen Sammler muesste jede Teilberechnung Zustand und Eventliste
/// durchreichen, was die Engine deutlich schwerer lesbar machen wuerde.
class _Round {
  _Round(this.player, this.enemy);

  Combatant player;
  Combatant enemy;
  CombatOutcome? outcome;
  final List<CombatEvent> events = <CombatEvent>[];

  Combatant of(Side side) => side == Side.player ? player : enemy;

  void set(Side side, Combatant value) {
    if (side == Side.player) {
      player = value;
    } else {
      enemy = value;
    }
  }

  void emit(CombatEvent event) => events.add(event);

  void finish(CombatOutcome result) {
    outcome = result;
    events.add(CombatEnded(result));
  }
}
