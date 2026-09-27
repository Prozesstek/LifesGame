/// Eine angekündigte Überschrift im Wissensbaum — noch ohne Seite.
///
/// **Warum es das gibt** ([ADR-0050]). Der Baum soll zeigen, wie groß er
/// wird, bevor sein Inhalt geschrieben ist: Physik, Geschichte,
/// Philosophie stehen im Bild, grau und mit „Inhalt folgt". Öffnen lässt
/// sich eine Ankündigung nicht — niemand zahlt einen Punkt für etwas
/// Leeres (ADR-0012: „ein Knoten erscheint erst, wenn seine Seite steht").
///
/// **Kein [TheoryNode] ohne Lektion.** Eine Seite, die fehlen darf, hätte
/// jede Stelle angefasst, die Seiten zählt, belohnt oder abfragt — die
/// Rückfrage des Tages, die Errungenschaften, die Punkte. Eine eigene Art
/// bleibt an genau einer Stelle: dem Bild.
///
/// Wird die Überschrift befüllt, wird sie ein [TheoryNode] **mit derselben
/// Id** und verschwindet hier. Dass keine Id an beiden Stellen steht,
/// prüft `TheoryGraph.duplicateIds`.
class TheoryPlaceholder {
  const TheoryPlaceholder({
    required this.id,
    required this.title,
    required this.iconId,
    required this.parentIds,
  });

  final String id;

  /// Die Überschrift, wie sie im Baum steht.
  final String title;

  /// Welches Symbol sie trägt. Eine Id, kein Widget (ADR-0004).
  final String iconId;

  /// Wo sie hängt. Nie leer: Eine Ankündigung ist nie eine Wurzel.
  final List<String> parentIds;
}
