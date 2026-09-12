import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// „Je besessen" statt „im Besitz" — die Zahlen, die
/// `package:achievements` aus dem Inventar liest (ADR-0033).
///
/// Der ganze Abschnitt hängt an ADR-0031: Weil ein Verkauf als
/// **Historie** festgehalten wird und nicht als Abzug, lässt sich
/// überhaupt noch beantworten, was jemand einmal hatte.
void main() {
  /// Ein Stück je Platz, das billigste zuerst.
  GearItem ersterAuf(GearSlot slot) {
    return GearCatalog.all.firstWhere((i) => i.slot == slot);
  }

  /// Kauft, ohne auf Gold zu achten — hier geht es um den Besitz, nicht
  /// um die Ökonomie.
  Loadout mitBesitz(List<String> ids) {
    var loadout = const Loadout.empty();
    for (final id in ids) {
      loadout = loadout.buy(id, availableGold: 1 << 30);
    }
    return loadout;
  }

  group('Je besessen', () {
    test('ein leeres Inventar hat nichts', () {
      const leer = Loadout.empty();
      expect(leer.everOwnedIds, isEmpty);
      expect(leer.everOwnedCount, 0);
      expect(leer.slotsEverOwned, 0);
      expect(leer.completeSetsEverOwned, 0);
      expect(leer.soldCount, 0);
    });

    test('gekauft heißt besessen', () {
      final item = ersterAuf(GearSlot.helm);
      final loadout = mitBesitz(<String>[item.id]);

      expect(loadout.everOwnedCount, 1);
      expect(loadout.slotsEverOwned, 1);
    });

    // Der Kern: Ein Verkauf darf keine Errungenschaft zurücknehmen.
    test('verkauft bleibt besessen', () {
      final item = ersterAuf(GearSlot.helm);
      var loadout = mitBesitz(<String>[item.id]);
      loadout = loadout.sell(item.id);

      expect(loadout.isOwned(item.id), isFalse);
      expect(loadout.owned, isEmpty);
      expect(loadout.everOwnedCount, 1);
      expect(loadout.slotsEverOwned, 1);
      expect(loadout.soldCount, 1);
    });

    test('zweimal kaufen und verkaufen zählt einmal als Besitz', () {
      final item = ersterAuf(GearSlot.ring);
      var loadout = mitBesitz(<String>[item.id]);
      loadout = loadout.sell(item.id);
      loadout = loadout.buy(item.id, availableGold: 1 << 30);
      loadout = loadout.sell(item.id);

      expect(loadout.everOwnedCount, 1);
      // Der Verkauf selbst zählt jedes Mal — zweimal draufgezahlt.
      expect(loadout.soldCount, 2);
    });

    test('sechs Plätze ergeben Voll ausgerüstet', () {
      final loadout = mitBesitz(<String>[
        for (final slot in GearSlot.values) ersterAuf(slot).id,
      ]);

      expect(loadout.slotsEverOwned, 6);
      expect(loadout.everOwnedCount, 6);
    });

    test('zwei Stücke auf demselben Platz sind ein Platz', () {
      final aufHelm =
          GearCatalog.all.where((i) => i.slot == GearSlot.helm).take(2);
      final loadout = mitBesitz(<String>[for (final i in aufHelm) i.id]);

      expect(loadout.everOwnedCount, 2);
      expect(loadout.slotsEverOwned, 1);
    });

    test('fünfzehn Stücke ergeben den Sammler', () {
      final loadout = mitBesitz(<String>[
        for (final item in GearCatalog.all.take(15)) item.id,
      ]);

      expect(loadout.everOwnedCount, 15);
    });
  });

  group('Der Stratege', () {
    /// Alle Stücke eines Sets.
    List<GearItem> teileVon(String setId) {
      return GearCatalog.all.where((i) => i.setId == setId).toList();
    }

    test('drei von vier Teilen reichen nicht', () {
      final teile = teileVon(GearSets.all.first.id);
      expect(teile, hasLength(4));

      final loadout = mitBesitz(<String>[
        for (final item in teile.take(3)) item.id,
      ]);

      expect(loadout.completeSetsEverOwned, 0);
    });

    test('vier von vier Teilen zählen', () {
      final teile = teileVon(GearSets.all.first.id);
      final loadout = mitBesitz(<String>[for (final item in teile) item.id]);

      expect(loadout.completeSetsEverOwned, 1);
    });

    // Nicht dasselbe wie `activeSets`: Dort geht es darum, was jetzt
    // wirkt. Hier darum, was jemand einmal beisammen hatte.
    test('getragen werden müssen sie nicht', () {
      final teile = teileVon(GearSets.all.first.id);
      var loadout = mitBesitz(<String>[for (final item in teile) item.id]);

      // Kaufen legt an — abgelegt wird das Set wirkungslos, besessen
      // bleibt es trotzdem.
      for (final slot in GearSlot.values) {
        loadout = loadout.unequip(slot);
      }

      expect(loadout.equippedCount, 0);
      expect(loadout.activeSets, isEmpty);
      expect(loadout.completeSetsEverOwned, 1);
    });

    test('ein verkauftes Teil nimmt das Set nicht zurück', () {
      final teile = teileVon(GearSets.all.first.id);
      var loadout = mitBesitz(<String>[for (final item in teile) item.id]);
      loadout = loadout.sell(teile.first.id);

      expect(loadout.completeSetsEverOwned, 1);
    });

    test('zwei volle Sets zählen doppelt', () {
      final ids = <String>[
        for (final set in GearSets.all.take(2))
          for (final item in teileVon(set.id)) item.id,
      ];
      final loadout = mitBesitz(ids);

      expect(loadout.completeSetsEverOwned, 2);
    });
  });

  group('Nach dem Laden', () {
    test('die Historie überlebt Speichern und Laden', () {
      final teile =
          GearCatalog.all.where((i) => i.setId == GearSets.all.first.id);
      var loadout = mitBesitz(<String>[for (final item in teile) item.id]);
      loadout = loadout.sell(teile.first.id);

      final geladen = Loadout.fromJson(loadout.toJson());

      expect(geladen.everOwnedCount, loadout.everOwnedCount);
      expect(geladen.completeSetsEverOwned, 1);
      expect(geladen.soldCount, 1);
    });
  });
}
