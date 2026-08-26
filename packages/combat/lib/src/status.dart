/// Statuseffekte auf einem Kaempfer. Unveraenderlich: Ablauf einer Runde
/// erzeugt neue Instanzen, statt bestehende zu veraendern.
sealed class StatusEffect {
  const StatusEffect({required this.remainingTurns});

  /// Verbleibende Runden. Bei 0 laeuft der Effekt aus.
  final int remainingTurns;

  /// Stabiler Bezeichner fuer Events und UI. Kein `toString`, weil dieser
  /// Wert von der Darstellungsschicht ausgewertet wird.
  String get id;

  /// Eine Runde weiterzaehlen. Gibt `null` zurueck, wenn der Effekt endet.
  StatusEffect? ticked();
}

/// Schaden ueber Zeit. Wirkt am Rundenende.
final class Poison extends StatusEffect {
  const Poison({required this.damagePerTurn, required super.remainingTurns});

  final int damagePerTurn;

  @override
  String get id => 'poison';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return Poison(
      damagePerTurn: damagePerTurn,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// Senkt die Verteidigung des Traegers auf `factor` des Ausgangswerts.
final class DefenseDown extends StatusEffect {
  const DefenseDown({required this.factor, required super.remainingTurns});

  final double factor;

  @override
  String get id => 'defense_down';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return DefenseDown(factor: factor, remainingTurns: remainingTurns - 1);
  }
}

/// Absorbiert eingehenden Schaden, bis der Vorrat aufgebraucht ist.
final class Shield extends StatusEffect {
  const Shield({required this.absorb, required super.remainingTurns});

  final int absorb;

  @override
  String get id => 'shield';

  /// Nach dem Abfangen von [amount] Schaden. Gibt `null` zurueck, wenn
  /// der Schild dadurch bricht.
  Shield? afterAbsorbing(int amount) {
    final remaining = absorb - amount;
    if (remaining <= 0) return null;
    return Shield(absorb: remaining, remainingTurns: remainingTurns);
  }

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return Shield(absorb: absorb, remainingTurns: remainingTurns - 1);
  }
}

/// Brand. Wie [Poison] Schaden ueber Zeit, aber eine eigene Art:
/// Blütentau entfernt einen Effekt, und dann muss unterscheidbar sein,
/// welcher weg ist.
final class Burn extends StatusEffect {
  const Burn({required this.damagePerTurn, required super.remainingTurns});

  final int damagePerTurn;

  @override
  String get id => 'burn';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return Burn(
      damagePerTurn: damagePerTurn,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// Senkt eingehenden Schaden auf `factor` des Ausgangswerts.
///
/// Anders als [Shield] hat dieser Effekt keinen Vorrat: Er wirkt auf
/// jeden Treffer seiner Laufzeit, dafuer nur anteilig.
final class DamageReduction extends StatusEffect {
  const DamageReduction({
    required this.factor,
    required super.remainingTurns,
  });

  /// 0.6 bedeutet minus 40 %.
  final double factor;

  @override
  String get id => 'damage_reduction';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return DamageReduction(factor: factor, remainingTurns: remainingTurns - 1);
  }
}

/// Wirft einen Teil des erlittenen Schadens auf den Angreifer zurueck.
final class Reflect extends StatusEffect {
  const Reflect({
    required this.share,
    required super.remainingTurns,
    this.flatBonus = 0,
  });

  /// Anteil des erlittenen Schadens, der zurueckgeht. 0.3 = 30 %.
  final double share;

  /// Zusaetzlich fester Schaden, unabhaengig vom Treffer. Steinhaut mit
  /// perfektem Timing wirft 5 zurueck, auch wenn kaum etwas ankam.
  final int flatBonus;

  @override
  String get id => 'reflect';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return Reflect(
      share: share,
      flatBonus: flatBonus,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// Verkleinert das Perfect-Fenster des Traegers.
final class WindowShrink extends StatusEffect {
  const WindowShrink({required this.factor, required super.remainingTurns});

  /// 0.75 bedeutet minus 25 %.
  final double factor;

  @override
  String get id => 'window_shrink';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return WindowShrink(factor: factor, remainingTurns: remainingTurns - 1);
  }
}

/// Verlangsamt die eigene Leiste und belohnt Perfect zusaetzlich.
///
/// Beides zusammen in einem Effekt, weil Zeitdehnung genau das tut und
/// zwei getrennte Effekte immer gemeinsam auftreten wuerden.
final class TimeDilation extends StatusEffect {
  const TimeDilation({
    required this.speedFactor,
    required this.perfectBonus,
    required super.remainingTurns,
  });

  /// 0.5 bedeutet halbe Geschwindigkeit -- viel leichter zu treffen.
  final double speedFactor;

  /// Zusaetzlicher Schadensfaktor bei perfektem Timing. 0.15 = plus 15 %.
  final double perfectBonus;

  @override
  String get id => 'time_dilation';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return TimeDilation(
      speedFactor: speedFactor,
      perfectBonus: perfectBonus,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// Der Traeger bekommt keinen Timing-Bonus. Donnerkeil mit perfektem
/// Timing nimmt dem Gegner die naechste Runde.
final class TimingLocked extends StatusEffect {
  const TimingLocked({required super.remainingTurns});

  @override
  String get id => 'timing_locked';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return TimingLocked(remainingTurns: remainingTurns - 1);
  }
}

/// Die naechste Faehigkeit kostet weniger Energie.
final class CostReduction extends StatusEffect {
  const CostReduction({required this.amount, required super.remainingTurns});

  final int amount;

  @override
  String get id => 'cost_reduction';

  @override
  StatusEffect? ticked() {
    if (remainingTurns <= 1) return null;
    return CostReduction(amount: amount, remainingTurns: remainingTurns - 1);
  }
}
