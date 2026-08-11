/// Zusatzwirkung eines Moves, unabhaengig vom Schaden.
sealed class MoveEffect {
  const MoveEffect();
}

final class ApplyPoison extends MoveEffect {
  const ApplyPoison();
}

final class ApplyDefenseDown extends MoveEffect {
  const ApplyDefenseDown();
}

final class HealSelf extends MoveEffect {
  const HealSelf();
}

final class ShieldSelf extends MoveEffect {
  const ShieldSelf();
}

/// Ein Move belegt einen der vier Slots.
///
/// Keine Typen-Effektivitaet (bewusste Konzeptentscheidung). Die einzige
/// taktische Ressource ist Energie.
class Move {
  const Move({
    required this.id,
    required this.name,
    required this.power,
    required this.energyDelta,
    this.effects = const <MoveEffect>[],
  });

  /// Stabiler Bezeichner fuer Events, Speicherstaende und UI.
  final String id;

  final String name;

  /// Schadensmultiplikator auf den Angriffswert. 0 bedeutet: richtet
  /// keinen direkten Schaden an.
  final double power;

  /// Positiv erzeugt Energie, negativ verbraucht sie.
  final int energyDelta;

  /// Zusatzwirkungen. Das Ziel ergibt sich aus der Art des Effekts:
  /// [HealSelf] und [ShieldSelf] wirken auf den Anwender, alle uebrigen
  /// auf den Gegner. Damit gibt es keine zweite Quelle der Wahrheit.
  final List<MoveEffect> effects;

  bool get dealsDamage => power > 0;

  /// Energie, die vorhanden sein muss. Erzeugende Moves fordern nichts.
  int get energyCost => energyDelta < 0 ? -energyDelta : 0;

  bool isAffordableBy(int energy) => energy >= energyCost;
}

/// Standard-Moveset gemaess Konzept, Abschnitt 3.2.
///
/// Vier Slots, feste Rollen: erzeugen, verbrauchen, schwaechen, stuetzen.
abstract final class Moves {
  /// Slot 1 — erzeugt Energie, das Rueckgrat jeder Runde.
  static const Move basicAttack = Move(
    id: 'basic_attack',
    name: 'Schlag',
    power: 1.0,
    energyDelta: 3,
  );

  /// Slot 2 — verbraucht viel, der Auszahlungsmoment.
  static const Move heavyAttack = Move(
    id: 'heavy_attack',
    name: 'Wuchtschlag',
    power: 2.2,
    energyDelta: -6,
  );

  /// Slot 3 — schwacher Direktschaden, dafuer Wirkung ueber Zeit.
  static const Move poisonStrike = Move(
    id: 'poison_strike',
    name: 'Giftklinge',
    power: 0.4,
    energyDelta: -3,
    effects: <MoveEffect>[ApplyPoison(), ApplyDefenseDown()],
  );

  /// Slot 4 — kein Schaden, dafuer Ausdauer im Dungeon. Weil HP zwischen
  /// den Kaempfen nicht heilen, ist dieser Slot die eigentliche
  /// Ressourcenentscheidung.
  static const Move mend = Move(
    id: 'mend',
    name: 'Sammeln',
    power: 0,
    energyDelta: -4,
    effects: <MoveEffect>[HealSelf(), ShieldSelf()],
  );

  static const List<Move> defaultLoadout = <Move>[
    basicAttack,
    heavyAttack,
    poisonStrike,
    mend,
  ];
}
