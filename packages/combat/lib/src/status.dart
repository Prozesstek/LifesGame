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
