/// **Was erst mit einem Level aufgeht** (ADR-0098).
///
/// Der Weg des Mentors bleibt an Taten (ADR-0068, ADR-0079): Gewohnheit,
/// Theorie, Fähigkeiten, Kampf, Laden, Ausrüstung kommen, wenn es dort
/// etwas zu tun gibt. Was **danach** kommt, wartet auf ein Level — damit
/// ein Aufstieg etwas Neues bringt und die Startseite am ersten Tag nicht
/// alles auf einmal zeigt.
///
/// Dieses Package weiß nicht, was ein Lagerfeuer oder ein Haustier ist.
/// Es hält nur, **ab wann** — wie [AbilitySlots] die Plätze.
enum LevelExtra {
  /// Truhe, Dailies, Rückfrage, „Morgen zuerst“ (ADR-0076).
  lagerfeuer(3),

  /// Der eine Lauf des Tages (ADR-0072).
  tagesdungeon(4),

  /// Das Haustier (ADR-0086) — Frederiks Beispiel.
  haustier(5),

  /// Der Kreis der Statistik (ADR-0087).
  statistik(7),

  /// Die Sammlung samt Errungenschaften (ADR-0080).
  sammlung(10);

  const LevelExtra(this.level);

  /// Ab welchem Level es offen ist.
  final int level;

  bool offenAuf(int level) => level >= this.level;

  /// Was genau auf [level] aufgeht.
  static List<LevelExtra> aufLevel(int level) => <LevelExtra>[
        for (final e in values)
          if (e.level == level) e,
      ];
}
