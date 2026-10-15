import 'balance.dart';
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
    this.heroPower,
    this.heroLeech = 0,
    this.fromWeapon = false,
    this.isBoulder = false,
    this.maxAge = ActionBalance.projectileLifetime,
    this.freezeSeconds = 0,
    this.boomerang = false,
  });

  final int id;

  /// Wem es gehört. Ein Geschoss trifft nie die eigene Seite — sonst
  /// erschiessen sich zwei Schützen gegenseitig, und die Halle löst sich
  /// von selbst auf.
  final Faction faction;

  /// Veränderlich nur für den Bumerang, der umkehrt und dem Helden folgt.
  Vec2 velocity;
  final int damage;
  final double radius;

  /// Gesetzt, wenn der Held es geschossen hat: Dann rechnet der Einschlag
  /// wie ein Schlag des Helden (`Angriff × heroPower`, minus
  /// Verteidigung), und [damage] wird nicht gelesen.
  final double? heroPower;

  /// Anteil des Schadens, der den Helden heilt (Seelenraub).
  final double heroLeech;

  /// Ob es ein Pfeil der Waffe ist — dann gelten deren Nebenwirkungen.
  final bool fromWeapon;

  /// Ob es der Felsbrocken des Wächters ist — nur für die Darstellung.
  final bool isBoulder;

  /// Nach so vielen Sekunden verlischt es. Ein Skillshot fliegt genau
  /// seine Reichweite weit, nicht weiter — sonst zeigte die Vorschau eine
  /// kürzere Bahn, als der Funke dann fliegt.
  final double maxAge;

  /// Über null: Der Getroffene erstarrt so lange (Eisball, ADR-0073).
  final double freezeSeconds;

  /// Ob es ein Bumerang ist: Er fliegt durch Gegner und kehrt um
  /// (Wiederkehr, ADR-0073).
  final bool boomerang;

  Vec2 position;
  double age = 0;
  bool spent = false;

  /// Nur beim Bumerang: ob er schon auf dem Rückweg ist, und wen er auf
  /// dem laufenden Weg schon getroffen hat.
  bool returning = false;

  /// Nach so vielen Sekunden kehrt ein Bumerang um.
  double returnAfter = 0;
  final Set<int> hitIds = <int>{};
}

/// Ein Geschoss, wie der Renderer es sieht.
class ProjectileView {
  const ProjectileView({
    required this.id,
    required this.faction,
    required this.position,
    required this.direction,
    required this.radius,
    this.isBoulder = false,
    this.isBoomerang = false,
    this.isFreezing = false,
  });

  factory ProjectileView.of(Projectile p) {
    return ProjectileView(
      id: p.id,
      faction: p.faction,
      position: p.position,
      direction: p.velocity.normalized,
      radius: p.radius,
      isBoulder: p.isBoulder,
      isBoomerang: p.boomerang,
      isFreezing: p.freezeSeconds > 0,
    );
  }

  final int id;
  final Faction faction;
  final Vec2 position;
  final Vec2 direction;
  final double radius;
  final bool isBoulder;

  /// Die Kugel der Wiederkehr, die zurückkommt.
  final bool isBoomerang;

  /// Der Eisball.
  final bool isFreezing;
}
