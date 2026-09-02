import 'ability.dart';

/// Alle Fähigkeiten des Spiels an einem Ort.
///
/// Gleiche Regel wie bei Preisen, Belohnungen und Titeln: Steht eine
/// dieser Bedingungen irgendwo anders im Code, ist das ein Bug.
///
/// **[choosable] ist der Stand von ADR-0022:** die fünfzehn Fähigkeiten
/// aus der Vorlage, elf an Theorieknoten, vier an Streak-Marken. Der
/// Zwischenstand aus ADR-0017 — Kraftschlag, Zehrung, Sammeln, Atemzug —
/// ist damit **abgelöst**. Die vier existieren in `package:combat` weiter
/// (Gegner benutzen sie), sind aber nicht mehr wählbar.
///
/// **Wer hier etwas herausnimmt, macht Spielstände ungültig.** Eine Id,
/// die ein Spieler auf einem Platz liegen hat und die hier verschwindet,
/// blockiert diesen Platz — sichtbar belegt, im Kampf wirkungslos. Genau
/// das ist bei ADR-0022 passiert. Seit ADR-0024 räumt
/// [ChosenAbilities.fromJson] solche Reste beim Laden weg; das ändert
/// nichts daran, dass eine Streichung hier eine Entscheidung ist.
///
/// **Seit ADR-0019 hängen die wählbaren an Knoten** statt offen zu sein.
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

  /// Die fünfzehn Fähigkeiten, die der Spieler auf die freien Slots legen
  /// kann (ADR-0022).
  ///
  /// Waffenfähigkeiten stehen **nicht** hier: Sie werden nicht gewählt,
  /// sondern folgen aus der Ausrüstung (ADR-0013). [weaponMoves] regelt
  /// das.
  ///
  /// **Elf hängen am Baum, vier an Streak-Marken.** Beide Quellen aus
  /// ADR-0013 werden benutzt, und die Aufteilung sagt etwas aus: Lesen
  /// gibt die Werkzeuge, Durchhalten gibt die Wucht. Sternenfall — die
  /// einzige legendäre — kommt ausschließlich über sechzig Tage Kette.
  ///
  /// **Warum nach Gebiet und nicht nach Tiefe.** Der Baum ist genau eine
  /// Ebene tief: Alle zwanzig Unterknoten hängen direkt an den vier
  /// Wurzeln und kosten je einen Punkt (ADR-0019). Eine Staffelung nach
  /// Tiefe gibt es also nicht zu holen. Was die frühen von den späten
  /// Fähigkeiten trennt, ist die **Energie**: Vulkanbruch kostet 8,
  /// Sternenfall 10 — und das Maximum kommt aus Klarheit, also aus
  /// Häkchen.
  static const List<Ability> choosable = <Ability>[
    // --- Körper: der Einstieg ---
    Ability(
      moveId: 'funkenstoss',
      source: FromTheory('koerper-bewegung'),
      requirement: 'Körper: „Die kleinste Dosis, die wirkt" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'steinhaut',
      source: FromTheory('gesellschaft-grenzen'),
      requirement: 'Körper: „Stress" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'wurzelgriff',
      source: FromTheory('koerper-ernaehrung'),
      requirement: 'Körper: „Essen ist ein Umgebungsproblem" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'aurastrom',
      source: FromTheory('koerper-schlaf'),
      requirement: 'Körper: „Schlaf ist keine verlorene Zeit" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'bluetentau',
      source: FromTheory('gesellschaft-hilfe'),
      requirement: 'Körper: „Erholung" bestehen',
      rarity: Rarity.uncommon,
    ),

    // --- Geist: Technik und Kontrolle ---
    Ability(
      moveId: 'klingenwirbel',
      source: FromTheory('geist-wiederholung'),
      requirement: 'Geist: „Wiederholung" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'frostnebel',
      source: FromTheory('geist-gedanken'),
      requirement: 'Geist: „Gedanken sind keine Tatsachen" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'prisma_barriere',
      source: FromTheory('wissenschaft-quelle'),
      requirement: 'Geist: „Unbehagen aushalten" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'giftmoor',
      source: FromTheory('gesellschaft-umfeld'),
      requirement: 'Geist: „Motivation" bestehen',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'zeitdehnung',
      source: FromTheory('geist-aufmerksamkeit'),
      requirement:
          'Geist: „Aufmerksamkeit ist die eigentliche Währung" bestehen',
      rarity: Rarity.epic,
    ),

    // --- Wissenschaft ---
    Ability(
      moveId: 'vulkanbruch',
      source: FromTheory('wissenschaft-ursache'),
      requirement: 'Wissenschaft: „Zusammenhang ist keine Ursache" bestehen',
      rarity: Rarity.epic,
    ),

    // --- Streak-Marken: was Durchhalten gibt ---
    Ability(
      moveId: 'donnerkeil',
      source: FromStreak(7),
      requirement: '7 Tage Kette',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'sandsturm',
      source: FromStreak(14),
      requirement: '14 Tage Kette',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'seelenraub',
      source: FromStreak(30),
      requirement: '30 Tage Kette',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'sternenfall',
      source: FromStreak(60),
      requirement: '60 Tage Kette',
      rarity: Rarity.legendary,
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
