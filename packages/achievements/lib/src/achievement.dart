import 'rewards.dart';
import 'stats.dart';

/// Der Spielbereich, in dem eine Errungenschaft zu Hause ist.
///
/// **Sortiert wird nach Bereichen und nicht nach Eigenschaften**
/// (ADR-0033, Punkt 8). Jede Errungenschaft kommt aus genau einem
/// Bereich, die Zuordnung ist damit nie strittig, und die vier Reiter
/// entsprechen den Kreisen des Startbildschirms. Die fünf Kategorien aus
/// Issue #41 (Geist, Körper, Disziplin, Soziales, Abenteuer) erzählen
/// mehr über die Person — diese Aufgabe übernehmen jetzt die Titel der
/// Entdeckungen.
enum AchievementArea {
  gewohnheiten('Gewohnheiten'),
  theorie('Theorie'),
  kampf('Kampf'),
  laden('Laden');

  const AchievementArea(this.label);

  final String label;
}

/// Ob eine Errungenschaft vorher sichtbar ist.
enum AchievementKind {
  /// Sichtbar, mit Fortschritt („37 / 50").
  ///
  /// **Ein Meilenstein ohne sichtbaren Abstand wäre nur eine Absage** —
  /// der Laden und die Titel zeigen deshalb „noch 12 Tage".
  milestone,

  /// Steht bis zum Verdienen als ??? in ihrer Kategorie.
  ///
  /// **Eine Entdeckung verliert alles, wenn man sie vorher lesen kann.**
  /// Der ???-Platz zeigt trotzdem, dass es etwas zu finden gibt.
  discovery,
}

/// Eine Errungenschaft: Bedingung, Stufe und was sie mitbringt.
///
/// **Die Bedingung ist eine Messung, kein Schalter.** Jede Errungenschaft
/// nennt eine Zahl aus [AchievementStats] und einen Zielwert; verdient
/// ist sie ab [target]. Das hat zwei Gründe: Der Fortschritt („37 / 50")
/// fällt dabei von selbst ab, und eine Bedingung, die nur `true` oder
/// `false` kennt, könnte einen Meilenstein nicht anzeigen, ohne die Regel
/// ein zweites Mal zu formulieren.
///
/// Entdeckungen messen ebenfalls — sie stehen nur auf [target] 1 und
/// zeigen ihren Fortschritt nicht.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.area,
    required this.kind,
    required this.tier,
    required this.requirement,
    required this.measure,
    this.target = 1,
    this.titleId,
    this.moveId,
  });

  /// Stabiler Bezeichner. Steht in keinem Spielstand — was verdient ist,
  /// wird gerechnet (ADR-0033, Punkt 2) — aber Fähigkeiten hängen daran
  /// (`FromAchievement`), und Tests nennen ihn.
  final String id;

  /// Der Wortlaut, wie ihn der Spieler sieht — „der Beständige".
  final String name;

  final AchievementArea area;
  final AchievementKind kind;
  final AchievementTier tier;

  /// Die Bedingung im Klartext.
  ///
  /// Steht als Text daneben statt aus der Messung erzeugt zu werden: Der
  /// Laden, der Titelkatalog und der Fähigkeitskatalog machen es genauso,
  /// und eine Bedingung muss lesbar sein, nicht nur korrekt.
  final String requirement;

  /// Woran gemessen wird. Eine Zahl aus dem Stand, mehr nicht.
  final int Function(AchievementStats) measure;

  /// Ab wann sie verdient ist.
  final int target;

  /// Der Titel, den sie mitbringt — oder null.
  ///
  /// Naht zu `package:identity`. Kein Wortlaut, nur die Id: Was der Titel
  /// heißt, steht dort (ADR-0033, Punkt 6).
  final String? titleId;

  /// Die Fähigkeit, die sie mitbringt — oder null.
  ///
  /// Naht zu `package:combat` über `package:abilities`. Vier
  /// Meilensteine tragen eine, einer je Bereich (ADR-0033, Punkt 7).
  final String? moveId;

  bool get isMilestone => kind == AchievementKind.milestone;

  bool get isDiscovery => kind == AchievementKind.discovery;

  /// Wie weit der Spieler ist — nie über [target] hinaus, damit „31 / 30"
  /// gar nicht erst entstehen kann.
  int progressIn(AchievementStats stats) {
    final value = measure(stats);
    if (value < 0) return 0;
    return value > target ? target : value;
  }

  bool isEarnedBy(AchievementStats stats) => measure(stats) >= target;

  /// Wie viel noch fehlt — 0, wenn sie verdient ist.
  int missingFor(AchievementStats stats) => target - progressIn(stats);
}
