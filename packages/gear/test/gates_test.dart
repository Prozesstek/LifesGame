import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// Episch und Legendär hängen an der Gegnerreihe (ADR-0034).
///
/// Was hier **nicht** geprüft werden kann: ob die Sprossen zu einer echten
/// Reihe gehören. Dieses Package kennt sie nicht — das ist Absicht und der
/// Grund, warum `test/gear_gates_seam_test.dart` in der App dazugehört.
void main() {
  group('Die Sperre', () {
    test('die drei offenen Stufen verlangen nichts', () {
      for (final rarity in GearRarity.open) {
        expect(GearGates.rungFor(rarity), 0, reason: rarity.name);
        expect(rarity.isGated, isFalse, reason: rarity.name);
        expect(
          GearGates.isOpen(rarity, highestRung: 0),
          isTrue,
          reason: rarity.name,
        );
      }
    });

    test('Legendär liegt hinter Episch', () {
      expect(GearGates.epicRung, greaterThan(0));
      expect(GearGates.legendaryRung, greaterThan(GearGates.epicRung));
    });

    test('genau die Sprosse öffnet, eine darunter nicht', () {
      expect(
        GearGates.isOpen(
          GearRarity.epic,
          highestRung: GearGates.epicRung - 1,
        ),
        isFalse,
      );
      expect(
        GearGates.isOpen(GearRarity.epic, highestRung: GearGates.epicRung),
        isTrue,
      );
      expect(
        GearGates.isOpen(
          GearRarity.legendary,
          highestRung: GearGates.legendaryRung - 1,
        ),
        isFalse,
      );
      expect(
        GearGates.isOpen(
          GearRarity.legendary,
          highestRung: GearGates.legendaryRung,
        ),
        isTrue,
      );
    });

    test('jede Stufe ist entweder offen oder verdient', () {
      for (final rarity in GearRarity.values) {
        expect(
          GearRarity.open.contains(rarity) != GearRarity.gated.contains(rarity),
          isTrue,
          reason: rarity.name,
        );
      }
    });
  });

  group('Im Laden', () {
    final episch = GearCatalog.all.firstWhere(
      (i) => i.rarity == GearRarity.epic,
    );
    final legendaer = GearCatalog.all.firstWhere(
      (i) => i.rarity == GearRarity.legendary,
    );

    GearCopy angebot(GearItem item) => GearCopy(
          uid: 'laden-${item.id}',
          itemId: item.id,
          bonus: item.bonus.scaled,
          paid: item.price,
        );

    test('ohne Sprosse ist Episches gesperrt — auch mit Gold', () {
      // **Die Sperre kommt vor dem Gold.** Wer das Stück ansieht, soll
      // lesen, dass es verdient werden muss, nicht dass es zu teuer ist.
      const leer = Loadout.empty();

      expect(
        leer.blockFor(angebot(episch), availableGold: 100000),
        PurchaseBlock.gesperrt,
      );
      expect(leer.buy(angebot(episch), availableGold: 100000), same(leer));
    });

    test('mit der Sprosse ist es ein Kauf wie jeder andere', () {
      const leer = Loadout.empty();

      expect(
        leer.blockFor(
          angebot(episch),
          availableGold: 100000,
          highestRung: GearGates.epicRung,
        ),
        isNull,
      );
      expect(
        leer.blockFor(
          angebot(episch),
          availableGold: 0,
          highestRung: GearGates.epicRung,
        ),
        PurchaseBlock.zuWenigGold,
      );
    });

    test('Episch reicht nicht für Legendär', () {
      expect(
        const Loadout.empty().blockFor(
          angebot(legendaer),
          availableGold: 100000,
          highestRung: GearGates.epicRung,
        ),
        PurchaseBlock.gesperrt,
      );
    });

    test('ein gekauftes Stück bleibt, auch wenn die Sprosse fehlt', () {
      // Die Sprosse wird beim **Kauf** geprüft, nicht beim Tragen.
      final mit = const Loadout.empty().buy(
        angebot(episch),
        availableGold: 100000,
        highestRung: GearGates.epicRung,
      );
      final gelesen = Loadout.fromJson(mit.toJson());

      expect(gelesen.ownsItem(episch.id), isTrue);
      expect(gelesen.equippedIn(episch.slot), episch);
      expect(gelesen.bonus.isEmpty, isFalse);
    });

    test('Verkaufen braucht keine Sprosse', () {
      final mit = const Loadout.empty().buy(
        angebot(episch),
        availableGold: 100000,
        highestRung: GearGates.epicRung,
      );
      final uid = angebot(episch).uid;

      expect(mit.canSell(uid), isTrue);
      expect(mit.sell(uid).ownsItem(episch.id), isFalse);
    });
  });
}
