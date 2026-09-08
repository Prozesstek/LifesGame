import 'gear_set.dart';

/// Die drei Sets des Spiels.
///
/// **Jedes wirkt auf genau eine Art von Fähigkeit.** Ein Set, das jede
/// Fähigkeit gleich verstärkt, wäre nur ein größerer Bonus — man nimmt das
/// stärkste und ist fertig. So lohnt sich ein Set genau dann, wenn die
/// belegten Plätze dazu passen, und das macht es zu einer Entscheidung im
/// Sinn von [ADR-0013].
///
/// **Welche Stücke dazugehören, steht an den Stücken** (`GearItem.setId`),
/// nicht hier. Sonst gäbe es zwei Listen, die auseinanderlaufen können —
/// derselbe Fallstrick wie bei den Fähigkeiten (`gotchas.md`).
///
/// Die drei Sets kosten fast gleich viel (1880 · 1870 · 1840 Gold), und
/// das ist keine Kosmetik: Wäre eines deutlich billiger, wäre die Wahl
/// zwischen ihnen keine Frage des Spielstils mehr, sondern des Geldbeutels.
/// `set_catalog_test.dart` hält die Spanne fest.
abstract final class GearSets {
  /// Angriff: härter zuschlagen, wenn man es sich leistet.
  static const GearSet eisernerWille = GearSet(
    id: 'set-eiserner-wille',
    name: 'Eiserner Wille',
    target: SetTarget.angriff,
    twoPiece: SetPerk(damageFactor: 1.10),
    fourPiece: SetPerk(damageFactor: 1.25),
    why: 'Für alle, die ihre freien Plätze mit Donnerkeil, Seelenraub und '
        'Sternenfall belegen. Auf den Waffenzug wirkt es bewusst nicht — '
        'den drückt man ohnehin jede Runde.',
  );

  /// Umgebung: die teuerste Art wird bezahlbar.
  static const GearSet sturmruf = GearSet(
    id: 'set-sturmruf',
    name: 'Sturmruf',
    target: SetTarget.umgebung,
    twoPiece: SetPerk(energyDiscount: 1),
    fourPiece: SetPerk(energyDiscount: 2),
    why: 'Umgebungen kosten sechs bis acht Energie und sind damit die '
        'teuerste Art im Spiel. Zwei Punkte Rabatt heißen: eine Runde '
        'früher, jedes Mal.',
  );

  /// Schutz: die Leiste wird zu treffen.
  static const GearSet ruhigerStand = GearSet(
    id: 'set-ruhiger-stand',
    name: 'Ruhiger Stand',
    target: SetTarget.schutz,
    twoPiece: SetPerk(timingSpeedFactor: 0.85, timingWindowFactor: 1.25),
    fourPiece: SetPerk(timingSpeedFactor: 0.7, timingWindowFactor: 1.6),
    why: 'Steinhaut und Prisma-Barriere leben von ihrer Perfect-Wirkung — '
        'und die verfehlt man ausgerechnet dann, wenn es eng wird. Eine '
        'breitere, langsamere Leiste macht Schutz verlässlich statt stark.',
  );

  static const List<GearSet> all = <GearSet>[
    eisernerWille,
    sturmruf,
    ruhigerStand,
  ];

  static GearSet? byId(String? id) {
    if (id == null) return null;
    for (final set in all) {
      if (set.id == id) return set;
    }
    return null;
  }
}
