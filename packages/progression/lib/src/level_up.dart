import 'ability_slots.dart';
import 'level_curve.dart';
import 'level_extras.dart';
import 'power_curve.dart';
import 'theory_points.dart';

/// **Was ein Aufstieg bringt** — von [from] auf [to], auch über mehrere
/// Level auf einmal.
///
/// Die Feier in der App zählt das auf, statt „Level 7" allein zu zeigen:
/// Ein Level ist seit ADR-0042 der grösste Sprung im Spiel, und wer nicht
/// sieht, was er bringt, merkt ihn nicht. Gerechnet wird hier, aus den
/// Kurven, die es schon gibt — keine neue Zahl.
class LevelUp {
  const LevelUp._({
    required this.from,
    required this.to,
    required this.theoryPoints,
    required this.powerGain,
    required this.newSlots,
    required this.extras,
    required this.opensUltimate,
  });

  factory LevelUp.between(int from, int to) {
    return LevelUp._(
      from: from,
      to: to,
      theoryPoints: to > from
          ? TheoryPoints.earnedAt(to) - TheoryPoints.earnedAt(from)
          : 0,
      powerGain:
          to > from ? PowerCurve.factorFor(to) / PowerCurve.factorFor(from) : 1,
      newSlots: <int>[
        for (var slot = 1; slot <= AbilitySlots.total; slot++)
          if (AbilitySlots.levelForSlot(slot) case final ab?)
            if (ab > from && ab <= to) slot,
      ],
      extras: <LevelExtra>[
        for (final e in LevelExtra.values)
          if (e.level > from && e.level <= to) e,
      ],
      opensUltimate:
          AbilitySlots.ultimateLevel > from && AbilitySlots.ultimateLevel <= to,
    );
  }

  final int from;
  final int to;

  /// Neue Theoriepunkte.
  final int theoryPoints;

  /// Um welchen Faktor der Held im Kampf stärker wird (`PowerCurve`).
  final double powerGain;

  /// Die Fähigkeitsplätze, die dabei aufgehen, ab 1 gezählt.
  final List<int> newSlots;

  /// Was dabei aufgeht (ADR-0098) — Lagerfeuer, Haustier und so fort.
  final List<LevelExtra> extras;

  /// Ob der Platz der Ultimate aufgeht (ADR-0073).
  final bool opensUltimate;

  /// Ob der Aufstieg mehr bringt als Punkt und Macht — ein Meilenstein
  /// auf der Roadmap.
  bool get isMilestone =>
      newSlots.isNotEmpty || extras.isNotEmpty || opensUltimate || isMax;

  bool get isLevelUp => to > from;

  /// Ob das Höchstlevel erreicht ist.
  bool get isMax => to >= LevelCurve.maxLevel;
}
