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
  /// **Zehn Waffen, zehn verschiedene Züge** — die Tabelle aus ADR-0017,
  /// Punkt 2. Bis dahin gaben beide Klingen `sword_strike`; die Waffe
  /// bestimmte damit nichts, und der ganze Slot war Dekoration.
  ///
  /// **Keine zwei Waffen teilen sich einen Zug**, und keiner davon steht
  /// in [choosable]. Beides prüfen Tests: die Eindeutigkeit hier im
  /// Package, die Naht zum Laden in `test/abilities_seam_test.dart`.
  ///
  /// Was die fünf unterscheidet, ist nicht „mehr" oder „weniger",
  /// sondern *Schaden jetzt* gegen *Energie für später*:
  ///
  /// | Waffe | Zug | Power | Energie |
  /// |---|---|---|---|
  /// | Kurzbogen | Bogenschuss | 1,0 | +3 |
  /// | Übungsklinge | Hieb | 1,3 | +2 |
  /// | Streitkolben | Wuchtstoß | 0,9 | +3, Verteidigung runter |
  /// | Geschliffene Klinge | Doppelstich | 0,5 | +4 |
  /// | Kriegsstab | Sammelschlag | 0,6 | +5 |
  /// | Zweihänder | Spalter | 1,6 | +1 |
  /// | Langbogen | Doppelschuss | 0,45 × 2 | +4 |
  /// | Sonnenklinge | Sonnenhieb | 1,4 | +3, Perfect entzündet |
  /// | Langspeer | Speerstich | 1,1 | trifft alle in einer Linie |
  /// | Blutsichel | Sichelhieb | 0,9 | trifft alle im Bogen, raubt Leben |
  ///
  /// Die Zahlen der Tabelle stammen aus dem Rundenkampf; was in der
  /// Grube gilt, steht in `PitWeapons`. Langspeer und Blutsichel kamen
  /// mit ADR-0077 und haben nur dort Zahlen.
  ///
  /// **Die letzten drei hängen an der Gegnerreihe** (ADR-0034) und bringen
  /// je einen Rhythmus, den es unter den fünf ersten nicht gab: den
  /// langsamsten Schlag, den doppelten Pfeil, und den ersten Waffenzug mit
  /// einer Perfect-Wirkung.
  ///
  /// **Der Kurzbogen trägt denselben Zug wie [fallbackMoveId]**, und das
  /// ist Absicht: Laut ADR-0017 ist er eine der fünf Waffen, und „den
  /// Bogen hat jeder" ist genau der Grund, warum er auch der Rückfall
  /// ist. Gekauft gibt er Angriff statt eines neuen Rhythmus — der
  /// ruhigste Einstieg, den der Laden hat.
  static const Map<String, String> weaponMoves = <String, String>{
    'gear-kurzbogen': 'basic_attack',
    'gear-uebungsklinge': 'sword_strike',
    'gear-streitkolben': 'mace_bash',
    'gear-geschliffene-klinge': 'dagger_double',
    'gear-kriegsstab': 'staff_gather',
    'gear-zweihaender': 'greatsword_cleave',
    'gear-langbogen': 'longbow_volley',
    'gear-sonnenklinge': 'sunblade_flare',
    'gear-langspeer': 'spear_thrust',
    'gear-blutsichel': 'sickle_reap',
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
  /// **Warum nach Gebiet und nicht nach Tiefe.** Fast alle Knoten hängen
  /// direkt an den vier Wurzeln und kosten je einen Punkt (ADR-0019); der
  /// einzige tiefere (*Psychologie*) trägt keine Fähigkeit. Eine
  /// Staffelung nach Tiefe gibt es also nicht zu holen. Was die frühen von den späten
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

    // --- Aus Errungenschaften: die vier aus ADR-0017, zurückgeholt ---
    //
    // **Sie ersetzen nichts.** Die fünfzehn oben bleiben, wie sie sind;
    // diese kommen als sechzehnte bis neunzehnte Wahl dazu (ADR-0033,
    // Punkt 7). Neue Kampfzahlen entstehen dabei keine — alle vier
    // existieren in `package:combat` samt Werten, und die Gegner spielen
    // sie längst.
    //
    // **Die Seltenheit war in ADR-0033 als offen vermerkt und ist hier
    // entschieden**, nach dem, was ein Zug tut: Kraftschlag ist mit
    // `power` 2,2 der härteste Einzelschlag im Spiel und damit selten;
    // Zehrung und Sammeln sind Werkzeuge wie die übrigen Uncommons;
    // Atemzug *erzeugt* Energie, statt sie zu kosten, und ist damit der
    // ruhigste von allen.
    Ability(
      moveId: 'breath',
      source: FromAchievement('durchatmen'),
      requirement: 'Errungenschaft „Durchatmen"',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'poison_strike',
      source: FromAchievement('ein-gebiet-ganz'),
      requirement: 'Errungenschaft „Ein Gebiet ganz"',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'mend',
      source: FromAchievement('voll-ausgeruestet'),
      requirement: 'Errungenschaft „Voll ausgerüstet"',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'heavy_attack',
      source: FromAchievement('zehn-sprossen'),
      requirement: 'Errungenschaft „Zehn Sprossen"',
      rarity: Rarity.rare,
    ),

    // --- Frederiks zehn (ADR-0073, `docs/vorlagen/faehigkeiten-2.md`) ---
    //
    // Die Quellen stehen so in der Vorlage. Körper und Geist tragen damit
    // je sieben Fähigkeiten, Wissenschaft und Gesellschaft zwei und drei —
    // die Grenze „keines mehr als drei“ aus Issue #21 gilt seitdem nicht
    // mehr (`graph_content_test.dart`).
    Ability(
      moveId: 'glutspur',
      source: FromTheory('ausdauer-intervalle'),
      requirement: 'Ausdauer: „Intervalltraining" bestehen',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'fanghaken',
      source: FromTheory('psychologie-konformitaet'),
      requirement: 'Psychologie: „Die Macht der Mehrheit" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'glueckstrank',
      source: FromAchievement('zehn-truhen'),
      requirement: 'Errungenschaft „Zehn Truhen"',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'wiederkehr',
      source: FromTheory('philosophie-existenzialismus'),
      requirement: 'Philosophie: „Freiheit und Sinn" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'schnappfalle',
      source: FromTheory('gewohnheiten-offensichtlich'),
      requirement: 'Gewohnheiten: „Mach es offensichtlich" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'falke',
      source: FromStreak(14),
      requirement: '14 Tage Kette',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'steinschlag',
      source: FromTheory('kraft-intensitaet'),
      requirement: 'Kraft: „Wie nah ans Versagen" bestehen',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'rankenpeitsche',
      source: FromTheory('philosophie-stoizismus'),
      requirement: 'Philosophie: „Was in deiner Macht steht" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'rueckenwind',
      source: FromTheory('ausdauer-grundlage'),
      requirement: 'Ausdauer: „Locker und lang" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'eisball',
      source: FromStreak(30),
      requirement: '30 Tage Kette',
      rarity: Rarity.rare,
    ),

    // --- AktivesBretts zehn (ADR-0074, `docs/vorlagen/faehigkeiten-2.md`) ---
    //
    // Sechs hängen an Körper und Geist, je zwei an Wissenschaft und
    // Gesellschaft, damit keines mehr als zwei Fünftel trägt
    // (`graph_content_test.dart`). Der zweite Atem kommt über die Kette.
    Ability(
      moveId: 'zinseszins',
      source: FromTheory('gewohnheiten-zwei-minuten'),
      requirement: 'Gewohnheiten: „Zwei Minuten reichen" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'schattenschritt',
      source: FromTheory('psychologie-bystander'),
      requirement: 'Psychologie: „Warum keiner hilft" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'kampfrausch',
      source: FromTheory('psychologie-emotionen'),
      requirement: 'Psychologie: „Gefühle regulieren" bestehen',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'kriegsschrei',
      source: FromTheory('kraft-hypertrophie'),
      requirement: 'Kraft: „Wie ein Muskel wächst" bestehen',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'spiegelbild',
      source: FromTheory('wissenschaft-selbsttest'),
      requirement: 'Wissenschaft: „Sich selbst testen" bestehen',
      rarity: Rarity.epic,
    ),
    Ability(
      moveId: 'parade',
      source: FromTheory('wissenschaft-studie'),
      requirement: 'Wissenschaft: „Eine Überschrift ist keine Studie" '
          'bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'ruhepuls',
      source: FromTheory('schlaf-regeneration'),
      requirement: 'Körper: „Schlaf & Regeneration" bestehen',
      rarity: Rarity.common,
    ),
    Ability(
      moveId: 'kettenblitz',
      source: FromTheory('medien-information'),
      requirement: 'Gesellschaft: „Medien & Information" bestehen',
      rarity: Rarity.rare,
    ),
    Ability(
      moveId: 'rammbock',
      source: FromTheory('kraft-technik'),
      requirement: 'Kraft: „Technik vor Gewicht" bestehen',
      rarity: Rarity.uncommon,
    ),
    Ability(
      moveId: 'zweiter_atem',
      source: FromStreak(7),
      requirement: '7 Tage Kette',
      rarity: Rarity.epic,
    ),
  ];

  /// Die **Ultimates** (ADR-0073): je eine Bedingung aus den bestehenden
  /// Quellen, nie aus der Grube.
  ///
  /// **Sie stehen nicht in [choosable]** — eine Ultimate liegt nur auf
  /// ihrem eigenen Platz, und [byMoveId] findet sie deshalb nicht. Ihre
  /// [Ability.rarity] wird nicht gezeigt: Ultimates haben keine
  /// Seltenheit, sie tragen einen goldenen Doppelrand.
  ///
  /// **Mindestens eine ist auf Level 15 über den Baum erreichbar** — sonst
  /// ginge ihr Platz auf und bliebe leer. Das ist die Wassergrube;
  /// `test/abilities_seam_test.dart` hält es fest.
  static const List<Ability> ultimates = <Ability>[
    Ability(
      moveId: 'wassergrube',
      source: FromTheory('koerper-erholung'),
      requirement: 'Körper: „Erholung ist Teil der Arbeit" bestehen',
    ),
    Ability(
      moveId: 'fleischfressende_pflanze',
      source: FromStreak(30),
      requirement: '30 Tage Kette',
    ),
    // AktivesBretts zwei (ADR-0074).
    Ability(
      moveId: 'bestform',
      source: FromAchievement('sieben-tage-in-form'),
      requirement: 'Errungenschaft „Sieben Tage in Form"',
    ),
    Ability(
      moveId: 'rueckspulen',
      source: FromTheory('psychologie-gedaechtnis'),
      requirement: 'Psychologie: „Erinnerung ist kein Video" bestehen',
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

  /// Die Ultimate mit [moveId], oder null — auch für jede gewöhnliche.
  static Ability? ultimateByMoveId(String moveId) {
    for (final ability in ultimates) {
      if (ability.moveId == moveId) return ability;
    }
    return null;
  }

  /// Alle Ultimates, die zu diesem Stand offen sind.
  static List<Ability> unlockedUltimatesBy(AbilityProgress progress) {
    return List<Ability>.unmodifiable(
      ultimates.where((ability) => ability.isUnlockedBy(progress)),
    );
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
