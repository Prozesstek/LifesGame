/// Wie viele Fähigkeitsslots ein Level offen hat.
///
/// Gleiche Regel wie bei der Levelkurve: Steht eine dieser Zahlen
/// irgendwo anders im Code, ist das ein Bug.
///
/// **Warum das hier liegt und nicht bei den Fähigkeiten.** Ein Slot ist
/// nichts, was eine Fähigkeit mitbringt — er ist das, was ein
/// Levelaufstieg *gibt* (ADR-0012). Deshalb steht er neben der Kurve, die
/// bestimmt, wann dieser Aufstieg kommt. Was später in den Slots liegt,
/// weiß dieses Package nicht und soll es nicht wissen.
///
/// **Was hier bewusst noch fehlt.** ADR-0012 nennt drei Dinge, die ein
/// Aufstieg gibt: einen Theoriepunkt je Stufe, einen Fähigkeitspunkt auf
/// jeder dritten, und die Slots auf 3/6/10. Nur die Slots stehen hier.
/// Die beiden Punktarten gehören daneben, sobald sie gebaut werden.
abstract final class AbilitySlots {
  /// Vier Plätze: drei frei wählbar, einer von der Waffe bestimmt
  /// (ADR-0013).
  static const int total = 4;

  /// Ab welchem Level der jeweilige Slot offen ist, aufsteigend.
  ///
  /// Der erste steht auf Level 1: Er trägt die Fähigkeit der getragenen
  /// Waffe, und ohne ihn hätte eine Waffe von Anfang an einen Teil, der
  /// nirgends hinkann.
  static const List<int> unlockLevels = <int>[1, 3, 6, 10];

  /// Wie viele Slots auf [level] offen sind — mindestens einer.
  static int openAt(int level) {
    var open = 0;
    for (final required in unlockLevels) {
      if (level >= required) open++;
    }
    return open < 1 ? 1 : open;
  }

  /// Ab welchem Level [slot] offen ist. [slot] zählt ab 1.
  /// Null, wenn es diesen Slot nicht gibt.
  static int? levelForSlot(int slot) {
    if (slot < 1 || slot > total) return null;
    return unlockLevels[slot - 1];
  }

  /// Die nächste Stufe, die einen weiteren Slot bringt.
  /// Null, wenn bereits alle offen sind.
  static int? nextUnlockAfter(int level) {
    for (final required in unlockLevels) {
      if (level < required) return required;
    }
    return null;
  }
}
