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
  /// Erzeugt Energie, das Rueckgrat jeder Runde. Gehoert zum *Kurzbogen*
  /// (ADR-0017).
  ///
  /// Der Name ist Anzeigetext, die Id ist es nicht: Die Darstellung haengt
  /// an `basic_attack` (siehe `lib/combat/battle/move_animation.dart`), nie
  /// am Wortlaut. Umbenennen aendert deshalb nichts an Balance oder Bild.
  static const Move basicAttack = Move(
    id: 'basic_attack',
    name: 'Bogenschuss',
    power: 1.0,
    energyDelta: 3,
  );

  /// Verbraucht viel, der Auszahlungsmoment. Kommt aus dem Knoten *Sport*
  /// (ADR-0017).
  static const Move heavyAttack = Move(
    id: 'heavy_attack',
    name: 'Kraftschlag',
    power: 2.2,
    energyDelta: -6,
  );

  /// Schwacher Direktschaden, dafuer Wirkung ueber Zeit. Kommt aus dem
  /// Knoten *Ernaehrung* (ADR-0017).
  ///
  /// **Die Schwaechung ist hier bewusst raus.** Bis ADR-0017 machte dieser
  /// Move Gift *und* Verteidigung runter. Beides zusammen nahm zwei der elf
  /// Theorieplaetze ihre Aufgabe weg; die Schwaechung gehoert jetzt zu
  /// *Bloesse finden* (Knoten Psychologie). Solange die noch nicht gebaut
  /// ist, fehlt sie im Spiel -- das ist eine gemessene Balance-Aenderung,
  /// keine Nebenwirkung (siehe `docs/context/state.md`).
  static const Move poisonStrike = Move(
    id: 'poison_strike',
    name: 'Zehrung',
    power: 0.4,
    energyDelta: -3,
    effects: <MoveEffect>[ApplyPoison()],
  );

  /// Kein Schaden, dafuer Ausdauer im Dungeon. Weil HP zwischen den
  /// Kaempfen nicht heilen, ist das die eigentliche Ressourcenentscheidung.
  /// Kommt aus dem Knoten *Schlaf* (ADR-0017).
  static const Move mend = Move(
    id: 'mend',
    name: 'Sammeln',
    power: 0,
    energyDelta: -4,
    effects: <MoveEffect>[HealSelf(), ShieldSelf()],
  );

  // --- Die uebrigen Waffen (ADR-0017) ---
  //
  // Alle Waffenmoves *erzeugen* Energie, keiner kostet welche. Das ist
  // keine Geschmacksfrage: Auf Level 1 ist nur Slot 1 offen, und der
  // gehoert der Waffe (ADR-0016). Ein Move, der Energie kostet, waere dort
  // unbezahlbar -- der erste Kampf eines neuen Spielers waere eine
  // Sackgasse.
  //
  // Der Unterschied zwischen ihnen ist der *Rhythmus*: Wer +5 erzeugt,
  // kann sich teure Moves leisten; wer +2 erzeugt, kommt selten dorthin
  // und schlaegt dafuer jede Runde haerter zu.

  /// Schwert: Schaden jetzt, teure Moves selten.
  static const Move swordStrike = Move(
    id: 'sword_strike',
    name: 'Hieb',
    power: 1.3,
    energyDelta: 2,
  );

  /// Dolch: wenig Schaden, dafuer schnell zum grossen Schlag.
  static const Move daggerDouble = Move(
    id: 'dagger_double',
    name: 'Doppelstich',
    power: 0.5,
    energyDelta: 4,
  );

  /// Streitkolben: bringt die Schwaechung mit, die *Zehrung* verloren hat.
  static const Move maceBash = Move(
    id: 'mace_bash',
    name: 'Wuchtstoss',
    power: 0.9,
    energyDelta: 3,
    effects: <MoveEffect>[ApplyDefenseDown()],
  );

  /// Stab: der Motor. Macht 'Richtiger Moment' (-8) ueberhaupt bezahlbar.
  static const Move staffGather = Move(
    id: 'staff_gather',
    name: 'Sammelschlag',
    power: 0.6,
    energyDelta: 5,
  );

  /// Knoten *Erholung*: eine Runde nichts tun, dafuer Energie und etwas
  /// Heilung. Der einzige Move ausserhalb der Waffen, der Energie erzeugt.
  static const Move breath = Move(
    id: 'breath',
    name: 'Atemzug',
    power: 0,
    energyDelta: 4,
    effects: <MoveEffect>[HealSelf()],
  );

  /// Jeder Move, den es gibt.
  ///
  /// Die Liste ist die Naht zu `package:abilities`: Dort steht, wie man an
  /// eine Faehigkeit kommt, hier was sie tut, und verbunden sind beide
  /// Seiten nur ueber die Id. Dass jede Id ankommt, prueft
  /// `test/abilities_seam_test.dart` in der App -- kein Package allein
  /// kann das.
  static const List<Move> all = <Move>[
    basicAttack,
    swordStrike,
    daggerDouble,
    maceBash,
    staffGather,
    heavyAttack,
    poisonStrike,
    mend,
    breath,
  ];

  /// Nachschlagen ueber die Id. Null, wenn es den Move nicht gibt.
  ///
  /// Gibt bewusst null zurueck statt zu werfen: Eine Id kann aus einem
  /// alten Spielstand kommen, und ein Kampf ohne Knoepfe waere die
  /// schlechtere Antwort darauf (ADR-0010).
  static Move? byId(String id) {
    for (final move in all) {
      if (move.id == id) return move;
    }
    return null;
  }

  /// Das Moveset der **Gegner** — und der Rueckfall, solange ein Spieler
  /// nichts gewaehlt hat.
  ///
  /// Nicht mehr 'die vier Slots des Spielers': Seit ADR-0017 stellt der
  /// Spieler sich sein Set aus dem zusammen, was er freigeschaltet hat.
  static const List<Move> defaultLoadout = <Move>[
    basicAttack,
    heavyAttack,
    poisonStrike,
    mend,
  ];
}
