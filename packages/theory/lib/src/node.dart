import 'lesson.dart';

/// Ein Knoten im Theoriegraph.
///
/// **Ein Knoten ist eine Seite mit drei Fragen**, kein Thema mit mehreren
/// Lektionen ([ADR-0019]). Das ist der Unterschied zu ADR-0012 und der
/// Grund, warum ein voller Startbaum zwanzig Seiten kostet und nicht
/// sechzig.
///
/// Name und Zusammenfassung stehen **nicht** hier, sondern an der Lektion.
/// Zwei Titel für dieselbe Sache laufen sonst auseinander, sobald einer
/// von beiden geändert wird.
class TheoryNode {
  const TheoryNode({
    required this.id,
    required this.lesson,
    required this.iconId,
    this.parentIds = const <String>[],
    this.cost = 1,
    this.unlocksAbility,
  });

  final String id;

  /// Die Seite selbst: Text und drei Fragen.
  final Lesson lesson;

  /// Welches Icon auf dem Knoten sitzt. Eine Id, kein Widget — das
  /// Package kennt Flutter nicht (ADR-0004).
  final String iconId;

  /// Die Knoten, von denen aus dieser erreichbar ist.
  ///
  /// Leer heißt Wurzel. **Zwei Eltern sind erlaubt**, damit ein Knoten
  /// zwei Themengebiete verbinden kann (ADR-0019). Damit ist die Struktur
  /// formal ein gerichteter Graph, kein Baum — und deshalb prüft
  /// `TheoryGraph.isAcyclic`, dass niemand einen Kreis einträgt.
  final List<String> parentIds;

  /// Was das Öffnen kostet, in Theoriepunkten.
  ///
  /// Immer 1, unabhängig von der Tiefe (ADR-0012, von ADR-0019
  /// übernommen). Ausnahme ist das Handbuch mit 0: Es erklärt das Spiel
  /// und darf nichts kosten (ADR-0005, ADR-0018).
  final int cost;

  /// Die Fähigkeit, die dieser Knoten mitbringt — oder null.
  ///
  /// Nur vier Knoten im Startbaum tragen eine (ADR-0019). Alle übrigen
  /// geben Erfahrung und Gold über `TheoryRewards`.
  final String? unlocksAbility;

  bool get isRoot => parentIds.isEmpty;

  bool get isFree => cost == 0;

  /// Der Name des Knotens — der Titel seiner Seite.
  String get name => lesson.title;

  /// Ein Satz für die Übersicht.
  String get summary => lesson.summary;
}
