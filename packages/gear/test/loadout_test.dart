import 'package:gear/gear.dart';
import 'package:test/test.dart';

void main() {
  const klinge = 'gear-uebungsklinge';
  const grosseKlinge = 'gear-geschliffene-klinge';
  const helm = 'gear-lederkappe';

  group('Kaufen', () {
    test('ein leeres Inventar hat nichts und hat nichts ausgegeben', () {
      const loadout = Loadout.empty();

      expect(loadout.owned, isEmpty);
      expect(loadout.spentGold, 0);
      expect(loadout.bonus.isEmpty, isTrue);
      expect(loadout.equippedCount, 0);
    });

    test('ein Kauf kostet genau den Preis', () {
      final item = GearCatalog.byId(klinge);
      final loadout = const Loadout.empty().buy(klinge, availableGold: 1000);

      expect(loadout.isOwned(klinge), isTrue);
      expect(loadout.spentGold, item?.price);
    });

    test('gekauft wird gleich angelegt', () {
      final loadout = const Loadout.empty().buy(klinge, availableGold: 1000);

      expect(loadout.isEquipped(klinge), isTrue);
      expect(loadout.equippedIn(GearSlot.waffe)?.id, klinge);
    });

    test('zu wenig Gold nennt den Grund und ändert nichts', () {
      const loadout = Loadout.empty();

      expect(
        loadout.blockFor(grosseKlinge, availableGold: 10),
        PurchaseBlock.zuWenigGold,
      );
      expect(loadout.buy(grosseKlinge, availableGold: 10), same(loadout));
    });

    test('zweimal dasselbe geht nicht', () {
      final loadout = const Loadout.empty().buy(klinge, availableGold: 1000);

      expect(
        loadout.blockFor(klinge, availableGold: 1000),
        PurchaseBlock.bereitsGekauft,
      );
      final nochmal = loadout.buy(klinge, availableGold: 1000);
      expect(nochmal.spentGold, loadout.spentGold);
    });

    test('ein unbekanntes Stück nennt sich unbekannt', () {
      const loadout = Loadout.empty();

      expect(
        loadout.blockFor('gibt-es-nicht', availableGold: 99999),
        PurchaseBlock.unbekannt,
      );
    });

    test('genau der Preis reicht', () {
      final item = GearCatalog.byId(klinge);
      final preis = item?.price ?? 0;

      expect(
        const Loadout.empty().canBuy(klinge, availableGold: preis),
        isTrue,
      );
      expect(
        const Loadout.empty().canBuy(klinge, availableGold: preis - 1),
        isFalse,
      );
    });
  });

  group('Tragen', () {
    test('nur Getragenes wirkt, Besitz allein nicht', () {
      final loadout = const Loadout.empty()
          .buy(klinge, availableGold: 5000)
          .unequip(GearSlot.waffe);

      expect(loadout.isOwned(klinge), isTrue);
      expect(loadout.bonus.isEmpty, isTrue);
    });

    test('ein zweites Stück auf demselben Platz verdrängt das erste', () {
      final loadout = const Loadout.empty()
          .buy(klinge, availableGold: 5000)
          .buy(grosseKlinge, availableGold: 5000);

      expect(loadout.equippedIn(GearSlot.waffe)?.id, grosseKlinge);
      expect(loadout.isEquipped(klinge), isFalse);
      // Besitz bleibt: Umrüsten kostet nichts, nur der Kauf hat gekostet.
      expect(loadout.isOwned(klinge), isTrue);
      expect(loadout.equippedCount, 1);
    });

    test('zurückrüsten auf das alte Stück geht ohne Kosten', () {
      final loadout = const Loadout.empty()
          .buy(klinge, availableGold: 5000)
          .buy(grosseKlinge, availableGold: 5000);
      final vorher = loadout.spentGold;

      final zurueck = loadout.equip(klinge);

      expect(zurueck.equippedIn(GearSlot.waffe)?.id, klinge);
      expect(zurueck.spentGold, vorher);
    });

    test('was man nicht besitzt, kann man nicht anlegen', () {
      const loadout = Loadout.empty();

      expect(loadout.equip(klinge), same(loadout));
    });

    test('Boni addieren sich über die Plätze', () {
      final loadout = const Loadout.empty()
          .buy(klinge, availableGold: 5000)
          .buy(helm, availableGold: 5000);

      final klingeBonus = GearCatalog.byId(klinge)?.bonus;
      final helmBonus = GearCatalog.byId(helm)?.bonus;

      expect(
        loadout.bonus.attack,
        (klingeBonus?.attack ?? 0) + (helmBonus?.attack ?? 0),
      );
      expect(
        loadout.bonus.maxHp,
        (klingeBonus?.maxHp ?? 0) + (helmBonus?.maxHp ?? 0),
      );
    });
  });

  group('Speichern und laden', () {
    test('ein voller Stand kommt unverändert zurück', () {
      final loadout = const Loadout.empty()
          .buy(klinge, availableGold: 9000)
          .buy(helm, availableGold: 9000)
          .buy(grosseKlinge, availableGold: 9000)
          .equip(klinge);

      final gelesen = Loadout.fromJson(loadout.toJson());

      expect(gelesen.owned.map((i) => i.id), loadout.owned.map((i) => i.id));
      expect(gelesen.spentGold, loadout.spentGold);
      expect(gelesen.equippedIdIn(GearSlot.waffe), klinge);
      expect(gelesen.equippedIdIn(GearSlot.helm), helm);
      expect(gelesen.bonus.attack, loadout.bonus.attack);
    });

    test('unbekannte Ids verschwinden mitsamt ihrem Preis', () {
      // Der Fall, der ohne diese Nachsicht den Goldstand verfälschen
      // würde: ein Stück, das es in dieser Version nicht mehr gibt.
      final gelesen = Loadout.fromJson(<String, Object?>{
        'ownedIds': <Object?>[klinge, 'gear-aus-einer-anderen-version', 42],
        'equipped': <String, Object?>{'waffe': klinge},
      });

      expect(gelesen.owned.map((i) => i.id), <String>[klinge]);
      expect(gelesen.spentGold, GearCatalog.byId(klinge)?.price);
    });

    test('Getragenes ohne Besitz wird nicht getragen', () {
      final gelesen = Loadout.fromJson(<String, Object?>{
        'ownedIds': <Object?>[],
        'equipped': <String, Object?>{'waffe': klinge},
      });

      expect(gelesen.equippedIdIn(GearSlot.waffe), isNull);
    });

    test('ein Stück auf dem falschen Platz wird verworfen', () {
      final gelesen = Loadout.fromJson(<String, Object?>{
        'ownedIds': <Object?>[klinge],
        'equipped': <String, Object?>{'helm': klinge},
      });

      expect(gelesen.isOwned(klinge), isTrue);
      expect(gelesen.equippedIdIn(GearSlot.helm), isNull);
    });

    test('Müll ergibt einen leeren Stand statt einer Ausnahme', () {
      expect(Loadout.fromJson(<String, Object?>{}).owned, isEmpty);
      expect(
        Loadout.fromJson(<String, Object?>{'ownedIds': 'nein'}).owned,
        isEmpty,
      );
    });
  });
}
