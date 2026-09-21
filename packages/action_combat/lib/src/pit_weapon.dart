import 'balance.dart';

/// Was die Waffe aus dem Grundangriff macht (ADR-0039).
///
/// **Die Waffe ist der Grundangriff, kein Knopf.** Im Rundenkampf brachte
/// sie einen Zug mit, den man jede Runde drückte (ADR-0017). In der Grube
/// schlägt der Held von selbst — also bestimmt die Waffe, *wie*: Wer
/// einen Bogen trägt, schiesst; wer einen Zweihänder trägt, trifft alles
/// vor sich. Der Rhythmus, den ADR-0029 als Grund für Sidegrades nannte,
/// wird hier sichtbar statt nur gerechnet.
///
/// Die Ids sind die **Waffenzüge** aus `package:combat`, nicht die
/// Ausrüstungs-Ids: Dieses Package kennt `gear` nicht, und die Zuordnung
/// Waffe → Zug steht bereits an einer Stelle
/// (`AbilityCatalog.weaponMoves`).
class PitWeapon {
  const PitWeapon({
    required this.moveId,
    required this.name,
    required this.power,
    this.cooldownFactor = 1,
    this.range = ActionBalance.heroAttackRange,
    this.ranged = false,
    this.hits = 1,
    this.cleave = false,
    this.manaOnHit = 0,
    this.burnPerSecond = 0,
  });

  final String moveId;
  final String name;

  /// Faktor auf den Angriffswert je Treffer.
  final double power;

  /// Faktor auf die Zeit zwischen zwei Schlägen. Grösser ist langsamer.
  final double cooldownFactor;

  /// Reichweite ab Mittelpunkt. Fernwaffen sehen weiter, als sie im
  /// Nahkampf reichen würden.
  final double range;

  /// Ob ein Geschoss fliegt, statt dass ein Schlag fällt.
  final bool ranged;

  /// Wie viele Treffer je Schlag — zwei Stiche, zwei Pfeile.
  final int hits;

  /// Ob der Schlag **alle** in Reichweite trifft statt nur den nächsten.
  final bool cleave;

  /// Mana je Treffer — die Waffe, die Fähigkeiten bezahlt.
  final int manaOnHit;

  /// Brand je Sekunde auf dem Getroffenen, als Vielfaches des Angriffs.
  final double burnPerSecond;
}

/// Die acht Waffen und der leere Platz.
///
/// Hier wird geschrieben wie in `pit_ability.dart`. Wer eine ändert, lässt
/// `dart run tool/pit_sim.dart` laufen.
abstract final class PitWeapons {
  /// Ohne Waffe: der Grundschlag, mit dem der Prototyp gespielt wurde.
  ///
  /// Im Spiel kommt das nicht vor — ohne gekaufte Waffe trägt jeder den
  /// Kurzbogen (ADR-0016). Er ist der Stand für Tests und den
  /// Entwicklermodus.
  static const PitWeapon fist = PitWeapon(
    moveId: '',
    name: 'Faust',
    power: 1,
  );

  /// Der Rückfall für alle, und der ruhigste Einstieg: schwach, aber aus
  /// sicherer Entfernung.
  static const PitWeapon kurzbogen = PitWeapon(
    moveId: 'basic_attack',
    name: 'Bogenschuss',
    power: 0.8,
    range: 190,
    ranged: true,
  );

  static const PitWeapon hieb = PitWeapon(
    moveId: 'sword_strike',
    name: 'Hieb',
    power: 1.25,
  );

  /// Langsam, schwer.
  static const PitWeapon wuchtstoss = PitWeapon(
    moveId: 'mace_bash',
    name: 'Wuchtstoss',
    power: 1.6,
    cooldownFactor: 1.35,
  );

  /// Zwei schnelle Stiche.
  static const PitWeapon doppelstich = PitWeapon(
    moveId: 'dagger_double',
    name: 'Doppelstich',
    power: 0.6,
    cooldownFactor: 0.9,
    hits: 2,
  );

  /// Etwas mehr Reichweite, schwach — dafür Mana mit jedem Treffer.
  static const PitWeapon sammelschlag = PitWeapon(
    moveId: 'staff_gather',
    name: 'Sammelschlag',
    power: 0.8,
    range: 48,
    manaOnHit: 3,
  );

  /// Trifft alles in Reichweite, langsam.
  static const PitWeapon spalter = PitWeapon(
    moveId: 'greatsword_cleave',
    name: 'Spalter',
    power: 1.5,
    cooldownFactor: 1.4,
    range: 44,
    cleave: true,
  );

  /// Zwei Pfeile je Schuss, weiter als der Kurzbogen.
  static const PitWeapon doppelschuss = PitWeapon(
    moveId: 'longbow_volley',
    name: 'Doppelschuss',
    power: 0.55,
    range: 230,
    ranged: true,
    hits: 2,
  );

  /// Jeder Treffer brennt nach.
  static const PitWeapon sonnenhieb = PitWeapon(
    moveId: 'sunblade_flare',
    name: 'Sonnenhieb',
    power: 1.3,
    burnPerSecond: 0.25,
  );

  static const List<PitWeapon> all = <PitWeapon>[
    kurzbogen,
    hieb,
    wuchtstoss,
    doppelstich,
    sammelschlag,
    spalter,
    doppelschuss,
    sonnenhieb,
  ];

  /// `null` für einen Zug, der keine Waffe ist.
  static PitWeapon? byMoveId(String moveId) {
    for (final waffe in all) {
      if (waffe.moveId == moveId) return waffe;
    }
    return null;
  }
}
