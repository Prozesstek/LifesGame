import 'vec2.dart';

/// Wer auf wen schlägt.
enum Faction { held, gegner }

/// Welche Art Gegner. Der Held trägt [EnemyKind.keiner].
enum EnemyKind { keiner, fussvolk, endgegner }

/// Eine Figur in der Halle.
///
/// **Veränderlich — und das ist hier richtig.** Alle anderen Packages
/// dieses Projekts geben bei jeder Änderung einen neuen Wert zurück, und
/// das aus gutem Grund: Dort geht es um Nutzerzustand, der gespeichert,
/// abgeleitet und zurückgenommen wird. Hier geht es um eine Position, die
/// sechzigmal je Sekunde weiterrückt. Für dreissig Figuren wären das
/// 1800 neue Objekte je Sekunde, und Dart räumt sie mit Pausen weg, die
/// man als Ruckeln sieht.
///
/// Die Grenze bleibt trotzdem scharf: Aus der Halle kommt **nichts**
/// heraus ausser Ereignissen ([ActionEvent]) und dem Ergebnis. Niemand
/// ausserhalb dieses Packages bekommt eine Figur in die Hand, die er
/// verändern könnte.
class ActionEntity {
  ActionEntity({
    required this.id,
    required this.faction,
    required this.kind,
    required this.position,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.radius,
    required this.speed,
    required this.attackRange,
    required this.attackCooldown,
    this.damageMultiplier = 1,
    this.critChance = 0,
    this.critFactor = 2,
  }) : hp = maxHp;

  final int id;
  final Faction faction;
  final EnemyKind kind;

  final int maxHp;
  final int attack;
  final int defense;
  final double radius;
  final double speed;
  final double attackRange;

  /// Sekunden zwischen zwei Schlägen.
  final double attackCooldown;

  final double damageMultiplier;
  final double critChance;
  final double critFactor;

  Vec2 position;
  int hp;

  /// Sekunden, bis wieder geschlagen werden darf.
  double cooldownLeft = 0;

  /// Ob dieser Gegner den Helden bemerkt hat.
  bool aggro = false;

  /// Wohin die Figur zuletzt gesehen hat — nur für die Darstellung.
  Vec2 facing = const Vec2(0, 1);

  bool get isAlive => hp > 0;

  bool get isHero => faction == Faction.held;

  /// Anteil der verbliebenen Lebenspunkte, 0 bis 1.
  double get hpRatio => maxHp <= 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);

  /// Nimmt Schaden und gibt zurück, was tatsächlich abgezogen wurde.
  int takeDamage(int amount) {
    final vorher = hp;
    hp = (hp - amount).clamp(0, maxHp);
    return vorher - hp;
  }
}

/// Ein Blick auf eine Figur, den der Renderer bekommt.
///
/// Eine Kopie, kein Verweis: Die Darstellung soll zeichnen, nicht
/// mitspielen. Dieselbe Trennung wie zwischen `CombatSession` und
/// `battle_game.dart`.
class EntityView {
  const EntityView({
    required this.id,
    required this.faction,
    required this.kind,
    required this.position,
    required this.radius,
    required this.hpRatio,
    required this.facing,
    required this.isAlive,
  });

  factory EntityView.of(ActionEntity entity) {
    return EntityView(
      id: entity.id,
      faction: entity.faction,
      kind: entity.kind,
      position: entity.position,
      radius: entity.radius,
      hpRatio: entity.hpRatio,
      facing: entity.facing,
      isAlive: entity.isAlive,
    );
  }

  final int id;
  final Faction faction;
  final EnemyKind kind;
  final Vec2 position;
  final double radius;
  final double hpRatio;
  final Vec2 facing;
  final bool isAlive;
}
