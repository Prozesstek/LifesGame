import 'ability_moves.dart';
import 'environment.dart';
import 'timing_spec.dart';

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

// --- Wirkungen des Faehigkeiten-Sets ---

/// Entzuendet den Gegner. [chance] 1.0 heisst immer.
final class ApplyBurn extends MoveEffect {
  const ApplyBurn({
    this.chance = 1.0,
    this.damageFactor = 3 / Environments.referenceAttack,
    this.turns = 2,
  });

  final double chance;

  /// Schaden je Runde als Vielfaches des eigenen Angriffswerts.
  final double damageFactor;
  final int turns;
}

/// Senkt eingehenden Schaden des Anwenders.
final class ReduceIncoming extends MoveEffect {
  const ReduceIncoming({required this.factor, this.turns = 1});

  final double factor;
  final int turns;
}

/// Wirft einen Teil des erlittenen Schadens zurueck.
final class ReflectIncoming extends MoveEffect {
  const ReflectIncoming({
    required this.share,
    this.turns = 2,
    this.flatBonus = 0,
  });

  final double share;
  final int turns;
  final int flatBonus;
}

/// Verkleinert das Perfect-Fenster des Gegners.
final class ShrinkEnemyWindow extends MoveEffect {
  const ShrinkEnemyWindow({required this.factor, required this.turns});

  final double factor;
  final int turns;
}

/// Verlangsamt die eigene Leiste und belohnt Perfect zusaetzlich.
final class DilateTime extends MoveEffect {
  const DilateTime({
    this.speedFactor = 0.5,
    this.perfectBonus = 0.15,
    this.turns = 2,
  });

  final double speedFactor;
  final double perfectBonus;
  final int turns;
}

/// Nimmt dem Gegner den Timing-Bonus der naechsten Runde.
final class LockEnemyTiming extends MoveEffect {
  const LockEnemyTiming({this.turns = 1});

  final int turns;
}

/// Die naechste Faehigkeit des Anwenders kostet weniger.
final class CheapenNext extends MoveEffect {
  const CheapenNext({this.amount = 1, this.turns = 2});

  final int amount;
  final int turns;
}

/// Heilt den Anwender um einen Anteil des zugefuegten Schadens.
final class LifeSteal extends MoveEffect {
  const LifeSteal({required this.share});

  /// 1.0 = 100 % des Schadens.
  final double share;
}

/// Stiehlt dem Gegner Energie und gibt sie dem Anwender.
final class StealEnergy extends MoveEffect {
  const StealEnergy({required this.amount});

  final int amount;
}

/// Entfernt einen negativen Statuseffekt vom Anwender.
final class CleanseSelf extends MoveEffect {
  const CleanseSelf();
}

/// Heilt den Anwender um ein Vielfaches seines Angriffswerts.
///
/// Eigener Effekt neben [HealSelf], weil dieser eine Zahl mitbringt --
/// [HealSelf] nimmt die aus [Balance].
final class HealSelfBy extends MoveEffect {
  const HealSelfBy({required this.factor});

  final double factor;
}

/// Legt eine Umgebung. Die Id zeigt in [Environments].
final class SetEnvironment extends MoveEffect {
  const SetEnvironment(this.environmentId);

  final String environmentId;
}

/// Gibt dem Anwender Energie, zusaetzlich zu [Move.energyDelta].
///
/// Eigener Effekt, weil Aurastrom bei perfektem Timing **mehr** gibt als
/// im Grundfall -- und `energyDelta` steht am Move, nicht an der Wirkung.
final class GainEnergy extends MoveEffect {
  const GainEnergy({required this.amount});

  final int amount;
}

/// Ignoriert Schild, Schadensminderung und Reflexion.
final class IgnoreProtection extends MoveEffect {
  const IgnoreProtection();
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
    this.perfectEffects = const <MoveEffect>[],
    this.timing = TimingSpec.standard,
    this.perfectFactor,
    this.missFactor,
    this.hits = 1,
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

  /// Wirkungen, die **nur** bei perfektem Timing eintreten.
  ///
  /// Die Vorlage trennt beides sauber: Funkenstoss macht immer Schaden,
  /// entzuendet aber nur bei Perfect. Zwei Listen sind ehrlicher als ein
  /// Effekt, der intern nachfragt, wie gut getroffen wurde.
  final List<MoveEffect> perfectEffects;

  /// Wie schwer der perfekte Treffer ist.
  final TimingSpec timing;

  /// Eigener Schadensfaktor bei perfektem Timing.
  ///
  /// **Warum das hier steht und nicht in [Balance].** ADR-0009 hat den
  /// pauschalen Deckel von +20 % gemessen und begruendet: Ein Faktor, der
  /// auf *jeden* Treffer wirkt, entscheidet den Kampf allein. Dieser Wert
  /// ist etwas anderes -- er gilt nur fuer eine einzelne Faehigkeit, die
  /// Energie kostet und ein enges Fenster hat. Der Bonus ist verdient,
  /// nicht geschenkt.
  ///
  /// `null` bedeutet: Es gilt der Deckel aus [Balance]. Basisangriff und
  /// alle Waffenmoves lassen das bewusst so -- sie werden jede Runde
  /// gedrueckt, und genau dort galt die Messung.
  final double? perfectFactor;

  /// Eigener Schadensfaktor, wenn das Fenster verfehlt wurde.
  ///
  /// `null` heisst: kein Abzug, wie ueberall sonst. Nur Sternenfall setzt
  /// das -- Verfehlen kostet dort mehr als den entgangenen Bonus.
  final double? missFactor;

  /// Wie oft getippt und getroffen wird. Klingenwirbel hat drei.
  final int hits;

  bool get isMultiHit => hits > 1;

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
  /// Sucht erst unter den Grundmoves, dann im Faehigkeiten-Set.
  ///
  /// Ein Aufrufer soll nicht wissen muessen, aus welchem der beiden
  /// Kataloge eine Id stammt -- fuer ihn ist es einfach ein Move.
  static Move? byId(String id) {
    for (final move in all) {
      if (move.id == id) return move;
    }
    return AbilityMoves.byId(id);
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
