import 'dart:math';

import 'balance.dart';
import 'combatant.dart';
import 'enemy_policy.dart';
import 'environment.dart';
import 'events.dart';
import 'move.dart';
import 'state.dart';
import 'status.dart';
import 'timed_hit.dart';
import 'timing_rules.dart';
import 'timing_spec.dart';

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

    final round = _Round(state.player, state.enemy, state.environment)
      ..emit(RoundStarted(state.round));

    _act(round, Side.player, action.move, action.hitsFor(action.move));
    if (!_settleDeaths(round)) {
      _actEnemy(round);
    }
    if (!_settleDeaths(round)) {
      _tickStatuses(round, Side.player);
      _tickStatuses(round, Side.enemy);
      _tickEnvironment(round);
      _settleDeaths(round);
    }

    return CombatStep(
      state: state.copyWith(
        player: round.player,
        enemy: round.enemy,
        round: state.round + 1,
        outcome: round.outcome,
        environment: round.environment,
        clearEnvironment: round.environment == null,
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
    _act(round, Side.enemy, move, _rollHits(round, Side.enemy, move));
  }

  /// Die Tipps des Gegners. Er zielt nicht -- er trifft die Leiste an einer
  /// zufaelligen Stelle, gewertet mit denselben Fenstern wie beim Spieler.
  ///
  /// **Ohne neue Zahl.** Ein Zug mit 24 % Fenster wird dadurch in etwa 24 %
  /// der Faelle perfekt, einer mit 4 % fast nie -- die Staffelung steckt
  /// schon in [TimingSpec]. Und erst dadurch wirken die Faehigkeiten, die
  /// das gegnerische Fenster verengen: Wurzelgriff und Sandsturm hatten
  /// gegen einen Gegner, der immer [TimedHit.none] bekam, keinerlei
  /// Wirkung.
  ///
  /// Ein Zug ohne Zeitfenster wuerfelt gar nicht erst -- sonst verbrauchte
  /// er Zufallszahlen, ohne dass etwas davon abhinge.
  List<TimedHit> _rollHits(_Round round, Side side, Move move) {
    if (!move.hasTimingWindow) {
      return List<TimedHit>.filled(move.hits, TimedHit.none);
    }

    final spec = effectiveTiming(
      move: move,
      actor: round.of(side),
      side: side,
      environment: round.environment,
    );
    return <TimedHit>[
      for (var i = 0; i < move.hits; i++) spec.judgeAt(_random.nextDouble()),
    ];
  }

  /// Fuehrt einen Move aus: Kosten, Schaden, Zusatzwirkungen.
  void _act(_Round round, Side side, Move move, List<TimedHit> hits) {
    final actor = round.of(side);
    final discount = _costDiscount(actor);
    if (actor.energy < move.energyCost - discount) {
      round.emit(
        MoveFailed(
          side: side,
          moveId: move.id,
          reason: MoveFailure.notEnoughEnergy,
        ),
      );
      return;
    }

    round.damageThisAction = 0;
    round.emit(MoveUsed(side: side, moveId: move.id));
    _applyEnergy(round, side, move.energyDelta + discount);
    if (discount > 0) {
      round.set(side, round.of(side).withoutStatus('cost_reduction'));
    }

    // Der beste Tipp entscheidet ueber die Perfect-Wirkungen. Bei einem
    // einzelnen Treffer ist das schlicht der eine.
    final best = _bestHit(hits);

    if (move.dealsDamage) {
      for (final hit in hits) {
        _applyDamage(round, side, move, hit);
        if (round.of(_opposite(side)).isDefeated) break;
      }
      // Alle Tipps perfekt gibt den Bonustreffer (Klingenwirbel).
      if (move.isMultiHit && hits.every((h) => h == TimedHit.perfect)) {
        _applyDamage(round, side, move, TimedHit.perfect);
      }
    }

    for (final effect in move.effects) {
      _applyEffect(round, side, effect);
    }
    if (best == TimedHit.perfect) {
      for (final effect in move.perfectEffects) {
        _applyEffect(round, side, effect);
      }
    }
  }

  /// Der beste Tipp einer Runde. Perfect schlaegt Good schlaegt None.
  TimedHit _bestHit(List<TimedHit> hits) {
    if (hits.contains(TimedHit.perfect)) return TimedHit.perfect;
    if (hits.contains(TimedHit.good)) return TimedHit.good;
    return TimedHit.none;
  }

  /// Rabatt aus [CostReduction], falls einer anliegt.
  int _costDiscount(Combatant actor) {
    for (final status in actor.statuses) {
      if (status is CostReduction) return status.amount;
    }
    return 0;
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
    final factor = _timingFactor(round, side, move, timedHit);
    final environment = round.environment;
    final fromField = environment?.damageFactorFor(side) ?? 1.0;
    final raw = _rawDamage(
      round.of(side),
      round.of(target),
      move,
      factor * fromField,
    );

    // Schutz ignorieren steht bei Sternenfall in den Perfect-Wirkungen --
    // es gilt also nur, wenn perfekt getroffen wurde.
    final ignores = move.effects.any((e) => e is IgnoreProtection) ||
        (timedHit == TimedHit.perfect &&
            move.perfectEffects.any((e) => e is IgnoreProtection));

    _dealDamage(round, side, target, move, raw, factor, ignores);
  }

  /// Was das Timing bei **dieser** Faehigkeit wert ist.
  ///
  /// Die Reihenfolge ist Absicht: Erst der eigene Faktor der Faehigkeit,
  /// dann Zeitdehnung obendrauf, und ganz zuletzt die Sperre -- wer keinen
  /// Timing-Bonus bekommen darf, bekommt auch keinen aus einem Buff.
  double _timingFactor(_Round round, Side side, Move move, TimedHit hit) {
    if (_hasStatus<TimingLocked>(round.of(side))) return balance.timedHitNone;

    final base = switch (hit) {
      TimedHit.perfect => move.perfectFactor ?? balance.timedHitPerfect,
      TimedHit.good => balance.timedHitGood,
      TimedHit.none => move.missFactor ?? balance.timedHitNone,
    };

    if (hit != TimedHit.perfect) return base;

    for (final status in round.of(side).statuses) {
      if (status is TimeDilation) return base + status.perfectBonus;
    }
    return base;
  }

  bool _hasStatus<T extends StatusEffect>(Combatant who) {
    return who.statuses.any((s) => s is T);
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

  /// Zieht Schaden ab, nachdem Schutzwirkungen ihn gemindert haben.
  ///
  /// Reihenfolge: Schadensminderung, dann Schild, dann HP. Reflexion geht
  /// vom **tatsaechlich erlittenen** Schaden aus -- was der Schild
  /// schluckt, wird nicht zurueckgeworfen.
  void _dealDamage(
    _Round round,
    Side attacker,
    Side target,
    Move move,
    int amount,
    double factor,
    bool ignoresProtection,
  ) {
    var remaining = amount;

    if (!ignoresProtection) {
      for (final status in round.of(target).statuses) {
        if (status is DamageReduction) {
          remaining = max(
            balance.minimumDamage,
            (remaining * status.factor).round(),
          );
        }
      }
    }

    final shield = ignoresProtection ? null : round.of(target).activeShield;

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
    round.damageThisAction += remaining;
    round.emit(
      DamageDealt(target: target, amount: remaining, timedHitFactor: factor),
    );

    if (!ignoresProtection) _reflect(round, attacker, target, remaining);
  }

  /// Wirft einen Teil des Schadens auf den Angreifer zurueck.
  void _reflect(_Round round, Side attacker, Side target, int taken) {
    for (final status in round.of(target).statuses) {
      if (status is! Reflect) continue;

      final back = (taken * status.share).round() + status.flatBonus;
      if (back <= 0) continue;

      round.set(attacker, round.of(attacker).withHpDelta(-back));
      round.emit(
        DamageDealt(
          target: attacker,
          amount: back,
          timedHitFactor: balance.timedHitNone,
        ),
      );
    }
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

      // --- Wirkungen des Faehigkeiten-Sets ---

      case ApplyBurn(:final chance, :final damageFactor, :final turns):
        if (_random.nextDouble() > chance) break;
        _addStatus(
          round,
          _opposite(side),
          Burn(
            damagePerTurn:
                max(1, (round.of(side).attack * damageFactor).round()),
            remainingTurns: turns,
          ),
        );

      case ReduceIncoming(:final factor, :final turns):
        _addStatus(
          round,
          side,
          DamageReduction(factor: factor, remainingTurns: turns),
        );

      case ReflectIncoming(:final share, :final turns, :final flatBonus):
        _addStatus(
          round,
          side,
          Reflect(share: share, flatBonus: flatBonus, remainingTurns: turns),
        );

      case ShrinkEnemyWindow(:final factor, :final turns):
        _addStatus(
          round,
          _opposite(side),
          WindowShrink(factor: factor, remainingTurns: turns),
        );

      case DilateTime(:final speedFactor, :final perfectBonus, :final turns):
        _addStatus(
          round,
          side,
          TimeDilation(
            speedFactor: speedFactor,
            perfectBonus: perfectBonus,
            remainingTurns: turns,
          ),
        );

      case LockEnemyTiming(:final turns):
        _addStatus(
          round,
          _opposite(side),
          TimingLocked(remainingTurns: turns),
        );

      case CheapenNext(:final amount, :final turns):
        _addStatus(
          round,
          side,
          CostReduction(amount: amount, remainingTurns: turns),
        );

      case LifeSteal(:final share):
        // Bezieht sich auf den Schaden **dieser** Handlung. Deshalb zaehlt
        // `_Round` ihn mit, statt dass der Effekt ihn neu ausrechnet --
        // eine zweite Rechnung waere eine zweite Wahrheit.
        final gained = (round.damageThisAction * share).round();
        if (gained > 0) _healBy(round, side, gained);

      case StealEnergy(:final amount):
        final victim = _opposite(side);
        final available = min(amount, round.of(victim).energy);
        if (available <= 0) break;
        _applyEnergy(round, victim, -available);
        _applyEnergy(round, side, available);

      case CleanseSelf():
        final harmful = round.of(side).statuses.where(_isHarmful).toList();
        if (harmful.isEmpty) break;
        round.set(side, round.of(side).withoutStatus(harmful.first.id));
        round.emit(
          StatusExpired(target: side, statusId: harmful.first.id),
        );

      case HealSelfBy(:final factor):
        _healBy(round, side, (round.of(side).attack * factor).round());

      case SetEnvironment(:final environmentId):
        final template = Environments.byId(environmentId);
        if (template == null) break;
        round.environment = template.copyWith(owner: side);
        round.emit(
          EnvironmentSet(
            environmentId: template.id,
            owner: side,
            turns: template.remainingTurns,
          ),
        );

      case GainEnergy(:final amount):
        _applyEnergy(round, side, amount);

      case IgnoreProtection():
        // Wirkt im Schadensweg, nicht als Statuseffekt.
        break;
    }
  }

  /// Welche Statuseffekte als „negativ" gelten und von Bluetentau
  /// entfernt werden koennen.
  bool _isHarmful(StatusEffect status) {
    return status is Poison ||
        status is Burn ||
        status is DefenseDown ||
        status is WindowShrink ||
        status is TimingLocked;
  }

  /// Heilt um einen festen Betrag, gemindert durch die Umgebung.
  void _healBy(_Round round, Side side, int amount) {
    final environment = round.environment;
    final factor = environment?.healFactorFor(side) ?? 1.0;
    final wanted = (amount * factor).round();
    if (wanted <= 0) return;

    final actor = round.of(side);
    final healed = actor.withHpDelta(wanted);
    final actual = healed.hp - actor.hp;
    round.set(side, healed);
    if (actual > 0) round.emit(Healed(target: side, amount: actual));
  }

  /// Laesst die Umgebung wirken und altern.
  void _tickEnvironment(_Round round) {
    final environment = round.environment;
    if (environment == null) return;

    final elapsed = environment.elapsedOf(
      Environments.byId(environment.id)?.remainingTurns ??
          environment.remainingTurns,
    );
    final factor = environment.dotFactorInTurn(elapsed);
    final victim = environment.victim;

    if (factor > 0) {
      final damage = max(
        1,
        (round.of(environment.owner).attack * factor).round(),
      );
      round.set(victim, round.of(victim).withHpDelta(-damage));
      round.emit(
        StatusTicked(
          target: victim,
          statusId: environment.id,
          damage: damage,
        ),
      );
    }

    if (environment.energyPenaltyOnEnemy > 0) {
      _applyEnergy(round, victim, -environment.energyPenaltyOnEnemy);
    }

    final next = environment.ticked();
    round.environment = next;
    if (next == null) {
      round.emit(EnvironmentEnded(environment.id));
    }
  }

  void _heal(_Round round, Side side) {
    final actor = round.of(side);
    _healBy(round, side, (actor.attack * balance.healFactorOfAttack).round());
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

  /// Schaden ueber Zeit eines Effekts. 0, wenn er keinen anrichtet.
  ///
  /// Gift und Brand sind zwei Arten mit derselben Wirkung -- getrennt,
  /// damit Bluetentau gezielt eine davon entfernen kann.
  int _dotDamageOf(StatusEffect status) {
    if (status is Poison) return status.damagePerTurn;
    if (status is Burn) return status.damagePerTurn;
    return 0;
  }

  /// Laesst Statuseffekte wirken und altern.
  void _tickStatuses(_Round round, Side side) {
    final current = round.of(side).statuses;
    if (current.isEmpty) return;

    final survivors = <StatusEffect>[];
    for (final status in current) {
      final dot = _dotDamageOf(status);
      if (dot > 0) {
        round.set(side, round.of(side).withHpDelta(-dot));
        round.emit(
          StatusTicked(target: side, statusId: status.id, damage: dot),
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
  _Round(this.player, this.enemy, this.environment);

  Combatant player;
  Combatant enemy;
  CombatOutcome? outcome;

  /// Die Umgebung, die gerade liegt. Veraenderbar, weil eine Faehigkeit
  /// sie mitten in der Runde ersetzen kann.
  Environment? environment;

  /// Schaden, den die laufende Handlung angerichtet hat.
  ///
  /// Lebensraub braucht ihn, und er soll ihn **nicht** neu ausrechnen:
  /// Eine zweite Rechnung ueber denselben Treffer waere eine zweite
  /// Wahrheit, die von der ersten abweichen kann.
  int damageThisAction = 0;

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
