import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// Prüft den **Inhalt** des Shops, nicht den Code drumherum — dieselbe
/// Rolle wie `content_test.dart` in `package:theory`. Ein neues
/// Ausrüstungsstück wird automatisch mitgeprüft.
void main() {
  group('Katalog', () {
    test('Ids sind eindeutig', () {
      final ids = GearCatalog.all.map((item) => item.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('Namen sind eindeutig', () {
      final names = GearCatalog.all.map((item) => item.name).toList();

      expect(names.toSet(), hasLength(names.length));
    });

    test('jede Id folgt derselben Form', () {
      for (final item in GearCatalog.all) {
        expect(item.id, startsWith('gear-'), reason: item.name);
      }
    });

    test('jedes Stück kostet etwas und wirkt', () {
      for (final item in GearCatalog.all) {
        expect(item.price, greaterThan(0), reason: item.name);
        expect(
          item.bonus.isEmpty,
          isFalse,
          reason: '${item.name} kostet Gold, ändert aber nichts',
        );
      }
    });

    test('jedes Stück begründet sich', () {
      for (final item in GearCatalog.all) {
        expect(
          item.why.length,
          greaterThan(40),
          reason: '${item.name} hat keine brauchbare Begründung',
        );
      }
    });

    test('jeder Platz hat mindestens ein Stück', () {
      // Ein leerer Platz im Charakterbildschirm sieht wie ein Fehler aus.
      for (final slot in GearSlot.values) {
        expect(
          GearCatalog.forSlot(slot),
          isNotEmpty,
          reason: 'Platz ${slot.label} hat nichts zu bieten',
        );
      }
    });

    test('teurer heißt auf demselben Platz auch besser', () {
      // Sonst ist eine Kaufentscheidung eine Falle.
      for (final slot in GearSlot.values) {
        final items = GearCatalog.forSlot(slot);
        for (var i = 1; i < items.length; i++) {
          final billiger = items[i - 1].bonus;
          final teurer = items[i].bonus;
          final summeBilliger = billiger.attack +
              billiger.maxHp +
              billiger.defense * 8 +
              billiger.maxEnergy * 8;
          final summeTeurer = teurer.attack +
              teurer.maxHp +
              teurer.defense * 8 +
              teurer.maxEnergy * 8;
          expect(
            summeTeurer,
            greaterThan(summeBilliger),
            reason: '${items[i].name} kostet mehr als ${items[i - 1].name}, '
                'bringt aber nicht mehr',
          );
        }
      }
    });
  });

  group('Preise gegen den Gold-Zufluss', () {
    // Fünf Gewohnheiten bringen 25 Gold am Tag. Die Zahl steht in
    // `package:habits`, das dieses Package nicht kennt — deshalb hier als
    // ausdrückliche Annahme, nicht als Import.
    const int goldProTag = 25;

    test('ein voller Satz Stufe 1 ist in etwa einer Woche tragbar', () {
      final tage = GearCatalog.cheapestFullSetPrice / goldProTag;

      expect(tage, greaterThan(24), reason: 'zu billig, keine Entscheidung');
      expect(tage, lessThan(45), reason: 'zu teuer, der Shop bleibt Deko');
    });

    test('das teuerste Einzelstück ist in etwa einem Monat tragbar', () {
      final teuerstes = GearCatalog.all
          .map((item) => item.price)
          .reduce((a, b) => a > b ? a : b);
      final tage = teuerstes / goldProTag;

      expect(tage, greaterThan(20));
      expect(tage, lessThan(45));
    });

    test('die zweite Stufe kostet deutlich mehr als die erste', () {
      for (final slot in GearSlot.values) {
        final items = GearCatalog.forSlot(slot);
        if (items.length < 2) continue;
        expect(
          items[1].price,
          greaterThan(items[0].price * 3),
          reason: 'Auf ${slot.label} liegen die Stufen zu dicht beieinander — '
              'dann ist die erste Stufe überflüssig',
        );
      }
    });
  });
}
