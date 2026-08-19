import 'title.dart';

/// Alle Titel des Spiels an einem Ort.
///
/// Gleiche Regel wie bei Preisen und Belohnungen: Steht eine dieser
/// Schwellen irgendwo anders im Code, ist das ein Bug.
///
/// **Drei Quellen, absichtlich.** Ein Titel nur für Streaks würde
/// belohnen, wer lange dabei ist; einer nur für Lektionen, wer viel liest.
/// Nebeneinander sagen sie etwas über den Stil — und genau das ist laut
/// ADR-0013 der Sinn: Wo eine Klasse sichtbar wird, wird sie aus dem
/// Verhalten abgeleitet, nie gewählt.
abstract final class TitleCatalog {
  /// In der Reihenfolge, in der sie im Spiel erscheinen sollen: je Quelle
  /// aufsteigend.
  static const List<CharacterTitle> all = <CharacterTitle>[
    CharacterTitle(
      id: 'entschlossen',
      label: 'der Entschlossene',
      requirement: '3 Tage am Stück',
      requiredStreak: 3,
    ),
    CharacterTitle(
      id: 'bestaendig',
      label: 'der Beständige',
      requirement: '30 Tage am Stück',
      requiredStreak: 30,
    ),
    CharacterTitle(
      id: 'unbeirrbar',
      label: 'der Unbeirrbare',
      requirement: '60 Tage am Stück',
      requiredStreak: 60,
    ),
    // ADR-0013 nennt für diesen Titel „der fünfte abgeschlossene Knoten".
    // Knoten gibt es noch nicht -- der Baum wird erst mit ADR-0012 zu
    // einem. Bis dahin zählen Lektionen. Beim Umbau wandert die Bedingung
    // mit, der Titel bleibt.
    CharacterTitle(
      id: 'wissbegierig',
      label: 'der Wissbegierige',
      requirement: '5 bestandene Lektionen',
      requiredLessons: 5,
    ),
    CharacterTitle(
      id: 'belesen',
      label: 'der Belesene',
      requirement: '12 bestandene Lektionen',
      requiredLessons: 12,
    ),
    CharacterTitle(
      id: 'verlaesslich',
      label: 'der Verlässliche',
      requirement: '50 Häkchen gesetzt',
      requiredChecks: 50,
    ),
    CharacterTitle(
      id: 'unermuedlich',
      label: 'der Unermüdliche',
      requirement: '200 Häkchen gesetzt',
      requiredChecks: 200,
    ),
  ];

  static CharacterTitle? byId(String? id) {
    if (id == null) return null;
    for (final title in all) {
      if (title.id == id) return title;
    }
    return null;
  }

  /// Alle Titel, die zu diesem Stand verdient sind.
  static List<CharacterTitle> earnedBy(TitleStats stats) {
    return List<CharacterTitle>.unmodifiable(
      all.where((title) => title.isEarnedBy(stats)),
    );
  }

  /// Ob dieser Titel getragen werden darf.
  static bool isEarned(String? id, TitleStats stats) {
    final title = byId(id);
    return title != null && title.isEarnedBy(stats);
  }
}
