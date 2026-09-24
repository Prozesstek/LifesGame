/// Die Schlüssel zur Beute des Wächters (ADR-0048).
///
/// **Verdient wird woanders:** jedes Häkchen, jede bestandene Seite, jede
/// richtige Rückfrage ist einer. Diese Zahl rechnet die App aus den
/// Historien und reicht sie herein ([earned]). Dieses Package kennt nur,
/// wie viele schon verbraucht sind, und die Regel für den Vorrat.
///
/// **Höchstens [cap] auf Vorrat.** Aus der Historie liesse sich das nur
/// rechnen, wenn man wüsste, wann welcher Schlüssel kam. Deshalb verfällt
/// der Überhang **beim Einsetzen**: Wer 40 verdient und 0 verbraucht hat,
/// sieht 10; setzt er einen ein, zählen 31 als verbraucht, und er hat 9.
/// Gespeichert wird nur eine Zahl, die nie fällt.
abstract final class GearKeys {
  static const int cap = 10;

  /// Wie viele Schlüssel gerade da sind.
  static int available({required int earned, required int consumed}) {
    final rest = earned - consumed;
    if (rest <= 0) return 0;
    return rest > cap ? cap : rest;
  }

  /// Der neue Verbrauch nach einem eingesetzten Schlüssel — samt dem
  /// Überhang, der dabei verfällt. Unverändert, wenn keiner da ist.
  static int consume({required int earned, required int consumed}) {
    final da = available(earned: earned, consumed: consumed);
    if (da <= 0) return consumed;
    // Alles, was über dem Vorrat lag, ist jetzt weg, dazu der eine.
    return earned - da + 1;
  }
}
