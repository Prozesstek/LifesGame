import 'vec2.dart';

/// Wer auf wen schlägt.
enum Faction { held, gegner }

/// Welche Art Gegner. Der Held trägt [EnemyKind.keiner].
enum EnemyKind {
  keiner,

  /// Läuft heran und schlägt zu.
  fussvolk,

  /// Bleibt auf Abstand und schiesst.
  schuetze,

  /// Der Wächter am Ende. Wird nicht zurückgestossen.
  endgegner,

  /// Klein, schnell, schwach — schneller als der Held. Kommt im Rudel.
  ///
  /// **Er ist der Grund, dass Weglaufen nicht immer geht.** Gegen Fussvolk
  /// und Schützen ist Abstand die sichere Antwort; der Kobold holt einen
  /// ein, und man muss sich stellen.
  flink,

  /// Gross, langsam, zäh — ein Gegner zwischendurch, kein Endgegner.
  ///
  /// **Er ist der Grund, eine Fähigkeit aufzuheben.** Wer alles in die
  /// Traube davor verbrannt hat, steht vor ihm mit leerem Mana. Wird nicht
  /// zurückgestossen und lässt immer eine Heilkugel fallen.
  brocken,
}

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

  /// Ob die Figur gerade ausser Reichweite von allem ist — der Wächter,
  /// solange er schläft oder auftritt. Sie nimmt keinen Schaden, wird
  /// nicht anvisiert, von nichts geschoben und handelt nicht.
  bool untouchable = false;

  // --- Gegen Staus (ActionWorld._trackProgress) ---

  /// Wo die Figur zuletzt merklich vorangekommen ist.
  Vec2? progressAnchor;

  /// Wie lange sie beim Verfolgen schon auf der Stelle tritt.
  double stuckFor = 0;

  /// Solange das läuft, geht sie durch Verbündete hindurch — nicht durch
  /// Wände und nicht durch den Helden.
  double ghostLeft = 0;

  /// Wohin die Figur zuletzt gesehen hat — nur für die Darstellung.
  Vec2 facing = const Vec2(0, 1);

  // --- Zustände aus Fähigkeiten (ADR-0039) ---

  /// Tempo-Faktor, solange [slowLeft] läuft: Laufen und Zuschlagen.
  double slowFactor = 1;
  double slowLeft = 0;

  /// Schaden je Sekunde, solange [dotLeft] läuft — Gift, Brand, Frost.
  double dotPerSecond = 0;
  double dotLeft = 0;

  /// Zeit seit dem letzten Dauerschaden-Tick.
  double dotTick = 0;

  /// Mit welchem Anteil seines Tempos diese Figur gerade handelt.
  double get tempo => slowLeft > 0 ? slowFactor : 1;

  bool get isSlowed => slowLeft > 0;

  bool get isBurning => dotLeft > 0;

  bool get isAlive => hp > 0;

  bool get isHero => faction == Faction.held;

  /// Anteil der verbliebenen Lebenspunkte, 0 bis 1.
  double get hpRatio => maxHp <= 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);

  /// Nimmt Schaden und gibt zurück, was tatsächlich abgezogen wurde.
  int takeDamage(int amount) {
    if (untouchable) return 0;
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
    this.isSlowed = false,
    this.isBurning = false,
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
      isSlowed: entity.isSlowed,
      isBurning: entity.isBurning,
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

  /// Verlangsamt oder unter Dauerschaden — für eine Tönung im Renderer.
  final bool isSlowed;
  final bool isBurning;
}
