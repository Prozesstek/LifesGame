import 'entity.dart';
import 'vec2.dart';

/// Ein Pfeil in der Luft.
///
/// **Veränderlich, aus demselben Grund wie [ActionEntity]:** Ein Geschoss
/// rückt sechzigmal je Sekunde weiter. Nach aussen geht auch hier nur
/// eine Kopie ([ProjectileView]).
class Projectile {
  Projectile({
    required this.id,
    required this.faction,
    required this.position,
    required this.velocity,
    required this.damage,
    required this.radius,
  });

  final int id;

  /// Wem es gehört. Ein Geschoss trifft nie die eigene Seite — sonst
  /// erschiessen sich zwei Schützen gegenseitig, und die Halle löst sich
  /// von selbst auf.
  final Faction faction;

  final Vec2 velocity;
  final int damage;
  final double radius;

  Vec2 position;
  double age = 0;
  bool spent = false;
}

/// Ein Geschoss, wie der Renderer es sieht.
class ProjectileView {
  const ProjectileView({
    required this.id,
    required this.faction,
    required this.position,
    required this.direction,
    required this.radius,
  });

  factory ProjectileView.of(Projectile p) {
    return ProjectileView(
      id: p.id,
      faction: p.faction,
      position: p.position,
      direction: p.velocity.normalized,
      radius: p.radius,
    );
  }

  final int id;
  final Faction faction;
  final Vec2 position;
  final Vec2 direction;
  final double radius;
}
