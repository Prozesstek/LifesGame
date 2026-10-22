/// Wie weit ein Haustier gewachsen ist.
///
/// **Es wächst an Tagen mit Häkchen**, nicht an Erfahrung: Jeder Tag, an
/// dem mindestens eine Gewohnheit abgehakt wurde, zählt, und keiner zählt
/// je wieder weg. Sonst wäre es nur ein zweites Level-Abzeichen — und es
/// könnte etwas verlieren, was es nie soll.
enum HaustierStufe {
  ei('Ei', abLevel: 1),
  schluepfling('Schlüpfling', abLevel: 3),
  jung('Jung', abLevel: 6),
  ausgewachsen('Ausgewachsen', abLevel: 10),
  praechtig('Prächtig', abLevel: 17),
  uralt('Uralt', abLevel: 27);

  const HaustierStufe(this.label, {required this.abLevel});

  final String label;

  /// Ab welchem Level das Tier diese Stufe erreicht.
  final int abLevel;

  /// Ab wie vielen Tagen mit Häkchen.
  int get abTagen => HaustierWachstum.tageFuer(abLevel);
}

/// Die Rechnung dahinter. Gleiche Regel wie bei allen Kurven des Spiels:
/// Steht eine dieser Zahlen irgendwo anders, ist das ein Bug.
abstract final class HaustierWachstum {
  /// **Jedes Level kostet einen Tag mehr als das vorige**: Level 2 nach
  /// einem Tag, Level 5 nach 10, Level 10 nach 45, Level 27 nach 351.
  /// Am Anfang geht es schnell, wie es bei einem Jungtier sein soll; nach
  /// einem Jahr steigt es noch, nur seltener.
  static int tageFuer(int level) {
    if (level <= 1) return 0;
    return level * (level - 1) ~/ 2;
  }

  /// Das Level nach [tage] Tagen mit Häkchen.
  static int levelFuer(int tage) {
    var level = 1;
    while (tageFuer(level + 1) <= tage) {
      level++;
    }
    return level;
  }

  /// Die Stufe nach [tage] Tagen mit Häkchen.
  static HaustierStufe stufeFuer(int tage) {
    final level = levelFuer(tage);
    var stufe = HaustierStufe.ei;
    for (final s in HaustierStufe.values) {
      if (level >= s.abLevel) stufe = s;
    }
    return stufe;
  }

  /// Wie viele Tage mit Häkchen bis zum nächsten Level fehlen.
  static int tageBisNaechstes(int tage) {
    return tageFuer(levelFuer(tage) + 1) - tage;
  }

  /// Die nächste Stufe, oder null, wenn es die letzte ist.
  static HaustierStufe? naechsteStufe(HaustierStufe stufe) {
    final i = stufe.index + 1;
    return i < HaustierStufe.values.length ? HaustierStufe.values[i] : null;
  }
}
