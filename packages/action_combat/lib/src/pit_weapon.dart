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
    this.pierce = false,
    this.arcDegrees = 0,
    this.fs = 0,
  });

  /// **Zauberwaffe** (Skalierung, 08.11.2026): der Anteil der
  /// Fähigkeitsstärke am Grundangriff. Stäbe schlagen mit dem Geist,
  /// alles andere mit dem Körper — sonst bliebe ein Geist-Spieler immer
  /// schwach, denn den Lauf entscheidet der Grundangriff (ADR-0009).
  final double fs;

  /// Dieselbe Waffe, nur [faktor] mal so hart — Schlag und Brand.
  PitWeapon mitWucht(double faktor) => PitWeapon(
        moveId: moveId,
        name: name,
        power: power * faktor,
        cooldownFactor: cooldownFactor,
        range: range,
        ranged: ranged,
        hits: hits,
        cleave: cleave,
        manaOnHit: manaOnHit,
        burnPerSecond: burnPerSecond * faktor,
        pierce: pierce,
        arcDegrees: arcDegrees,
        fs: fs,
      );

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

  /// Ob der Stoss **alle in einer Linie** trifft — der Langspeer
  /// (ADR-0077). Breit ist sie `ActionBalance.spearHalfWidth`.
  final bool pierce;

  /// Ein Bogen vor dem Helden, so viele Grad weit: Alle darin werden
  /// getroffen — die Blutsichel (ADR-0077). Null heisst: nur der eine.
  final double arcDegrees;
}

/// Die zehn Waffen und der leere Platz.
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
    fs: 1,
  );

  // --- Die Stäbe (Skalierung, 08.11.2026): je Seltenheit einer ---

  /// Ein Funke, nicht weit, etwas langsam — der Bogen des Geists.
  static const PitWeapon funkenwurf = PitWeapon(
    moveId: 'staff_spark',
    name: 'Funkenwurf',
    power: 0.9,
    cooldownFactor: 1.1,
    range: 150,
    ranged: true,
    fs: 1,
  );

  /// Ein Splitter, der Mana zurückbringt.
  static const PitWeapon sternsplitter = PitWeapon(
    moveId: 'staff_star',
    name: 'Sternsplitter',
    power: 0.75,
    range: 170,
    ranged: true,
    manaOnHit: 2,
    fs: 1,
  );

  /// Ein Blitz, der nachbrennt.
  static const PitWeapon runenblitz = PitWeapon(
    moveId: 'staff_rune',
    name: 'Runenblitz',
    power: 1.0,
    range: 190,
    ranged: true,
    burnPerSecond: 0.2,
    fs: 1,
  );

  /// Drei Kometen auf einmal, jeder für sich leicht.
  static const PitWeapon kometenschauer = PitWeapon(
    moveId: 'staff_comet',
    name: 'Kometenschauer',
    power: 0.5,
    cooldownFactor: 1.15,
    range: 200,
    ranged: true,
    hits: 3,
    fs: 1,
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

  // --- Seit ADR-0077 ---

  /// Weiter als jede Nahkampfwaffe, und wer hintereinander steht, wird
  /// zusammen getroffen.
  static const PitWeapon speerstich = PitWeapon(
    moveId: 'spear_thrust',
    name: 'Speerstich',
    power: 1.1,
    cooldownFactor: 1.15,
    range: 68,
    pierce: true,
  );

  /// Schnelle Hiebe im Bogen, jeder für sich schwach — die Waffe des
  /// Vampirsets: Wer viele trifft, raubt viel.
  static const PitWeapon sichelhieb = PitWeapon(
    moveId: 'sickle_reap',
    name: 'Sichelhieb',
    // Erst 0,75: Stufe 13 nur zu 3 %, der Bogen zu 18 %.
    power: 0.9,
    cooldownFactor: 0.8,
    range: 40,
    arcDegrees: 120,
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
    speerstich,
    sichelhieb,
    funkenwurf,
    sternsplitter,
    runenblitz,
    kometenschauer,
  ];

  /// `null` für einen Zug, der keine Waffe ist.
  static PitWeapon? byMoveId(String moveId) {
    for (final waffe in all) {
      if (waffe.moveId == moveId) return waffe;
    }
    return null;
  }
}
