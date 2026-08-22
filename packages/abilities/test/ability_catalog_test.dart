import 'package:abilities/abilities.dart';
import 'package:test/test.dart';

/// Prüft den Katalog und seine Bedingungen (ADR-0017).
///
/// Was hier **nicht** geprüft werden kann: ob die Move-Ids in
/// `package:combat` ankommen und ob die Waffen-Ids in `package:gear`
/// existieren. Dieses Package kennt beide nicht — das ist Absicht und der
/// Grund, warum `test/abilities_seam_test.dart` in der App dazugehört.
void main() {
  group('Der Waffenslot', () {
    test('ohne Waffe greift der Rückfall', () {
      // Slot 1 darf nie leer sein: Auf Level 1 ist er der einzige offene.
      expect(
        AbilityCatalog.weaponMoveFor(null),
        AbilityCatalog.fallbackMoveId,
      );
    });

    test('eine unbekannte Waffe fällt ebenfalls zurück', () {
      // Ein Spielstand mit einem Stück, das es nicht mehr gibt, darf den
      // Kampf nicht ohne Move dastehen lassen. Gleiche Nachsicht wie beim
      // Laden (ADR-0010).
      expect(
        AbilityCatalog.weaponMoveFor('gear-gibt-es-nicht'),
        AbilityCatalog.fallbackMoveId,
      );
    });

    test('jede bekannte Waffe bringt eine Fähigkeit mit', () {
      for (final entry in AbilityCatalog.weaponMoves.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
        expect(
          AbilityCatalog.weaponMoveFor(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('keine Waffenfähigkeit steht in der Auswahl', () {
      // Slot 1 wird nicht gewählt, sondern folgt aus der Ausrüstung
      // (ADR-0013). Stünde sie in beiden Listen, gäbe es zwei Wege zu
      // derselben Fähigkeit.
      final weaponMoveIds = AbilityCatalog.weaponMoves.values.toSet();
      for (final ability in AbilityCatalog.choosable) {
        expect(
          weaponMoveIds,
          isNot(contains(ability.moveId)),
          reason: ability.moveId,
        );
      }
    });
  });

  group('Der Katalog', () {
    test('jede Id kommt nur einmal vor', () {
      final ids = AbilityCatalog.choosable.map((a) => a.moveId).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('jede Fähigkeit nennt ihre Bedingung lesbar', () {
      for (final ability in AbilityCatalog.choosable) {
        expect(ability.requirement, isNotEmpty, reason: ability.moveId);
      }
    });

    test('jede wählbare Fähigkeit ist auch als wählbar markiert', () {
      for (final ability in AbilityCatalog.choosable) {
        expect(ability.isChoosable, isTrue, reason: ability.moveId);
      }
    });

    test('byMoveId findet, was es gibt, und sonst nichts', () {
      expect(AbilityCatalog.byMoveId('mend'), isNotNull);
      expect(AbilityCatalog.byMoveId('gibt-es-nicht'), isNull);
    });
  });

  group('Was wann offen ist', () {
    test('Grundfähigkeiten sind ohne Fortschritt da', () {
      // Sonst hätte ein frischer Charakter drei offene Slots und nichts,
      // was hineinpasst.
      final offen = AbilityCatalog.unlockedBy(const AbilityProgress.empty());

      expect(offen, isNotEmpty);
      for (final ability in offen) {
        expect(ability.source, isA<FromStart>(), reason: ability.moveId);
      }
    });

    test('eine Streak-Fähigkeit braucht ihre Marke', () {
      const ability = Ability(
        moveId: 'test',
        source: FromStreak(7),
        requirement: '7 Tage am Stück',
      );

      expect(
        ability.isUnlockedBy(const AbilityProgress(longestStreak: 6)),
        isFalse,
      );
      expect(
        ability.isUnlockedBy(const AbilityProgress(longestStreak: 7)),
        isTrue,
      );
    });

    test('eine Streak-Fähigkeit bleibt, wenn die Kette reisst', () {
      // Der Grund, warum die Bedingung an longestStreak hängt und nicht
      // an der laufenden: konzept.md 3.7 schliesst Strafe fürs Verpassen
      // aus, ADR-0008 deckelt den Multiplikator aus demselben Grund.
      const ability = Ability(
        moveId: 'test',
        source: FromStreak(30),
        requirement: '30 Tage am Stück',
      );

      // longestStreak sinkt nicht, wenn die laufende Kette reisst.
      expect(
        ability.isUnlockedBy(const AbilityProgress(longestStreak: 45)),
        isTrue,
      );
    });

    test('eine Theoriefähigkeit braucht den abgeschlossenen Zweig', () {
      const ability = Ability(
        moveId: 'test',
        source: FromTheory('koerper'),
        requirement: 'Körper abschliessen',
      );

      expect(
        ability.isUnlockedBy(const AbilityProgress.empty()),
        isFalse,
      );
      expect(
        ability.isUnlockedBy(
          const AbilityProgress(completedBranchIds: <String>{'koerper'}),
        ),
        isTrue,
      );
    });

    test('eine Waffenfähigkeit hängt an der angelegten Waffe', () {
      const ability = Ability(
        moveId: 'test',
        source: FromWeapon('gear-uebungsklinge'),
        requirement: 'Übungsklinge tragen',
      );

      expect(ability.isChoosable, isFalse);
      expect(
        ability.isUnlockedBy(
          const AbilityProgress(equippedWeaponId: 'gear-uebungsklinge'),
        ),
        isTrue,
      );
      expect(
        ability.isUnlockedBy(
          const AbilityProgress(equippedWeaponId: 'gear-geschliffene-klinge'),
        ),
        isFalse,
      );
    });

    test('mehr Fortschritt nimmt nie eine Fähigkeit weg', () {
      // Dieselbe Zusage wie bei den Titeln (ADR-0014) und den Slots
      // (ADR-0016): Fortschritt schrumpft nicht.
      var previous = 0;
      for (var streak = 0; streak <= 90; streak++) {
        final offen = AbilityCatalog.unlockedBy(
          AbilityProgress(
            longestStreak: streak,
            completedBranchIds: const <String>{'koerper', 'geist'},
          ),
        );

        expect(offen.length, greaterThanOrEqualTo(previous));
        previous = offen.length;
      }
    });

    test('isUnlocked weist zurück, was es nicht gibt', () {
      expect(
        AbilityCatalog.isUnlocked(
          'gibt-es-nicht',
          const AbilityProgress.empty(),
        ),
        isFalse,
      );
    });
  });
}
