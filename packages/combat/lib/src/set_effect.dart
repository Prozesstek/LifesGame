import 'move.dart';
import 'move_kind.dart';

/// Was ein vollstaendiges Ausruestungs-Set im Kampf aendert.
///
/// **Die Engine kennt keine Ausruestung** und soll es nicht. Was sie
/// bekommt, ist dieses Ergebnis: „auf Zuege dieser Art wirkt das". Woher es
/// kommt — welche vier Stuecke jemand traegt, was sie kosten, wie das Set
/// heisst — steht in `package:gear`, das dieses Package nicht kennt.
/// Zusammengefuegt wird beides in der App, wie bei den Kampfwerten auch.
///
/// Drei Hebel, mehr nicht:
///
/// | Hebel | wirkt auf |
/// |---|---|
/// | [damageFactor] | den angerichteten Schaden |
/// | [energyDiscount] | die Energiekosten |
/// | [timingSpeedFactor] / [timingWindowFactor] | die Leiste |
///
/// **Ein Set wirkt nur auf Zuege, die Energie kosten** ([appliesTo]). Der
/// Grund ist ADR-0009: Ein Faktor auf den Zug, den man *jede* Runde
/// drueckt, entscheidet den Kampf allein — genau deshalb hat der
/// Basisangriff keinen eigenen Perfect-Faktor. Ein Set, das den Waffenzug
/// verstaerkt, waere derselbe Fehler mit einer anderen Quelle.
///
/// Folge, die man kennen muss: **Aurastrom bekommt nichts.** Er ist eine
/// Schutz-Faehigkeit, die Energie *erzeugt*, und faellt damit durch dieses
/// Raster. Das ist der Preis dafuer, dass die Regel ohne eine zweite Liste
/// auskommt.
class SetEffect {
  const SetEffect({
    required this.kind,
    this.damageFactor = 1.0,
    this.energyDiscount = 0,
    this.timingSpeedFactor = 1.0,
    this.timingWindowFactor = 1.0,
  });

  /// Auf welche Art von Zuegen dieses Set wirkt.
  final MoveKind kind;

  /// Vielfaches auf den Schaden. 1.15 heisst 15 % mehr.
  final double damageFactor;

  /// Um wie viel die Energiekosten sinken. Nie unter null Kosten.
  final int energyDiscount;

  /// Vielfaches auf die Markergeschwindigkeit. Kleiner ist langsamer und
  /// damit leichter zu treffen.
  final double timingSpeedFactor;

  /// Vielfaches auf die Breite der Perfect-Zone. Groesser ist leichter.
  final double timingWindowFactor;

  /// Ob dieses Set auf [move] wirkt.
  bool appliesTo(Move move) => move.kind == kind && move.energyCost > 0;
}

/// Bequeme Rechnungen ueber mehreren Sets. Zwei Sets wirken
/// **multiplikativ** aufeinander, wie alles Uebrige im Timing auch.
extension SetEffects on Iterable<SetEffect> {
  double damageFactorFor(Move move) {
    var factor = 1.0;
    for (final set in this) {
      if (set.appliesTo(move)) factor *= set.damageFactor;
    }
    return factor;
  }

  int energyDiscountFor(Move move) {
    var discount = 0;
    for (final set in this) {
      if (set.appliesTo(move)) discount += set.energyDiscount;
    }
    return discount;
  }

  double timingSpeedFactorFor(Move move) {
    var factor = 1.0;
    for (final set in this) {
      if (set.appliesTo(move)) factor *= set.timingSpeedFactor;
    }
    return factor;
  }

  double timingWindowFactorFor(Move move) {
    var factor = 1.0;
    for (final set in this) {
      if (set.appliesTo(move)) factor *= set.timingWindowFactor;
    }
    return factor;
  }
}
