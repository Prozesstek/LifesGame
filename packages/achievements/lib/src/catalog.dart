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

/// Alle Errungenschaften des Spiels an einem Ort.
///
/// **19 Meilensteine und 8 Entdeckungen** — der erste Satz aus ADR-0033.
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
