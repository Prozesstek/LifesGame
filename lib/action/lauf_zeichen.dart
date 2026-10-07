/// Die Zeichen, mit denen sich die Grube erklärt (ADR-0069) — reine
/// Rechnung, ohne Bildschirm prüfbar.
///
/// **Zwei Dinge, und beide ohne Wort:** dass man zieht, um zu laufen, und
/// dass der Held von selbst schlägt. Im ersten Lauf liegt keine Fähigkeit
/// auf einem Platz; es steht also kein einziger Knopf da, und das
/// Steuerkreuz ist unsichtbar, bis der Daumen aufsetzt.
///
/// **Ein Stand je Lauf, nichts davon wird gespeichert.** Ob es die
/// Zeichen überhaupt gibt, sagt `ErsterStart.grubeErklaertSich` — bis die
/// erste Stufe geschafft ist. Wer den ersten Lauf verliert, bekommt sie im
/// nächsten wieder.
class LaufZeichen {
  /// Nach so vielen Punkten Weg verschwindet das Geister-Steuerkreuz:
  /// anderthalb Felder. Ein Wackeln der Hand reicht nicht, ein Schritt
  /// schon.
  static const double wegBisVerstanden = 48;

  /// Über die letzte Strecke davon blendet es aus, statt wegzuspringen.
  static const double ausblendWeg = 16;

  /// So lange steht das Zeichen am Helden, vom ersten Schlag an.
  static const double schlagSekunden = 4;

  /// Die letzte Sekunde davon blendet es aus.
  static const double schlagAusblenden = 1;

  double _weg = 0;
  double? _schlagAlter;

  /// Wie deckend das Geister-Steuerkreuz steht, 0 bis 1.
  double get ziehenDeckkraft {
    final rest = wegBisVerstanden - _weg;
    if (rest <= 0) return 0;
    return rest >= ausblendWeg ? 1 : rest / ausblendWeg;
  }

  bool get zeigtZiehen => ziehenDeckkraft > 0;

  /// Wie deckend das Zeichen am Helden steht, 0 bis 1.
  double get schlagDeckkraft {
    final alter = _schlagAlter;
    if (alter == null || alter >= schlagSekunden) return 0;
    final rest = schlagSekunden - alter;
    return rest >= schlagAusblenden ? 1 : rest / schlagAusblenden;
  }

  bool get zeigtSchlag => schlagDeckkraft > 0;

  /// Wie lange das Zeichen am Helden schon steht — für seine Drehung.
  double get schlagAlter => _schlagAlter ?? 0;

  /// Ein Bild weiter: [gelaufen] ist der Weg des Helden in diesem Bild.
  void advance(double dt, {required double gelaufen}) {
    if (gelaufen > 0) _weg += gelaufen;
    final alter = _schlagAlter;
    if (alter != null) _schlagAlter = alter + dt;
  }

  /// Der Held hat zugeschlagen. Nur der erste Schlag zählt: Das Zeichen
  /// kommt einmal je Lauf und fängt nicht mit jedem Hieb von vorn an.
  void heldSchlaegt() => _schlagAlter ??= 0;
}
