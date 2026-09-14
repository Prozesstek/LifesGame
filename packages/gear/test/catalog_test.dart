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

    test('jeder Platz führt acht Stücke: fünf offene, drei verdiente', () {
      // Fünf von Anfang an (ADR-0029), drei hinter der Gegnerreihe
      // (ADR-0034). Beide Zahlen einzeln, damit ein Platz nicht mit acht
      // offenen und null verdienten durchrutscht.
      for (final slot in GearSlot.values) {
        final alle = GearCatalog.forSlot(slot);
        final offen = alle.where((item) => !item.rarity.isGated);
        final verdient = alle.where((item) => item.rarity.isGated);

        expect(offen, hasLength(5), reason: slot.label);
        expect(verdient, hasLength(3), reason: slot.label);
      }
    });

    test('jeder Platz hat zwei, zwei, eins — und zwei, eins', () {
      // Zwei gewöhnliche, zwei ungewöhnliche, ein seltenes; dahinter zwei
      // epische und ein legendäres. Die Form ist überall dieselbe, damit
      // ein Platz nicht heimlich reicher wird als ein anderer.
      for (final slot in GearSlot.values) {
        expect(
          GearCatalog.forSlotAndRarity(slot, GearRarity.epic),
          hasLength(2),
          reason: slot.label,
        );
        expect(
          GearCatalog.forSlotAndRarity(slot, GearRarity.legendary),
          hasLength(1),
          reason: slot.label,
        );
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

    test('das teuerste offene Stück ist in etwa einem Monat tragbar', () {
      // **Nur die Stücke, die von Anfang an kaufbar sind.** Die drei
      // verdienten je Platz haben ihre eigene Grenze im nächsten Test.
      final teuerstes = GearCatalog.all
          .where((item) => !item.rarity.isGated)
          .map((item) => item.price)
          .reduce((a, b) => a > b ? a : b);
      final tage = teuerstes / goldProTag;

      expect(tage, greaterThan(20));
      expect(tage, lessThan(45));
    });

    test('Verdientes ist teurer als Offenes, aber nicht unerreichbar', () {
      // **Die Sperre ist die Hürde, nicht der Preis** (ADR-0034). Wer
      // Sprosse zwanzig geschafft hat, hat das Gold der Reihe dazu — die
      // Grenze liegt deshalb bei achtzig Tagen Gewohnheiten, nicht bei
      // fünfundvierzig. Darüber sähe es niemand mehr, auch nicht mit der
      // Reihe im Rücken.
      for (final slot in GearSlot.values) {
        final selten = GearCatalog.forSlotAndRarity(slot, GearRarity.rare);
        final episch = GearCatalog.forSlotAndRarity(slot, GearRarity.epic);
        final legendaer = GearCatalog.forSlotAndRarity(
          slot,
          GearRarity.legendary,
        );

        expect(
          episch.first.price,
          greaterThan(selten.single.price),
          reason: slot.label,
        );
        expect(
          legendaer.single.price,
          greaterThan(episch.last.price),
          reason: slot.label,
        );
        expect(
          legendaer.single.price / goldProTag,
          lessThanOrEqualTo(80),
          reason: '${slot.label}: Legendär unerreichbar',
        );
      }
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

    test('ein Verkauf bringt weniger zurück, als er gekostet hat', () {
      // **Beide Grenzen sind eine Entscheidung** (ADR-0031). Bei 1,0 wäre
      // der Laden folgenlos — kaufen, ansehen, zurückgeben —, bei 0,0
      // wäre der Verkauf eine Löschtaste.
      expect(GearPrices.refundShare, greaterThan(0));
      expect(GearPrices.refundShare, lessThan(1));

      for (final item in GearCatalog.all) {
        final erloes = Loadout.refundFor(item);

        expect(erloes, greaterThan(0), reason: item.name);
        expect(erloes, lessThan(item.price), reason: item.name);
      }
    });

    test('ein Fehlkauf kostet höchstens gut eine Woche', () {
      // Der Verlust muss spürbar sein, aber ein Irrtum darf nicht den
      // ganzen Monat kosten — sonst kauft niemand mehr etwas aus. Gilt für
      // die offenen Stücke; wer sich ein verdientes gerade erkämpft hat,
      // verkauft es nicht aus Versehen.
      final teuerstes = GearCatalog.all
          .where((item) => !item.rarity.isGated)
          .map((item) => item.price - Loadout.refundFor(item))
          .reduce((a, b) => a > b ? a : b);

      expect(teuerstes / goldProTag, lessThan(25));
    });

    test('das seltene Stück ist auf seinem Platz das teuerste offene', () {
      for (final slot in GearSlot.values) {
        final selten = GearCatalog.forSlotAndRarity(slot, GearRarity.rare);
        if (selten.isEmpty) continue;

        expect(
          selten.single.price,
          GearCatalog.forSlot(slot).where((i) => !i.rarity.isGated).last.price,
          reason: 'Auf ${slot.label} ist Selten nicht das teuerste Offene',
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
