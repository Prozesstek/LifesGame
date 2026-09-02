import 'package:abilities/abilities.dart';
import 'package:progression/progression.dart';

/// Welche Fähigkeiten zwischen zwei Ständen dazugekommen sind.
///
/// **Warum ein Vergleich und kein gespeichertes „schon gefeiert".**
/// Freischaltungen sind abgeleitet: Eine Fähigkeit ist offen, wenn ihre
/// Bedingung erfüllt ist — es gibt keinen Moment, den der Spielstand
/// festhält (ADR-0017). Ein Merkzettel „diese wurde schon gefeiert" wäre
/// eine zweite Wahrheit über etwas, das sich aus dem Fortschritt ergibt,
/// und müsste bei jedem neuen Katalogeintrag nachgezogen werden.
///
/// Stattdessen vergleicht die Oberfläche den Stand **vor** einer Handlung
/// mit dem danach. Der Preis ist ehrlich: Wer die App im selben Augenblick
/// abwürgt, verpasst die Feier. Der Fortschritt selbst geht nie verloren.
List<Ability> newlyUnlocked({
  required List<Ability> before,
  required List<Ability> after,
}) {
  final vorher = <String>{for (final ability in before) ability.moveId};

  return List<Ability>.unmodifiable(<Ability>[
    for (final ability in after)
      if (!vorher.contains(ability.moveId)) ability,
  ]);
}

/// Der erste freie Fähigkeitsplatz — oder null, wenn keiner offen ist.
///
/// [level] ist das Charakterlevel, [chosen] die Wahl auf den **freien**
/// Plätzen. Slot 1 gehört der Waffe und zählt hier nicht mit (ADR-0013);
/// deshalb steht `- 1` in der Rechnung und nicht irgendwo im Bildschirm.
///
/// [ChosenAbilities] lässt keine Lücken zu — `withAt` schiebt zusammen.
/// Der erste freie Platz ist damit schlicht das Ende der Liste.
int? firstFreeSlot({required ChosenAbilities chosen, required int level}) {
  final frei = AbilitySlots.openAt(level) - 1;
  if (chosen.length >= frei) return null;

  return chosen.length;
}

/// Die Stufe, die den nächsten Platz bringt — oder null, wenn alle offen
/// sind.
///
/// Steht hier neben [firstFreeSlot], weil beide dieselbe Frage von zwei
/// Seiten beantworten: Ist Platz? Und wenn nein, wann?
int? nextSlotLevel(int level) => AbilitySlots.nextUnlockAfter(level);
