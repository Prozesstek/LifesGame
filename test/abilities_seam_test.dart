import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:progression/progression.dart';

/// Die Nähte zwischen `package:abilities`, `package:combat` und
/// `package:gear`.
///
/// Alle drei kennen einander nicht — sie treffen sich nur über Ids.
/// Genau deshalb muss die Naht hier geprüft werden: Kein Package allein
/// kann es, und ein Tippfehler würde sonst erst dem Spieler auffallen, in
/// Form einer Fähigkeit, die nichts tut, oder eines Kampfes ohne Knöpfe.
///
/// Gleiche Bauform wie `test/habits_theory_test.dart` für die Naht
/// `Lesson.unlocksHabit` ↔ `HabitTemplate.name`.
void main() {
  group('Jede Fähigkeit findet ihren Move', () {
    test('jede wählbare Fähigkeit zeigt auf einen echten Move', () {
      for (final ability in AbilityCatalog.choosable) {
        expect(
          Moves.byId(ability.moveId),
          isNotNull,
          reason:
              'Fähigkeit "${ability.moveId}" steht im Katalog, aber '
              '`package:combat` kennt diesen Move nicht.',
        );
      }
    });

    test('jede Waffenfähigkeit zeigt auf einen echten Move', () {
      for (final entry in AbilityCatalog.weaponMoves.entries) {
        expect(
          Moves.byId(entry.value),
          isNotNull,
          reason:
              'Waffe "${entry.key}" bringt "${entry.value}" mit, aber '
              '`package:combat` kennt diesen Move nicht.',
        );
      }
    });

    test('der Rückfall zeigt auf einen echten Move', () {
      // Der wichtigste Fall: Ohne ihn stünde ein frischer Charakter im
      // Kampf ohne einen einzigen Knopf.
      expect(Moves.byId(AbilityCatalog.fallbackMoveId), isNotNull);
    });
  });

  group('Jede Waffe gibt es wirklich', () {
    test('jede Waffen-Id steht im Ausrüstungskatalog', () {
      for (final weaponId in AbilityCatalog.weaponMoves.keys) {
        final item = GearCatalog.all.where((i) => i.id == weaponId);

        expect(
          item,
          isNotEmpty,
          reason:
              'Der Fähigkeitskatalog kennt die Waffe "$weaponId", der '
              'Laden nicht.',
        );
        expect(item.first.slot, GearSlot.waffe, reason: weaponId);
      }
    });

    test('jede Waffe im Laden bringt eine Fähigkeit mit', () {
      // Sonst gäbe es eine Waffe, die den Waffenslot leer lässt — und der
      // ist laut ADR-0017 der Motor des ganzen Builds.
      final waffen = GearCatalog.all.where((i) => i.slot == GearSlot.waffe);

      for (final waffe in waffen) {
        expect(
          AbilityCatalog.weaponMoves.containsKey(waffe.id),
          isTrue,
          reason:
              'Die Waffe "${waffe.id}" liegt im Laden, bringt aber keine '
              'Fähigkeit mit.',
        );
      }
    });
  });

  group('Der Waffenslot trägt auf Level 1 allein', () {
    test('jeder Waffenmove erzeugt Energie, keiner kostet welche', () {
      // Die Regel, an der ADR-0017 hängt. Steht auch in
      // `packages/combat/test/combat_flow_test.dart` — dort für die
      // Move-Liste, hier für das, was tatsächlich an Waffen hängt.
      for (final moveId in <String>[
        AbilityCatalog.fallbackMoveId,
        ...AbilityCatalog.weaponMoves.values,
      ]) {
        final move = Moves.byId(moveId);

        expect(move, isNotNull, reason: moveId);
        expect(move!.energyCost, 0, reason: moveId);
        expect(move.energyDelta, greaterThan(0), reason: moveId);
      }
    });
  });

  group('Der Katalog passt zu den Slots', () {
    test('es gibt genug Fähigkeiten für die freien Plätze', () {
      // Drei freie Plätze auf Level 10 (ADR-0016). Weniger wählbare
      // Fähigkeiten als Plätze hiesse, dass ein Platz nie belegbar wäre.
      final freiePlaetze = AbilitySlots.total - 1;

      expect(
        AbilityCatalog.choosable.length,
        greaterThanOrEqualTo(freiePlaetze),
        reason:
            'Auf Level ${AbilitySlots.levelForSlot(AbilitySlots.total)} gibt '
            'es $freiePlaetze freie Plätze, aber nur '
            '${AbilityCatalog.choosable.length} wählbare Fähigkeiten.',
      );
    });

    test('ein frischer Charakter kann jeden Platz belegen, den er hat', () {
      // Auf Level 1 gibt es keinen freien Platz — und ab Level 3 muss
      // etwas da sein, das hineinpasst, sonst öffnet sich ein leeres
      // Versprechen.
      final offenOhneFortschritt = AbilityCatalog.unlockedBy(
        const AbilityProgress.empty(),
      );

      expect(
        offenOhneFortschritt.length,
        greaterThanOrEqualTo(AbilitySlots.total - 1),
        reason:
            'Ab Level ${AbilitySlots.levelForSlot(AbilitySlots.total)} sind '
            '${AbilitySlots.total - 1} Plätze offen, aber nur '
            '${offenOhneFortschritt.length} Fähigkeiten ohne Fortschritt '
            'verfügbar.',
      );
    });
  });
}
