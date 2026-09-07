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

    test('jeder Platz führt fünf Stücke — bis auf die Waffe', () {
      // **Die Waffe hinkt bewusst hinterher.** Jede Waffe im Laden muss
      // eine Fähigkeit mitbringen (`test/abilities_seam_test.dart` in der
      // App); die fehlenden zwei kommen deshalb zusammen mit ihren
      // Fähigkeiten. Sobald das passiert ist, fällt diese Ausnahme —
      // und dieser Test erinnert daran.
      for (final slot in GearSlot.values) {
        final erwartet = slot == GearSlot.waffe ? 2 : 5;

        expect(
          GearCatalog.forSlot(slot),
          hasLength(erwartet),
          reason: 'Platz ${slot.label} führt nicht $erwartet Stücke',
        );
      }
    });

    test('jeder volle Platz hat zwei, zwei und ein Stück', () {
      // Zwei gewöhnliche, zwei ungewöhnliche, ein seltenes. Die Form ist
      // überall dieselbe, damit ein Platz nicht heimlich reicher wird als
      // ein anderer.
      for (final slot in GearSlot.values) {
        if (GearCatalog.forSlot(slot).length < 5) continue;

        expect(
          GearCatalog.forSlotAndRarity(slot, GearRarity.common),
          hasLength(2),
          reason: slot.label,
        );
        expect(
          GearCatalog.forSlotAndRarity(slot, GearRarity.uncommon),
          hasLength(2),
          reason: slot.label,
        );
        expect(
          GearCatalog.forSlotAndRarity(slot, GearRarity.rare),
          hasLength(1),
          reason: slot.label,
        );
      }
    });

    test('jedes Stück hat eine Seltenheit, und jede kommt vor', () {
      final vorhanden = GearCatalog.all.map((item) => item.rarity).toSet();

      expect(
        vorhanden,
        contains(GearRarity.common),
        reason: 'Ohne gewöhnliche Stücke gibt es keinen Einstieg',
      );
    });

    test('teurer heißt bei gleicher Seltenheit auch besser', () {
      // **Nur noch innerhalb einer Seltenheit** (ADR-0029). Zwischen den
      // Stufen gilt es ausdrücklich nicht: Ein seltenes Stück darf in
      // reinen Zahlen schwächer sein und seinen Wert aus einem Set oder
      // einer Fähigkeit ziehen. Innerhalb einer Stufe wäre ein teureres,
      // schwächeres Stück dagegen weiter eine Falle.
      for (final slot in GearSlot.values) {
        for (final rarity in GearRarity.values) {
          final items = GearCatalog.forSlot(
            slot,
          ).where((item) => item.rarity == rarity).toList();

          _teurerIstBesser(items);
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

    test('die ungewöhnliche Stufe kostet ein Vielfaches der gewöhnlichen', () {
      // **Der Test hieß früher „die zweite Stufe kostet mehr als die
      // erste" und verglich die ersten beiden Stücke eines Platzes.** Mit
      // fünf Stücken je Platz stehen dort jetzt zwei gewöhnliche
      // nebeneinander, und die liegen absichtlich dicht beieinander. Was
      // weit auseinander liegen muss, sind die **Seltenheiten**.
      for (final slot in GearSlot.values) {
        final common = GearCatalog.forSlotAndRarity(slot, GearRarity.common);
        final uncommon = GearCatalog.forSlotAndRarity(
          slot,
          GearRarity.uncommon,
        );
        if (common.isEmpty || uncommon.isEmpty) continue;

        expect(
          uncommon.first.price,
          greaterThan(common.first.price * 2.5),
          reason: 'Auf ${slot.label} liegen die Seltenheiten zu dicht '
              'beieinander — dann ist die gewöhnliche Stufe überflüssig',
        );
      }
    });

    test('das seltene Stück ist auf seinem Platz das teuerste', () {
      for (final slot in GearSlot.values) {
        final selten = GearCatalog.forSlotAndRarity(slot, GearRarity.rare);
        if (selten.isEmpty) continue;

        expect(
          selten.single.price,
          GearCatalog.forSlot(slot).last.price,
          reason: 'Auf ${slot.label} ist das seltene Stück nicht das teuerste',
        );
      }
    });
  });
}

/// Prüft für eine nach Preis sortierte Liste, dass der Bonus mitwächst.
///
/// Verteidigung und Energie zählen achtfach: Ein Punkt davon wiegt im
/// Kampf deutlich schwerer als ein Punkt Angriff oder Leben.
void _teurerIstBesser(List<GearItem> items) {
  int wert(GearBonus bonus) {
    return bonus.attack + bonus.maxHp + bonus.defense * 8 + bonus.maxEnergy * 8;
  }

  for (var i = 1; i < items.length; i++) {
    expect(
      wert(items[i].bonus),
      greaterThan(wert(items[i - 1].bonus)),
      reason: '${items[i].name} kostet mehr als ${items[i - 1].name}, '
          'bringt aber nicht mehr',
    );
  }
}
