import 'title.dart';

/// Alle Titel des Spiels an einem Ort — **nur ihr Wortlaut**.
///
/// Wer einen Titel verdient, steht seit ADR-0033 in
/// `package:achievements`; hier steht, wie er heißt. Die Trennung ist
/// keine Förmlichkeit: Ein Titel ist ein Wort, das jemand neben seinem
/// Namen trägt, und eine Errungenschaft ist eine Leistung. Dass die
/// meisten Errungenschaften genauso heißen wie ihr Titel, ist Absicht und
/// kein Grund, beides zusammenzulegen — vier Titel kommen aus
/// Entdeckungen, deren Bedingung niemand vorher lesen soll.
///
/// **Dreizehn Titel: die sieben aus ADR-0014 und sechs neue.** Die sechs
/// kommen aus Entdeckungen und sagen etwas über den Stil statt über die
/// Menge — sie sind der Platz, an dem das Persönlichkeitsprofil aus
/// Issue #41 gelandet ist (ADR-0033, Punkt 9).
abstract final class TitleCatalog {
  /// In der Reihenfolge, in der sie im Spiel erscheinen sollen: erst die
  /// Meilensteine nach Schwelle, dann die Entdeckungen.
  static const List<CharacterTitle> all = <CharacterTitle>[
    // --- aus Meilensteinen (ADR-0014) ---
    CharacterTitle(id: 'entschlossen', label: 'der Entschlossene'),
    CharacterTitle(id: 'verlaesslich', label: 'der Verlässliche'),
    CharacterTitle(id: 'bestaendig', label: 'der Beständige'),
    CharacterTitle(id: 'unermuedlich', label: 'der Unermüdliche'),
    CharacterTitle(id: 'unbeirrbar', label: 'der Unbeirrbare'),
    CharacterTitle(id: 'wissbegierig', label: 'der Wissbegierige'),
    CharacterTitle(id: 'belesen', label: 'der Belesene'),

    // --- aus Entdeckungen (ADR-0033) ---
    CharacterTitle(id: 'moench', label: 'der Mönch'),
    CharacterTitle(id: 'herausforderer', label: 'der Herausforderer'),
    CharacterTitle(id: 'stoiker', label: 'der Stoiker'),
    CharacterTitle(id: 'alchemist', label: 'der Alchemist'),
    CharacterTitle(id: 'unbeugsam', label: 'der Unbeugsame'),
    CharacterTitle(id: 'stratege', label: 'der Stratege'),
  ];

  static CharacterTitle? byId(String? id) {
    if (id == null) return null;
    for (final title in all) {
      if (title.id == id) return title;
    }
    return null;
  }

  /// Die Titel zu einer Menge verdienter Ids, in Katalogreihenfolge.
  ///
  /// Unbekannte Ids werden übersprungen — ein Katalog kann sich ändern,
  /// und ein Titel, den es nicht mehr gibt, darf nichts kosten
  /// (ADR-0010).
  static List<CharacterTitle> forIds(Set<String> earnedIds) {
    return List<CharacterTitle>.unmodifiable(
      all.where((title) => earnedIds.contains(title.id)),
    );
  }

  /// Ob dieser Titel getragen werden darf.
  static bool isEarned(String? id, Set<String> earnedIds) {
    return id != null && byId(id) != null && earnedIds.contains(id);
  }
}
