import 'achievement.dart';
import 'rewards.dart';
import 'stats.dart';

// Woran gemessen wird, je eine Zeile. Als Funktionen auf oberster Ebene,
// damit die Katalogeinträge konstant bleiben können — ein Katalog, der
// zur Laufzeit entsteht, wäre zur Laufzeit auch änderbar.
int _totalChecks(AchievementStats s) => s.totalChecks;
int _longestStreak(AchievementStats s) => s.longestStreak;
int _customHabitCount(AchievementStats s) => s.customHabitCount;
int _daysWithThreeChecks(AchievementStats s) => s.daysWithThreeChecks;
int _longestRunWithThreeChecks(AchievementStats s) =>
    s.longestRunWithThreeChecks;
int _checksOnHardCustomHabits(AchievementStats s) => s.checksOnHardCustomHabits;
int _comebackStreak(AchievementStats s) => s.comebackStreak;
int _openedChests(AchievementStats s) => s.openedChests;
int _passedLessons(AchievementStats s) => s.passedLessons;
int _perfectLessons(AchievementStats s) => s.perfectLessons;
int _completedAreas(AchievementStats s) => s.completedAreas;
int _areasWithPassedNode(AchievementStats s) => s.areasWithPassedNode;
int _retriedLessons(AchievementStats s) => s.retriedLessons;
int _highestRung(AchievementStats s) => s.highestRung;
int _comebackVictories(AchievementStats s) => s.comebackVictories;
int _everOwnedCount(AchievementStats s) => s.everOwnedCount;
int _slotsEverOwned(AchievementStats s) => s.slotsEverOwned;
int _completeSetsEverOwned(AchievementStats s) => s.completeSetsEverOwned;
int _soldCount(AchievementStats s) => s.soldCount;
int _skillKoerper(AchievementStats s) => s.skillKoerper;
int _skillGeist(AchievementStats s) => s.skillGeist;
int _skillWissenschaft(AchievementStats s) => s.skillWissenschaft;
int _skillGesellschaft(AchievementStats s) => s.skillGesellschaft;

/// Alle Errungenschaften des Spiels an einem Ort.
///
/// **34 Meilensteine und 8 Entdeckungen** — der erste Satz aus ADR-0033,
/// dazu „Zehn Truhen“ aus ADR-0073, „Erste Seite“ aus ADR-0079 und die
/// zwölf Titel der Gebiete aus ADR-0085.
/// Gleiche Regel wie bei Preisen, Belohnungen und Titeln: Steht eine
/// dieser Bedingungen irgendwo anders im Code, ist das ein Bug.
///
/// **Der Satz ist erweiterbar, und zwar rückwirkend.** Weil alles aus der
/// Historie abgeleitet wird, bekommt ein bestehender Spielstand eine neu
/// eingetragene Errungenschaft sofort, wenn er sie längst verdient hat.
/// Ein Teil lässt sich damit sogar während des Testlaufs nachliefern,
/// ohne dass jemandem etwas verloren geht.
///
/// **Was bewusst fehlt** und warum, steht in ADR-0033: der Frühaufsteher
/// (ein Häkchen kennt keine Uhrzeit), der Opportunist (keine
/// Tagesplanung), „Shop geöffnet" (kein Ereignisprotokoll), der Mentor
/// (keine Freunde) und der Chaosagent (nicht bestimmbar).
abstract final class AchievementCatalog {
  /// Sortiert nach Bereich, darin Meilensteine vor Entdeckungen und nach
  /// Stufe aufsteigend — dieselbe Reihenfolge wie im Bildschirm.
  static const List<Achievement> all = <Achievement>[
    // ---------------- Gewohnheiten ----------------
    Achievement(
      id: 'erster-schritt',
      name: 'Erster Schritt',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Ein Häkchen setzen',
      measure: _totalChecks,
    ),
    Achievement(
      id: 'entschlossen',
      name: 'der Entschlossene',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: '3 Tage am Stück',
      measure: _longestStreak,
      target: 3,
      titleId: 'entschlossen',
    ),
    Achievement(
      id: 'eigene-handschrift',
      name: 'Eigene Handschrift',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Eine eigene Gewohnheit anlegen',
      measure: _customHabitCount,
    ),
    Achievement(
      id: 'verlaesslich',
      name: 'der Verlässliche',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: '50 Häkchen gesetzt',
      measure: _totalChecks,
      target: 50,
      titleId: 'verlaesslich',
    ),
    // Der Atemzug ist die Fähigkeit der Gewohnheiten: Er erzeugt Energie,
    // ohne zu schlagen — und wird von Durchhalten verdient, nicht von
    // Lesen (ADR-0033, Punkt 7).
    Achievement(
      id: 'durchatmen',
      name: 'Durchatmen',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: '14 Tage mit mindestens 3 Häkchen',
      measure: _daysWithThreeChecks,
      target: 14,
      moveId: 'breath',
    ),
    // Der Glückstrank ist die Fähigkeit der Truhe: Wer zehnmal alles
    // erledigt hat, hat zehnmal gewürfelt (ADR-0073, Vorlage).
    Achievement(
      id: 'zehn-truhen',
      name: 'Zehn Truhen',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: '10 Tagestruhen geöffnet',
      measure: _openedChests,
      target: 10,
      moveId: 'glueckstrank',
    ),
    // Bestform ist die Tagesform als Ultimate: Wer an sieben Tagen alles
    // Fällige erledigt hat, war siebenmal in Form — die Tagestruhe zählt
    // genau diese Tage (ADR-0074).
    Achievement(
      id: 'sieben-tage-in-form',
      name: 'Sieben Tage in Form',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'an 7 Tagen alles erledigt (Tagestruhe geöffnet)',
      measure: _openedChests,
      target: 7,
      moveId: 'bestform',
    ),
    Achievement(
      id: 'bestaendig',
      name: 'der Beständige',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: '30 Tage am Stück',
      measure: _longestStreak,
      target: 30,
      titleId: 'bestaendig',
    ),
    Achievement(
      id: 'unermuedlich',
      name: 'der Unermüdliche',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: '200 Häkchen gesetzt',
      measure: _totalChecks,
      target: 200,
      titleId: 'unermuedlich',
    ),
    Achievement(
      id: 'unbeirrbar',
      name: 'der Unbeirrbare',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: '60 Tage am Stück',
      measure: _longestStreak,
      target: 60,
      titleId: 'unbeirrbar',
    ),
    Achievement(
      id: 'moench',
      name: 'der Mönch',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: '21 Tage am Stück mit je mindestens 3 Häkchen',
      measure: _longestRunWithThreeChecks,
      target: 21,
      titleId: 'moench',
    ),
    Achievement(
      id: 'herausforderer',
      name: 'der Herausforderer',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: '30 Häkchen bei schweren eigenen Gewohnheiten',
      measure: _checksOnHardCustomHabits,
      target: 30,
      titleId: 'herausforderer',
    ),
    Achievement(
      id: 'stoiker',
      name: 'der Stoiker',
      area: AchievementArea.gewohnheiten,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: 'Nach mindestens 3 Tagen Pause eine neue Kette von 7 Tagen',
      measure: _comebackStreak,
      target: 7,
      titleId: 'stoiker',
    ),

    // ---------------- Theorie ----------------
    // Funkenstoß ist die Fähigkeit der ersten Seite (ADR-0079): Jeder
    // bekommt dieselbe, egal welche Seite er zuerst liest — so fühlt
    // sich der Anfang für alle gleich an, und der Mentor kann sagen, was
    // als Nächstes kommt.
    Achievement(
      id: 'erste-seite',
      name: 'Erste Seite',
      area: AchievementArea.theorie,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Eine Seite bestehen',
      measure: _passedLessons,
      moveId: 'funkenstoss',
    ),
    Achievement(
      id: 'wissbegierig',
      name: 'der Wissbegierige',
      area: AchievementArea.theorie,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: '5 Lektionen bestanden',
      measure: _passedLessons,
      target: 5,
      titleId: 'wissbegierig',
    ),
    Achievement(
      id: 'belesen',
      name: 'der Belesene',
      area: AchievementArea.theorie,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: '12 Lektionen bestanden',
      measure: _passedLessons,
      target: 12,
      titleId: 'belesen',
    ),
    Achievement(
      id: 'fehlerfrei',
      name: 'Fehlerfrei',
      area: AchievementArea.theorie,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: '10 Seiten ohne einen Fehler',
      measure: _perfectLessons,
      target: 10,
    ),
    // Zehrung ist die Fähigkeit der Theorie: Gift wirkt über Zeit und
    // belohnt, wer vorausdenkt.
    Achievement(
      id: 'ein-gebiet-ganz',
      name: 'Ein Gebiet ganz',
      area: AchievementArea.theorie,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Ein Gebiet des Baums vollständig bestehen',
      measure: _completedAreas,
      moveId: 'poison_strike',
    ),
    Achievement(
      id: 'alchemist',
      name: 'der Alchemist',
      area: AchievementArea.theorie,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: 'In allen vier Gebieten mindestens einen Knoten bestehen',
      measure: _areasWithPassedNode,
      target: 4,
      titleId: 'alchemist',
    ),
    Achievement(
      id: 'zweiter-anlauf',
      name: 'Zweiter Anlauf',
      area: AchievementArea.theorie,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: 'Eine Lektion bestehen, an der man vorher gescheitert ist',
      measure: _retriedLessons,
    ),

    // ---------------- Kampf ----------------
    Achievement(
      id: 'erster-sieg',
      name: 'Erster Sieg',
      area: AchievementArea.kampf,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Sprosse 1 der Reihe schlagen',
      measure: _highestRung,
    ),
    // Kraftschlag ist die Fähigkeit des Kampfes — und mit `power` 2,2
    // stärker als die frühen Commons. Er kommt deshalb erst auf Sprosse
    // 10, wenn der Charakter ohnehin trägt (ADR-0033).
    Achievement(
      id: 'zehn-sprossen',
      name: 'Zehn Sprossen',
      area: AchievementArea.kampf,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'Sprosse 10 der Reihe schlagen',
      measure: _highestRung,
      target: 10,
      moveId: 'heavy_attack',
    ),
    Achievement(
      id: 'zwanzig-sprossen',
      name: 'Zwanzig Sprossen',
      area: AchievementArea.kampf,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Sprosse 20 der Reihe schlagen',
      measure: _highestRung,
      target: 20,
    ),
    Achievement(
      id: 'die-spitze',
      name: 'Die Spitze',
      area: AchievementArea.kampf,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Sprosse 30 der Reihe schlagen',
      measure: _highestRung,
      target: 30,
    ),
    Achievement(
      id: 'unbeugsam',
      name: 'der Unbeugsame',
      area: AchievementArea.kampf,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: 'Einen Gegner nach 3 Niederlagen gegen ihn doch schlagen',
      measure: _comebackVictories,
      titleId: 'unbeugsam',
    ),

    // ---------------- Laden ----------------
    Achievement(
      id: 'erster-kauf',
      name: 'Erster Kauf',
      area: AchievementArea.laden,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Ein Ausrüstungsstück kaufen',
      measure: _everOwnedCount,
    ),
    // Sammeln ist die Fähigkeit des Ladens: Es heilt und schildet, statt
    // zu schlagen — und passt damit zu dem, der seine Ausrüstung pflegt.
    Achievement(
      id: 'voll-ausgeruestet',
      name: 'Voll ausgerüstet',
      area: AchievementArea.laden,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'Auf allen 6 Plätzen je ein Stück besessen haben',
      measure: _slotsEverOwned,
      target: 6,
      moveId: 'mend',
    ),
    Achievement(
      id: 'sammler',
      name: 'Sammler',
      area: AchievementArea.laden,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: '15 verschiedene Stücke besessen haben',
      measure: _everOwnedCount,
      target: 15,
    ),
    Achievement(
      id: 'stratege',
      name: 'der Stratege',
      area: AchievementArea.laden,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: 'Alle 4 Teile eines Sets besessen haben',
      measure: _completeSetsEverOwned,
      titleId: 'stratege',
    ),
    Achievement(
      id: 'kein-blick-zurueck',
      name: 'Kein Blick zurück',
      area: AchievementArea.laden,
      kind: AchievementKind.discovery,
      tier: AchievementTier.entdeckung,
      requirement: 'Ein Ausrüstungsstück verkaufen',
      measure: _soldCount,
    ),
    // ---------------- Gebiete (ADR-0085) ----------------
    // Je Skill drei Titel, bei 10, 25 und 50. Sie sind der Grund, eine
    // lange Zeit in einem Gebiet sichtbar zu machen: Wer 100 Ketten zu
    // 25 Tagen hatte, trägt am Ende denselben Titel wie jemand mit einer
    // langen — und behält ihn, wenn eine Kette fällt.
    Achievement(
      id: 'ruestig',
      name: 'der Rüstige',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Körper auf Stufe 10',
      measure: _skillKoerper,
      skillAreaId: 'koerper',
      target: 10,
      titleId: 'ruestig',
    ),
    Achievement(
      id: 'gestaehlt',
      name: 'der Gestählte',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'Körper auf Stufe 25',
      measure: _skillKoerper,
      skillAreaId: 'koerper',
      target: 25,
      titleId: 'gestaehlt',
    ),
    Achievement(
      id: 'unverwuestlich',
      name: 'der Unverwüstliche',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Körper auf Stufe 50',
      measure: _skillKoerper,
      skillAreaId: 'koerper',
      target: 50,
      titleId: 'unverwuestlich',
    ),
    Achievement(
      id: 'wach',
      name: 'der Wache',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Geist auf Stufe 10',
      measure: _skillGeist,
      skillAreaId: 'geist',
      target: 10,
      titleId: 'wach',
    ),
    Achievement(
      id: 'gesammelt',
      name: 'der Gesammelte',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'Geist auf Stufe 25',
      measure: _skillGeist,
      skillAreaId: 'geist',
      target: 25,
      titleId: 'gesammelt',
    ),
    Achievement(
      id: 'weise',
      name: 'der Weise',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Geist auf Stufe 50',
      measure: _skillGeist,
      skillAreaId: 'geist',
      target: 50,
      titleId: 'weise',
    ),
    Achievement(
      id: 'neugierig',
      name: 'der Neugierige',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Wissenschaft auf Stufe 10',
      measure: _skillWissenschaft,
      skillAreaId: 'wissenschaft',
      target: 10,
      titleId: 'neugierig',
    ),
    Achievement(
      id: 'forscher',
      name: 'der Forscher',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'Wissenschaft auf Stufe 25',
      measure: _skillWissenschaft,
      skillAreaId: 'wissenschaft',
      target: 25,
      titleId: 'forscher',
    ),
    Achievement(
      id: 'gelehrt',
      name: 'der Gelehrte',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Wissenschaft auf Stufe 50',
      measure: _skillWissenschaft,
      skillAreaId: 'wissenschaft',
      target: 50,
      titleId: 'gelehrt',
    ),
    Achievement(
      id: 'zugewandt',
      name: 'der Zugewandte',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.klein,
      requirement: 'Gesellschaft auf Stufe 10',
      measure: _skillGesellschaft,
      skillAreaId: 'gesellschaft',
      target: 10,
      titleId: 'zugewandt',
    ),
    Achievement(
      id: 'vertraut',
      name: 'der Vertraute',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.mittel,
      requirement: 'Gesellschaft auf Stufe 25',
      measure: _skillGesellschaft,
      skillAreaId: 'gesellschaft',
      target: 25,
      titleId: 'vertraut',
    ),
    Achievement(
      id: 'ratgeber',
      name: 'der Ratgeber',
      area: AchievementArea.gebiete,
      kind: AchievementKind.milestone,
      tier: AchievementTier.gross,
      requirement: 'Gesellschaft auf Stufe 50',
      measure: _skillGesellschaft,
      skillAreaId: 'gesellschaft',
      target: 50,
      titleId: 'ratgeber',
    ),
  ];

  static Achievement? byId(String? id) {
    if (id == null) return null;
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  static List<Achievement> inArea(AchievementArea area) {
    return List<Achievement>.unmodifiable(all.where((a) => a.area == area));
  }

  /// Alle, die zu diesem Stand verdient sind.
  static List<Achievement> earnedBy(AchievementStats stats) {
    final verdient = all.where((a) => a.isEarnedBy(stats));
    return List<Achievement>.unmodifiable(verdient);
  }

  static Set<String> earnedIdsBy(AchievementStats stats) {
    return <String>{
      for (final a in all)
        if (a.isEarnedBy(stats)) a.id,
    };
  }

  /// Die Titel, die zu diesem Stand verdient sind.
  ///
  /// **Die einzige Stelle, an der ein Titel verdient wird** (ADR-0033,
  /// Punkt 6). Vorher stand die Bedingung in `package:identity`; jetzt
  /// steht sie hier, und dort nur noch der Wortlaut. Zwei Stellen, die
  /// dieselbe Frage beantworten, driften auseinander (`gotchas.md`).
  static Set<String> earnedTitleIdsBy(AchievementStats stats) {
    return <String>{
      for (final a in all)
        if (a.titleId != null && a.isEarnedBy(stats)) a.titleId!,
    };
  }

  /// Die Fähigkeiten, die zu diesem Stand verdient sind.
  static Set<String> earnedMoveIdsBy(AchievementStats stats) {
    return <String>{
      for (final a in all)
        if (a.moveId != null && a.isEarnedBy(stats)) a.moveId!,
    };
  }

  // --- Was zusammenkommt ---

  /// Erfahrung aus allen verdienten Errungenschaften.
  ///
  /// **Einmalig je Errungenschaft, wie bei einer Lektion und einer
  /// Sprosse der Reihe.** Weil nichts doppelt verdient werden kann und
  /// keine Bedingung wieder fällt, steht der Gesamtbetrag als Zahl fest —
  /// siehe [lifetimeXp].
  static int xpFor(AchievementStats stats) => _sum(stats, (a) => a.tier.xp);

  static int goldFor(AchievementStats stats) => _sum(stats, (a) => a.tier.gold);

  /// Der Ruhm-Stand. Vergleichszahl, kein Guthaben (ADR-0033, Punkt 5).
  static int fameFor(AchievementStats stats) => _sum(stats, (a) => a.tier.fame);

  static int _sum(AchievementStats stats, int Function(Achievement) je) {
    var sum = 0;
    for (final a in all) {
      if (a.isEarnedBy(stats)) sum += je(a);
    }
    return sum;
  }

  /// Alles, was der ganze Satz über ein Spielerleben hergibt.
  ///
  /// Gegenprobe zu den Zahlen in ADR-0033 und zugleich die Obergrenze,
  /// die `test/progression_test.dart` in die vier Kurven einrechnet.
  static int get lifetimeXp => _total((a) => a.tier.xp);

  static int get lifetimeGold => _total((a) => a.tier.gold);

  static int get lifetimeFame => _total((a) => a.tier.fame);

  static int _total(int Function(Achievement) je) {
    var sum = 0;
    for (final a in all) {
      sum += je(a);
    }
    return sum;
  }

  static int get milestoneCount => all.where((a) => a.isMilestone).length;

  static int get discoveryCount => all.where((a) => a.isDiscovery).length;
}
