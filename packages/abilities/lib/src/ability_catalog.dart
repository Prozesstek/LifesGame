import 'ability.dart';

/// Alle Fähigkeiten des Spiels an einem Ort.
///
/// Gleiche Regel wie bei Preisen, Belohnungen und Titeln: Steht eine
/// dieser Bedingungen irgendwo anders im Code, ist das ein Bug.
///
/// **Der Stand ist Zwischenstand, und das mit Ansage.** ADR-0017 legt
/// zwanzig Fähigkeiten fest. Hier stehen die **neun**, für die die Engine
/// heute schon reicht — die fünf Waffen plus Kraftschlag, Zehrung,
/// Sammeln und Atemzug. Die übrigen elf brauchen einen verallgemeinerten
/// Statuseffekt und drei neue Mechaniken in `package:combat`; sie kommen
/// als Einträge dazu, ohne dass hier etwas umgebaut werden müsste.
///
/// **Seit ADR-0019 hängen die vier wählbaren an Knoten** statt offen zu
/// sein. Alle vier liegen unter *Körper* — das ist Absicht: Es sind die
/// Themen, aus denen im Spiel Angriff und Trefferpunkte werden.
abstract final class AbilityCatalog {
  /// Was Slot 1 trägt, wenn keine Waffe angelegt ist.
  ///
  /// **Slot 1 darf nie leer sein.** Auf Level 1 ist er der einzige offene
  /// (ADR-0016) — ohne Rückfall stünde ein frischer Charakter ohne einen
  /// einzigen Move da und könnte den ersten Kampf nicht führen.
  ///
  /// Der Rückfall ist der Kurzbogen: Er ist bereits der Basisangriff des
  /// Spiels, die Kampfdarstellung hängt an seiner Id (ADR-0015), und „den
  /// Bogen hat jeder" ist eine Erklärung, die kein Ausrüstungsstück
  /// braucht.
  static const String fallbackMoveId = 'basic_attack';

  /// Welche Waffe welche Fähigkeit mitbringt.
  ///
  /// **Heute zwei Einträge, laut ADR-0017 sollen es fünf sein.** Dolch,
  /// Streitkolben und Stab gibt es im Laden noch nicht — und ob es sie
  /// als *Alternativen* zum selben Preis oder als Leiter geben soll, ist
  /// eine Entscheidung über den Laden, nicht über Fähigkeiten. Solange
  /// sie offen ist, bleibt diese Zuordnung kurz.
  static const Map<String, String> weaponMoves = <String, String>{
    'gear-uebungsklinge': 'sword_strike',
    'gear-geschliffene-klinge': 'sword_strike',
  };

  /// Die Fähigkeiten, die der Spieler auf die freien Slots legen kann.
  ///
  /// Waffenfähigkeiten stehen **nicht** hier: Sie werden nicht gewählt,
  /// sondern folgen aus der Ausrüstung (ADR-0013). [weaponMoves] regelt
  /// das.
  static const List<Ability> choosable = <Ability>[
    Ability(
      moveId: 'heavy_attack',
      source: FromTheory('koerper-bewegung'),
      requirement: 'Körper: „Die kleinste Dosis, die wirkt" bestehen',
    ),
    Ability(
      moveId: 'poison_strike',
      source: FromTheory('koerper-erholung'),
      requirement: 'Körper: „Erholung ist Teil der Arbeit" bestehen',
    ),
    Ability(
      moveId: 'mend',
      source: FromTheory('koerper-ernaehrung'),
      requirement: 'Körper: „Essen ist ein Umgebungsproblem" bestehen',
    ),
    Ability(
      moveId: 'breath',
      source: FromTheory('koerper-schlaf'),
      requirement: 'Körper: „Schlaf ist keine verlorene Zeit" bestehen',
    ),
  ];

  /// Welcher Move in Slot 1 liegt.
  ///
  /// Nie null: Ohne Waffe greift [fallbackMoveId].
  static String weaponMoveFor(String? weaponId) {
    return weaponMoves[weaponId] ?? fallbackMoveId;
  }

  /// Alle wählbaren Fähigkeiten, die zu diesem Stand offen sind.
  static List<Ability> unlockedBy(AbilityProgress progress) {
    return List<Ability>.unmodifiable(
      choosable.where((ability) => ability.isUnlockedBy(progress)),
    );
  }

  static Ability? byMoveId(String moveId) {
    for (final ability in choosable) {
      if (ability.moveId == moveId) return ability;
    }
    return null;
  }

  /// Ob dieser Move gewählt werden darf.
  ///
  /// Geprüft wird beim **Zusammenstellen**, nicht beim Speichern —
  /// dieselbe Trennung wie beim Titel: Der Spielstand hält eine Wahl, die
  /// Bedingung gilt genau einmal, bei der Anzeige (ADR-0014).
  static bool isUnlocked(String moveId, AbilityProgress progress) {
    final ability = byMoveId(moveId);
    return ability != null && ability.isUnlockedBy(progress);
  }
}
