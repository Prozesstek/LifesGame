import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// Ein Angebot mit genau 100 % und dem Katalogpreis — wie ein Stück aus
/// dem Tagesladen, nur ohne Würfel.
GearCopy _angebot(String itemId, {String? uid}) {
  final item = GearCatalog.byId(itemId)!;
  return GearCopy(
    uid: uid ?? 'test-$itemId',
    itemId: itemId,
    bonus: item.bonus.scaled,
    paid: item.price,
  );
}

const _viel = 1000000;

void main() {
  final klinge = GearCatalog.byId('gear-uebungsklinge')!;
  final bogen = GearCatalog.byId('gear-kurzbogen')!;

  group('Kaufen', () {
    test('ein leeres Inventar hat nichts und hat nichts ausgegeben', () {
      const leer = Loadout.empty();
      expect(leer.ownedCopies, isEmpty);
      expect(leer.spentGold, 0);
      expect(leer.bonus.isEmpty, isTrue);
    });

    test('ein Kauf kostet genau den Preis', () {
      final l =
          const Loadout.empty().buy(_angebot(klinge.id), availableGold: _viel);
      expect(l.spentGold, klinge.price);
      expect(l.ownsItem(klinge.id), isTrue);
    });

    test('auf einen leeren Platz wird gleich angelegt', () {
      final l =
          const Loadout.empty().buy(_angebot(klinge.id), availableGold: _viel);
      expect(l.equippedIn(GearSlot.waffe), klinge);
    });

    test('ein zweites Stück verdrängt das getragene nicht von selbst', () {
      // Ein gewürfeltes Stück kann schlechter sein als das getragene.
      final l = const Loadout.empty()
          .buy(_angebot(klinge.id), availableGold: _viel)
          .buy(_angebot(bogen.id), availableGold: _viel);
      expect(l.equippedIn(GearSlot.waffe), klinge);
      expect(l.copiesIn(GearSlot.waffe), hasLength(2));
    });

    test('zu wenig Gold nennt den Grund und ändert nichts', () {
      const leer = Loadout.empty();
      final angebot = _angebot(klinge.id);
      expect(
        leer.blockFor(angebot, availableGold: klinge.price - 1),
        PurchaseBlock.zuWenigGold,
      );
      expect(leer.buy(angebot, availableGold: klinge.price - 1), same(leer));
    });

    test('genau der Preis reicht', () {
      expect(
        const Loadout.empty()
            .blockFor(_angebot(klinge.id), availableGold: klinge.price),
        isNull,
      );
    });

    test('dasselbe Angebot gibt es nur einmal, auch nach dem Verkauf', () {
      final angebot = _angebot(klinge.id);
      final gekauft = const Loadout.empty().buy(angebot, availableGold: _viel);
      expect(
        gekauft.blockFor(angebot, availableGold: _viel),
        PurchaseBlock.bereitsGekauft,
      );
      final verkauft = gekauft.sell(angebot.uid);
      expect(
        verkauft.blockFor(angebot, availableGold: _viel),
        PurchaseBlock.bereitsGekauft,
      );
    });

    test('ein zweites Exemplar desselben Stücks ist ein eigener Kauf', () {
      final l = const Loadout.empty()
          .buy(_angebot(klinge.id, uid: 'a'), availableGold: _viel)
          .buy(_angebot(klinge.id, uid: 'b'), availableGold: _viel);
      expect(l.copiesIn(GearSlot.waffe), hasLength(2));
      expect(l.spentGold, klinge.price * 2);
    });

    test('ein unbekanntes Stück nennt sich unbekannt', () {
      const fremd = GearCopy(
        uid: 'x',
        itemId: 'gibt-es-nicht-und-soll-es-nie-geben',
        bonus: GearBonus(),
        paid: 1,
      );
      expect(GearCatalog.byId(fremd.itemId), isNull);
      expect(
        const Loadout.empty().blockFor(fremd, availableGold: _viel),
        PurchaseBlock.unbekannt,
      );
    });
  });

  group('Beute', () {
    test('kostet nichts, auch wenn das Exemplar einen Preis trägt', () {
      final l = const Loadout.empty().addFree(_angebot(klinge.id));
      expect(l.spentGold, 0);
      expect(l.ownsItem(klinge.id), isTrue);
      expect(l.equippedIn(GearSlot.waffe), klinge);
    });

    test('dieselbe Beute kommt nicht zweimal an', () {
      final beute = _angebot(klinge.id);
      final einmal = const Loadout.empty().addFree(beute);
      expect(einmal.addFree(beute), same(einmal));
    });
  });

  group('Tragen', () {
    test('nur Getragenes wirkt, Besitz allein nicht', () {
      final l = const Loadout.empty()
          .buy(_angebot(klinge.id), availableGold: _viel)
          .unequip(GearSlot.waffe);
      expect(l.ownsItem(klinge.id), isTrue);
      expect(l.bonus.isEmpty, isTrue);
    });

    test('anlegen verdrängt, zurückrüsten kostet nichts', () {
      final l = const Loadout.empty()
          .buy(_angebot(klinge.id), availableGold: _viel)
          .buy(_angebot(bogen.id), availableGold: _viel);
      final bogenUid = l
          .copiesIn(GearSlot.waffe)
          .firstWhere((c) => c.itemId == bogen.id)
          .uid;
      final umgeruestet = l.equip(bogenUid);
      expect(umgeruestet.equippedIn(GearSlot.waffe), bogen);
      expect(umgeruestet.spentGold, l.spentGold);
    });

    test('was man nicht besitzt, kann man nicht anlegen', () {
      const leer = Loadout.empty();
      expect(leer.equip('nichts'), same(leer));
    });

    test('der Bonus ist der des Exemplars, im Kampfmassstab', () {
      const wurf = GearCopy(
        uid: 'w',
        itemId: 'gear-uebungsklinge',
        bonus: GearBonus(attack: 23),
        paid: 0,
      );
      final l = const Loadout.empty().addFree(wurf);
      expect(l.bonus.attack, 23);
    });

    test('Boni addieren sich über die Plätze', () {
      final helm = GearCatalog.forSlot(GearSlot.helm).first;
      final l = const Loadout.empty()
          .buy(_angebot(klinge.id), availableGold: _viel)
          .buy(_angebot(helm.id), availableGold: _viel);
      expect(l.bonus, klinge.bonus.scaled + helm.bonus.scaled);
    });
  });

  group('Verkaufen', () {
    test('der Erlös ist ein Viertel des Katalogpreises', () {
      expect(GearPrices.refundShare, 0.25);
      expect(Loadout.refundFor(klinge), (klinge.price * 0.25).floor());
    });

    test('verkauft heisst: nicht mehr im Besitz, nicht mehr getragen', () {
      final angebot = _angebot(klinge.id);
      final l = const Loadout.empty()
          .buy(angebot, availableGold: _viel)
          .sell(angebot.uid);
      expect(l.owns(angebot.uid), isFalse);
      expect(l.equippedIn(GearSlot.waffe), isNull);
      expect(l.spentGold, klinge.price - Loadout.refundFor(klinge));
    });

    test('Beute zu verkaufen bringt Gold', () {
      final beute = _angebot(klinge.id);
      final l = const Loadout.empty().addFree(beute).sell(beute.uid);
      expect(l.spentGold, -Loadout.refundFor(klinge));
    });

    test('was man nicht besitzt, kann man nicht verkaufen', () {
      const leer = Loadout.empty();
      expect(leer.canSell('nichts'), isFalse);
      expect(leer.sell('nichts'), same(leer));
    });

    test('zweimal verkaufen zählt einmal', () {
      final angebot = _angebot(klinge.id);
      final einmal = const Loadout.empty()
          .buy(angebot, availableGold: _viel)
          .sell(angebot.uid);
      expect(einmal.sell(angebot.uid), same(einmal));
    });

    test('die Historie überlebt Kaufen, Anlegen und Ablegen', () {
      // Jede Methode baut über `_copyWith` — dieser Weg hält fest, dass
      // keine den Verkauf oder die Schlüssel vergisst.
      final a = _angebot(klinge.id, uid: 'a');
      final l = const Loadout.empty()
          .buy(a, availableGold: _viel)
          .sell('a')
          .useKey(earned: 3)
          .buy(_angebot(bogen.id), availableGold: _viel)
          .equip('test-${bogen.id}')
          .unequip(GearSlot.waffe);
      expect(l.soldCount, 1);
      expect(l.keysConsumed, 1);
      expect(
        l.spentGold,
        klinge.price - Loadout.refundFor(klinge) + bogen.price,
      );
    });
  });

  group('Alles Schlechtere', () {
    test('ein schwächerer Wurf desselben Stücks ist Ausschuss', () {
      // Ein Stück ohne Set — Set-Teile sind nie Ausschuss.
      expect(GearCatalog.byId('gear-streitkolben')!.isSetPiece, isFalse);
      const stark = GearCopy(
        uid: 's',
        itemId: 'gear-streitkolben',
        bonus: GearBonus(attack: 11),
        paid: 0,
      );
      const schwach = GearCopy(
        uid: 'w',
        itemId: 'gear-streitkolben',
        bonus: GearBonus(attack: 9),
        paid: 0,
      );
      final l = const Loadout.empty().addFree(stark).addFree(schwach);
      expect(l.junk.map((c) => c.uid), <String>['w']);
    });

    test('eine andere Waffe ist nie Ausschuss — sie schlägt anders', () {
      final l = const Loadout.empty()
          .addFree(_angebot('gear-kriegsstab'))
          .addFree(_angebot(bogen.id));
      expect(l.junk, isEmpty);
    });

    test('Set-Teile und Episches bleiben liegen', () {
      final ringe = GearCatalog.forSlot(GearSlot.ring);
      final episch = ringe.firstWhere((i) => i.rarity == GearRarity.epic);
      final bester = ringe.firstWhere((i) => i.rarity == GearRarity.legendary);
      final l = const Loadout.empty()
          .addFree(_angebot(bester.id))
          .addFree(_angebot(episch.id));
      expect(l.junk, isEmpty);
    });

    test('alles auf einmal verkaufen', () {
      final helme = GearCatalog.forSlotAndRarity(
        GearSlot.helm,
        GearRarity.common,
      ).where((i) => !i.isSetPiece).toList();
      final rare =
          GearCatalog.forSlotAndRarity(GearSlot.helm, GearRarity.rare).first;
      var l = const Loadout.empty().addFree(_angebot(rare.id));
      for (final h in helme) {
        l = l.addFree(_angebot(h.id));
      }
      final ausschuss = l.junk.map((c) => c.uid).toList();
      expect(ausschuss, hasLength(helme.length));
      final aufgeraeumt = l.sellAll(ausschuss);
      expect(aufgeraeumt.junk, isEmpty);
      expect(aufgeraeumt.equippedIn(GearSlot.helm), rare);
    });
  });

  group('Schlüssel', () {
    test('ohne verdiente Schlüssel ändert Einsetzen nichts', () {
      const leer = Loadout.empty();
      expect(leer.useKey(earned: 0), same(leer));
    });

    test('der Überhang über zehn verfällt beim Einsetzen', () {
      final l = const Loadout.empty().useKey(earned: 40);
      expect(
        GearKeys.available(earned: 40, consumed: l.keysConsumed),
        GearKeys.cap - 1,
      );
    });
  });

  group('Speichern und laden', () {
    test('ein voller Stand kommt unverändert zurück', () {
      const wurf = GearCopy(
        uid: 'beute-3-20000-1',
        itemId: 'gear-uebungsklinge',
        bonus: GearBonus(attack: 12, defense: 3),
        paid: 0,
      );
      final l = const Loadout.empty()
          .buy(_angebot(bogen.id), availableGold: _viel)
          .addFree(wurf)
          .equip(wurf.uid)
          .sell('test-${bogen.id}')
          .useKey(earned: 5);
      final gelesen = Loadout.fromJson(l.toJson());

      expect(gelesen.toJson(), l.toJson());
      expect(gelesen.spentGold, l.spentGold);
      expect(gelesen.equippedCopyIn(GearSlot.waffe)?.bonus, wurf.bonus);
      expect(gelesen.keysConsumed, l.keysConsumed);
    });

    test('unbekannte Stücke verschwinden, der Rest bleibt', () {
      final json = <String, Object?>{
        'copies': <Object?>[
          <String, Object?>{'u': 'a', 'i': 'gibt-es-nicht', 'p': 999},
          _angebot(klinge.id).toJson(),
        ],
        'equipped': <String, Object?>{'waffe': 'test-${klinge.id}'},
      };
      final l = Loadout.fromJson(json);
      expect(l.ownedCopies, hasLength(1));
      expect(l.spentGold, klinge.price);
    });

    test('Müll ergibt einen leeren Stand statt einer Ausnahme', () {
      final l = Loadout.fromJson(<String, Object?>{
        'copies': 'kaputt',
        'sold': 3,
        'equipped': <Object?>[],
        'keys': 'viele',
      });
      expect(l.ownedCopies, isEmpty);
      expect(l.keysConsumed, 0);
    });
  });

  group('Übernahme alter Stände (vor ADR-0048)', () {
    // So sah ein Stand bis zum 24.09.2026 aus.
    final alt = <String, Object?>{
      'ownedIds': <Object?>[klinge.id, 'gear-lederwams', 'gibt-es-nicht'],
      'equipped': <String, Object?>{'waffe': klinge.id},
      'soldIds': <Object?>[bogen.id],
    };

    test('jedes Stück wird ein Exemplar mit genau 100 %', () {
      final l = Loadout.fromJson(alt);
      final kopie = l.equippedCopyIn(GearSlot.waffe);
      expect(kopie?.itemId, klinge.id);
      expect(kopie?.bonus, klinge.bonus.scaled);
      expect(kopie?.quality, 1.0);
    });

    test('Getragenes bleibt getragen, Unbekanntes fällt heraus', () {
      final l = Loadout.fromJson(alt);
      expect(l.equippedIn(GearSlot.waffe), klinge);
      expect(l.ownsItem('gibt-es-nicht'), isFalse);
    });

    test('das Gold bleibt, was es war — alte Verkäufe zum alten Satz', () {
      final l = Loadout.fromJson(alt);
      final besitz = <String>[klinge.id, 'gear-lederwams']
          .map((id) => GearCatalog.byId(id)?.price ?? 0)
          .fold<int>(0, (a, b) => a + b);
      final verloren =
          bogen.price - (bogen.price * Loadout.legacyRefundShare).floor();
      expect(l.spentGold, besitz + verloren);
    });

    test('verkauft bleibt je besessen', () {
      expect(Loadout.fromJson(alt).everOwnedIds, contains(bogen.id));
    });

    test('nach dem ersten Speichern ist es ein neuer Stand', () {
      final l = Loadout.fromJson(alt);
      final wieder = Loadout.fromJson(l.toJson());
      expect(wieder.toJson(), l.toJson());
      expect(wieder.toJson().containsKey('ownedIds'), isFalse);
    });
  });

  group('Sets', () {
    final eisern = GearCatalog.piecesOf('set-eiserner-wille');

    Loadout mitTeilen(int n) {
      var l = const Loadout.empty();
      for (final item in eisern.take(n)) {
        l = l.addFree(_angebot(item.id));
      }
      return l;
    }

    test('ein Teil allein wirkt noch nicht', () {
      expect(mitTeilen(1).activeSets, isEmpty);
      expect(mitTeilen(1).wearsAnySetPiece, isTrue);
    });

    test('zwei Teile geben die kleine Stufe, vier die volle', () {
      expect(mitTeilen(2).activeSets.single.pieces, 2);
      expect(mitTeilen(4).activeSets.single.pieces, 4);
    });

    test('Ablegen nimmt die Stufe wieder weg', () {
      final zwei = mitTeilen(2);
      final slot = eisern.first.slot;
      expect(zwei.unequip(slot).activeSets, isEmpty);
    });
  });
}
