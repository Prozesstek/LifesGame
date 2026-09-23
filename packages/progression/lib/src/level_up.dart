import 'ability_slots.dart';
import 'level_curve.dart';
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

  bool get isLevelUp => to > from;

  /// Ob das Höchstlevel erreicht ist.
  bool get isMax => to >= LevelCurve.maxLevel;
}
