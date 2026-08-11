import 'package:combat/combat.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Die Kampfdarstellung. Spielt Events ab und **rechnet nichts** (ADR-0002).
///
/// Es gibt hier bewusst keine HP, keine Stats und keine Regeln. Wenn diese
/// Klasse jemals eine Zahl bestimmt statt sie darzustellen, gehört sie in
/// `package:combat`.
class BattleGame extends FlameGame {
  BattleGame();

  late final Fighter _hero;
  late final Fighter _enemy;

  @override
  Future<void> onLoad() async {
    _hero = Fighter(color: const Color(0xFF5B8DEF), facesRight: true);
    _enemy = Fighter(color: const Color(0xFFE05B5B), facesRight: false);
    await addAll(<Component>[_hero, _enemy]);
    _layout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  void _layout() {
    final groundY = size.y * 0.62;
    _hero
      ..homeX = size.x * 0.24
      ..position = Vector2(size.x * 0.24, groundY);
    _enemy
      ..homeX = size.x * 0.76
      ..position = Vector2(size.x * 0.76, groundY);
  }

  Fighter _fighterFor(Side side) => side == Side.player ? _hero : _enemy;

  /// Übersetzt eine Runde in Bewegung. Mehr macht diese Schicht nicht.
  void playEvents(List<CombatEvent> events) {
    for (final event in events) {
      switch (event) {
        case MoveUsed(:final side):
          _fighterFor(side).lunge();
        case DamageDealt(:final target, :final timedHitFactor):
          _fighterFor(target).takeHit(strong: timedHitFactor > 1.0);
        case DamageAbsorbed(:final target):
          _fighterFor(target).pulseShield();
        case Healed(:final target):
          _fighterFor(target).glow(const Color(0xFF6FD68B));
        case StatusTicked(:final target):
          _fighterFor(target).glow(const Color(0xFF9BE05B));
        case CombatantDefeated(:final side):
          _fighterFor(side).fall();
        case RoundStarted():
        case MoveFailed():
        case ShieldBroke():
        case StatusApplied():
        case StatusExpired():
        case EnergyChanged():
        case CombatEnded():
          break;
      }
    }
  }

  void reset() {
    _hero.reset();
    _enemy.reset();
  }
}

/// Eine Kampffigur. Bewusst simpel gehalten: Rechteck mit Reaktionen.
/// Sprites und Rive-Animationen ersetzen das später, die Schnittstelle
/// (`lunge`, `takeHit`, …) bleibt dieselbe.
class Fighter extends PositionComponent {
  Fighter({required this.color, required this.facesRight})
    : super(size: Vector2(64, 96), anchor: Anchor.bottomCenter);

  final Color color;
  final bool facesRight;

  /// Ruheposition auf der X-Achse. Der Ausfallschritt kehrt hierher zurück.
  double homeX = 0;

  double _lunge = 0;
  double _flash = 0;
  double _shieldPulse = 0;
  Color _glowColor = const Color(0xFFFFFFFF);
  bool _down = false;

  void lunge() => _lunge = 1;

  void takeHit({bool strong = false}) {
    _flash = strong ? 1.4 : 1;
    _glowColor = const Color(0xFFFFFFFF);
  }

  void glow(Color tint) {
    _flash = 1;
    _glowColor = tint;
  }

  void pulseShield() => _shieldPulse = 1;

  void fall() => _down = true;

  void reset() {
    _down = false;
    _lunge = 0;
    _flash = 0;
    _shieldPulse = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lunge = (_lunge - dt * 3.2).clamp(0, 2);
    _flash = (_flash - dt * 2.6).clamp(0, 2);
    _shieldPulse = (_shieldPulse - dt * 2.2).clamp(0, 2);

    // Ausfallschritt in Blickrichtung, dann zurück.
    final direction = facesRight ? 1.0 : -1.0;
    final offset = _lunge * _lunge * 34 * direction;
    position.x = homeX + offset;
  }

  @override
  void render(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(10),
    );

    if (_down) {
      canvas.save();
      canvas.translate(0, size.y * 0.72);
      canvas.scale(1, 0.28);
    }

    final tint = _flash > 0
        ? Color.lerp(color, _glowColor, (_flash * 0.7).clamp(0, 1))!
        : color;
    canvas.drawRRect(body, Paint()..color = tint);

    if (_shieldPulse > 0) {
      canvas.drawRRect(
        body.inflate(6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(
            0xFF7FD4FF,
          ).withValues(alpha: _shieldPulse.clamp(0, 1)),
      );
    }

    if (_down) canvas.restore();
  }
}
