import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/pit_text.dart';
import 'package:lifes_game/character/faehigkeit_ordnung.dart';
import 'package:lifes_game/gear/gear_grouping.dart';

/// Wie die eigenen Fähigkeiten geordnet stehen (Frederik, 20.10.): wie
/// die Ausrüstung, nur ohne Überschriften.
void main() {
  final alle = AbilityCatalog.choosable;
  String name(Ability a) => pitNameOf(a.moveId) ?? a.moveId;

  test('keine Ordnung verliert eine oder zählt eine doppelt', () {
    for (final o in FaehigkeitOrdnung.values) {
      final geordnet = ordneFaehigkeiten(alle, o);
      expect(geordnet, hasLength(alle.length), reason: o.name);
      expect(geordnet.toSet(), alle.toSet(), reason: o.name);
    }
  });

  test('nach Seltenheit: Gewöhnliches zuerst, darin nach Namen', () {
    final geordnet = ordneFaehigkeiten(alle, FaehigkeitOrdnung.seltenheit);

    for (var i = 1; i < geordnet.length; i++) {
      final a = geordnet[i - 1];
      final b = geordnet[i];
      expect(a.rarity.index, lessThanOrEqualTo(b.rarity.index));
      if (a.rarity == b.rarity) {
        expect(sortKey(name(a)).compareTo(sortKey(name(b))), lessThan(1));
      }
    }
  });

  test('A bis Z nach deutschem Alphabet', () {
    final namen = ordneFaehigkeiten(
      alle,
      FaehigkeitOrdnung.alphabetisch,
    ).map(name).toList();
    final sortiert = [...namen]
      ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));

    expect(namen, sortiert);
  });

  test('nach Art: Angriff, Umgebung, Schutz', () {
    final arten = ordneFaehigkeiten(
      alle,
      FaehigkeitOrdnung.art,
    ).map((a) => PitAbilities.byId(a.moveId)!.kind.index).toList();
    final sortiert = [...arten]..sort();

    expect(arten, sortiert);
  });
}
