import 'package:combat/combat.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'battle/fighter.dart';
import 'battle/move_animation.dart';
import 'battle/projectile.dart';

/// Die Kampfdarstellung. Spielt Events ab und **rechnet nichts** (ADR-0002).
///
/// Es gibt hier bewusst keine HP, keine Stats und keine Regeln. Wenn diese
/// Klasse jemals eine Zahl bestimmt statt sie darzustellen, gehört sie in
/// `package:combat`.
///
/// **Warum eine Zeitachse.** Die Engine liefert eine Runde als *Liste* —
/// alles ist gleichzeitig wahr. Ein Kampf, den man ansehen soll, braucht
/// aber eine Reihenfolge: erst spannen, dann fliegt der Pfeil, dann zuckt
/// der Getroffene. [_beats] verteilt die Events deshalb über die Zeit,
/// ohne dass die Logik davon etwas wissen muss.
class BattleGame extends FlameGame {
  BattleGame();

  late final Fighter _hero;
  late final Fighter _enemy;

  /// Geplante Bewegungen mit ihrem Zeitpunkt, aufsteigend sortiert.
  final List<_Beat> _beats = <_Beat>[];

  /// Laufende Zeit seit Spielstart. Bezugsgröße für alle Zeitpunkte.
  double _now = 0;

  /// Wohin die nächste Einplanung fällt.
  double _cursor = 0;

  @override
  Future<void> onLoad() async {
    // Beide Seiten grau. Der Unterschied ist die Helligkeit — wer vorne
    // links steht, ist man selbst.
    _hero = Fighter(tint: const Color(0xFFBCC4D4), facesRight: true);
    _enemy = Fighter(tint: const Color(0xFF79808F), facesRight: false);
    await addAll(<Component>[_hero, _enemy]);
    _layout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  void _layout() {
    final groundY = size.y * 0.86;
    _hero
      ..homeX = size.x * 0.24
      ..position = Vector2(size.x * 0.24, groundY);
    _enemy
      ..homeX = size.x * 0.76
      ..position = Vector2(size.x * 0.76, groundY);
  }

  Fighter _fighterFor(Side side) => side == Side.player ? _hero : _enemy;

  Fighter _opponentOf(Side side) => side == Side.player ? _enemy : _hero;

  /// Übersetzt eine Runde in eine Abfolge von Bewegungen.
  ///
  /// [onDone] meldet, wann wieder Ruhe ist — der Bildschirm gibt daraufhin
  /// die Knöpfe frei.
  void playEvents(List<CombatEvent> events, {VoidCallback? onDone}) {
    _cursor = _beats.isEmpty ? _now : _beats.last.at;

    for (final event in events) {
      switch (event) {
        case MoveUsed(:final side, :final moveId):
          _playMove(side, MoveAnimation.forId(moveId));

        case DamageDealt(:final target, :final timedHitFactor):
          _at(0, () => _fighterFor(target).takeHit(strong: timedHitFactor > 1));
          _advance(0.18);

        case DamageAbsorbed(:final target):
          _at(0, () => _fighterFor(target).pulseShield());
          _advance(0.18);

        case Healed(:final target):
          _at(0, () => _fighterFor(target).glow(const Color(0xFF6FD68B)));
          _advance(0.2);

        case StatusTicked(:final target):
          _at(0, () => _fighterFor(target).glow(const Color(0xFF9BE05B)));
          _advance(0.2);

        case CombatantDefeated(:final side):
          _at(0.1, () => _fighterFor(side).fall());
          _advance(0.5);

        // Eine neue Umgebung ist ein sichtbarer Einschnitt: kurzes
        // Aufleuchten auf beiden Seiten, damit der Wechsel auffällt. Das
        // eigentliche Bild -- Lava, Sandschleier, Nebel -- fehlt noch.
        case EnvironmentSet():
          _at(0, () {
            _hero.glow(const Color(0xFFB88CFF));
            _enemy.glow(const Color(0xFFB88CFF));
          });
          _advance(0.25);

        case RoundStarted():
        case MoveFailed():
        case ShieldBroke():
        case StatusApplied():
        case StatusExpired():
        case EnergyChanged():
        case EnvironmentEnded():
        case CombatEnded():
          break;
      }
    }

    if (onDone != null) _at(0.05, onDone);
  }

  /// Die Ausholbewegung — und beim Bogen der Pfeil, der daraus entsteht.
  void _playMove(Side side, MoveAnimation animation) {
    final actor = _fighterFor(side);

    switch (animation.kind) {
      case MoveVisual.projectile:
        _at(0, actor.aimBow);
        _at(animation.windUp, () {
          actor.releaseBow();
          _fireArrow(side, animation);
        });
      case MoveVisual.melee:
        _at(animation.windUp, actor.lunge);
      case MoveVisual.support:
        _at(0, actor.brace);
    }

    // Bis zum **Einschlag**, nicht bis zum Abschuss. Das folgende
    // `DamageDealt` landet damit genau dann, wenn der Pfeil ankommt --
    // sonst zuckt der Getroffene, während das Geschoss noch unterwegs ist.
    _advance(animation.impact);
  }

  /// Schickt einen Pfeil los.
  ///
  /// Die Flugzeit ergibt sich aus dem Abstand zwischen Abschuss und
  /// Einschlag. Beide Zahlen stehen in derselben [MoveAnimation], und das
  /// Zucken des Getroffenen hängt an derselben Zeitachse — deshalb braucht
  /// der Pfeil keinen Rückruf, um den Treffer zu melden. Eine zweite Quelle
  /// für denselben Zeitpunkt wäre eine Quelle, die abweichen kann.
  void _fireArrow(Side side, MoveAnimation animation) {
    final shooter = _fighterFor(side);
    final target = _opponentOf(side);
    final flight = (animation.impact - animation.windUp).clamp(0.1, 2.0);

    add(
      Projectile(
        from: shooter.handAnchor,
        to: target.chestAnchor,
        flightTime: flight,
      ),
    );
  }

  void reset() {
    _beats.clear();
    _cursor = _now;
    _hero.reset();
    _enemy.reset();
    for (final shot in children.whereType<Projectile>().toList()) {
      shot.removeFromParent();
    }
  }

  // --- Zeitachse ---

  /// Plant eine Bewegung [offset] Sekunden nach dem aktuellen Cursor ein.
  void _at(double offset, VoidCallback action) {
    _beats.add(_Beat(_cursor + offset, action));
  }

  /// Schiebt den Cursor weiter, damit das Nächste danach kommt.
  void _advance(double seconds) => _cursor += seconds;

  @override
  void update(double dt) {
    super.update(dt);
    _now += dt;

    while (_beats.isNotEmpty && _beats.first.at <= _now) {
      _beats.removeAt(0).action();
    }
  }
}

/// Eine eingeplante Bewegung: was passiert, und wann.
class _Beat {
  const _Beat(this.at, this.action);

  final double at;
  final VoidCallback action;
}
