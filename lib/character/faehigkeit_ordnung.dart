import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';

import '../action/pit_text.dart';
import '../gear/gear_grouping.dart';

/// Wie die eigenen Fähigkeiten im Raster stehen — wie die Ordnungen der
/// Ausrüstung, aber **ohne Überschriften** (Frederik, 20.10.): ein Raster,
/// nur die Reihenfolge ändert sich.
enum FaehigkeitOrdnung {
  seltenheit('Nach Seltenheit'),
  alphabetisch('A bis Z'),
  art('Nach Art');

  const FaehigkeitOrdnung(this.label);

  final String label;
}

/// Ordnet [faehigkeiten] nach [ordnung] — reine Rechnung.
///
/// Bei gleicher Seltenheit oder Art entscheidet der Name, nach deutschem
/// Alphabet (`sortKey`, wie bei der Ausrüstung).
List<Ability> ordneFaehigkeiten(
  Iterable<Ability> faehigkeiten,
  FaehigkeitOrdnung ordnung,
) {
  String name(Ability a) => sortKey(pitNameOf(a.moveId) ?? a.moveId);
  int art(Ability a) => PitAbilities.byId(a.moveId)?.kind.index ?? 0;

  int vergleich(Ability a, Ability b) {
    final erst = switch (ordnung) {
      FaehigkeitOrdnung.seltenheit => a.rarity.index.compareTo(b.rarity.index),
      FaehigkeitOrdnung.art =>
        art(a) != art(b)
            ? art(a).compareTo(art(b))
            : a.rarity.index.compareTo(b.rarity.index),
      FaehigkeitOrdnung.alphabetisch => 0,
    };
    return erst != 0 ? erst : name(a).compareTo(name(b));
  }

  return List<Ability>.unmodifiable(faehigkeiten.toList()..sort(vergleich));
}
