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

  group('Verkaufen', () {
    final stueck = GearCatalog.byId(klinge)!;
    final erloes = Loadout.refundFor(stueck);

    Loadout mitKlinge() =>
        const Loadout.empty().buy(klinge, availableGold: 100000);

    test('der Erlös ist die Hälfte des Preises', () {
      expect(erloes, (stueck.price * GearPrices.refundShare).floor());
    });

    test('verkauft heißt: nicht mehr im Besitz, nicht mehr getragen', () {
      final nachher = mitKlinge().sell(klinge);

      expect(nachher.isOwned(klinge), isFalse);
      expect(nachher.isEquipped(klinge), isFalse);
      expect(nachher.equippedIn(GearSlot.waffe), isNull);
    });

    test('zurück kommt genau die Hälfte, nicht der ganze Preis', () {
      // **Der Kern von ADR-0031.** Ohne die versenkten Kosten fiele der
      // volle Preis aus `spentGold` heraus, sobald das Stück den Besitz
      // verlässt — der Laden wäre folgenlos.
      final vorher = mitKlinge();
      final nachher = vorher.sell(klinge);

      expect(vorher.spentGold, stueck.price);
      expect(nachher.spentGold, stueck.price - erloes);
      expect(nachher.lostGold, stueck.price - erloes);
    });

    test('zweimal kaufen und verkaufen kostet zweimal', () {
      final einmal = mitKlinge().sell(klinge);
      final zweimal = einmal.buy(klinge, availableGold: 100000).sell(klinge);

      expect(zweimal.soldIds, <String>[klinge, klinge]);
      expect(zweimal.lostGold, einmal.lostGold * 2);
    });

    test('was man nicht besitzt, kann man nicht verkaufen', () {
      const leer = Loadout.empty();

      expect(leer.canSell(klinge), isFalse);
      expect(leer.sell(klinge), same(leer));
      expect(leer.sell('gear-gibt-es-nicht'), same(leer));
    });

    test('ein anderes Stück auf demselben Platz bleibt liegen', () {
      // Verkauft wird genau eines, nicht der Platz.
      final beide = const Loadout.empty()
          .buy(klinge, availableGold: 100000)
          .buy(grosseKlinge, availableGold: 100000);

      final nachher = beide.sell(grosseKlinge);

      expect(nachher.isOwned(klinge), isTrue);
      expect(nachher.isOwned(grosseKlinge), isFalse);
      // Der Platz ist frei — das verkaufte Stück war das getragene.
      expect(nachher.equippedIn(GearSlot.waffe), isNull);
    });

    test('Gold kann durch einen Verkauf nie sinken', () {
      // Verkaufen gibt zurück, es nimmt nicht. Formal: `spentGold` darf
      // dabei nur fallen.
      for (final item in GearCatalog.all) {
        final mit = const Loadout.empty().buy(item.id, availableGold: 100000);
        final ohne = mit.sell(item.id);

        expect(
          ohne.spentGold,
          lessThanOrEqualTo(mit.spentGold),
          reason: item.name,
        );
      }
    });

    test('die Historie überlebt Kaufen, Anlegen und Ablegen', () {
      // **Der Fallstrick aus `gotchas.md`, vorweggenommen:** `soldIds`
      // ist ein Feld, das jede Methode weiterreichen muss, die ein neues
      // Loadout baut. Wer eine vergisst, löscht die versenkten Kosten —
      // und der Spieler bekommt sein Gold zurück.
      var loadout = mitKlinge().sell(klinge);
      final erwartet = loadout.lostGold;

      loadout = loadout
          .buy(helm, availableGold: 100000)
          .equip(helm)
          .unequip(GearSlot.helm);

      expect(loadout.lostGold, erwartet);
      expect(loadout.soldIds, <String>[klinge]);
    });

    test('ein Verkauf überlebt Speichern und Laden', () {
      final vorher = mitKlinge().sell(klinge);
      final nachher = Loadout.fromJson(vorher.toJson());

      expect(nachher.soldIds, vorher.soldIds);
      expect(nachher.lostGold, vorher.lostGold);
    });

    test('ohne Verkäufe steht nichts im Stand', () {
      // Ein Stand ohne Verkäufe sieht aus wie vor ADR-0031.
      expect(mitKlinge().toJson().containsKey('soldIds'), isFalse);
    });

    test('eine unbekannte Id fällt beim Laden heraus', () {
      final gelesen = Loadout.fromJson(<String, Object?>{
        'soldIds': <Object?>['gear-gibt-es-nicht', klinge, 42],
      });

      expect(gelesen.soldIds, <String>[klinge]);
    });
  });

  group('Sets', () {
    /// Ein Stand, der die [anzahl] billigsten Teile eines Sets trägt.
    Loadout mitTeilenVon(GearSet set, int anzahl) {
      var loadout = const Loadout.empty();
      for (final item in GearCatalog.piecesOf(set.id).take(anzahl)) {
        loadout = loadout.buy(item.id, availableGold: 100000);
      }
      return loadout;
    }

    test('ein Teil allein wirkt noch nicht', () {
      final loadout = mitTeilenVon(GearSets.eisernerWille, 1);

      expect(loadout.equippedPiecesOf(GearSets.eisernerWille.id), 1);
      expect(loadout.activeSets, isEmpty);
    });

    test('zwei Teile geben die kleine Stufe', () {
      final loadout = mitTeilenVon(GearSets.eisernerWille, 2);
      final aktiv = loadout.activeSets.single;

      expect(aktiv.set.id, GearSets.eisernerWille.id);
      expect(aktiv.pieces, 2);
      expect(aktiv.perk, GearSets.eisernerWille.twoPiece);
      expect(aktiv.isFull, isFalse);
    });

    test('vier Teile geben die volle Stufe, nicht beide', () {
      final loadout = mitTeilenVon(GearSets.eisernerWille, 4);
      final aktiv = loadout.activeSets.single;

      expect(aktiv.pieces, 4);
      expect(aktiv.perk, GearSets.eisernerWille.fourPiece);
      expect(aktiv.isFull, isTrue);
    });

    test('Ablegen nimmt die Stufe wieder weg', () {
      // **Besitz zählt nicht, nur was getragen wird.** Sonst wäre die
      // Wahl auf jedem Platz folgenlos, sobald man einmal alles gekauft
      // hat.
      final voll = mitTeilenVon(GearSets.eisernerWille, 4);
      final ohneHelm = voll.unequip(GearSlot.helm);

      expect(ohneHelm.activeSets.single.pieces, 3);
      expect(
        ohneHelm.activeSets.single.perk,
        GearSets.eisernerWille.twoPiece,
      );
      // Der Helm liegt weiter im Rucksack.
      expect(
        ohneHelm.owned.any((i) => i.setId == GearSets.eisernerWille.id),
        isTrue,
      );
    });

    test('zwei Sets können gleichzeitig anliegen', () {
      // Vier Set-Plätze, zwei Sets zu je zwei Teilen — das geht auf, und
      // es soll gehen: Zwei kleine Stufen gegen eine volle ist genau die
      // Entscheidung, die ein Set-System interessant macht.
      var loadout = const Loadout.empty();
      for (final set in <GearSet>[
        GearSets.eisernerWille,
        GearSets.sturmruf,
      ]) {
        for (final item in GearCatalog.piecesOf(set.id).take(2)) {
          loadout = loadout.buy(item.id, availableGold: 100000);
        }
      }

      expect(loadout.activeSets, hasLength(2));
      expect(loadout.activeSets.every((a) => a.pieces == 2), isTrue);
    });

    test('ein Stück ohne Set trägt zu keinem bei', () {
      final loadout = const Loadout.empty().buy(
        'gear-lederkappe',
        availableGold: 100000,
      );

      expect(loadout.activeSets, isEmpty);
    });
  });
}
