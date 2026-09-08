import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// Prüft den **Inhalt** der Sets, nicht den Code drumherum — dieselbe
/// Rolle wie `catalog_test.dart` für den Laden. Ein neues Set wird
/// automatisch mitgeprüft.
void main() {
  /// Gold, das fünf Gewohnheiten am Tag bringen. Steht in
  /// `package:habits`, das dieses Package nicht kennt — deshalb hier als
  /// ausdrückliche Annahme, geprüft von `test/progression_test.dart` in
  /// der App.
  const int goldProTag = 25;

  group('Die Sets', () {
    test('Ids und Namen sind eindeutig', () {
      final ids = GearSets.all.map((s) => s.id).toList();
      final namen = GearSets.all.map((s) => s.name).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(namen.toSet(), hasLength(namen.length));
    });

    test('jedes Set hat genau vier Stücke', () {
      for (final set in GearSets.all) {
        expect(
          GearCatalog.piecesOf(set.id),
          hasLength(GearSet.fullSize),
          reason: '${set.name} ist nicht vollständig',
        );
      }
    });

    test('die vier Stücke liegen auf vier verschiedenen Plätzen', () {
      // Zwei Teile auf demselben Platz hießen: Das Set ist nie voll
      // tragbar. Ein Platz trägt genau ein Stück.
      for (final set in GearSets.all) {
        final plaetze = GearCatalog.piecesOf(set.id).map((i) => i.slot);

        expect(plaetze.toSet(), hasLength(GearSet.fullSize), reason: set.name);
      }
    });

    test('Ring und Talisman gehören zu keinem Set', () {
      // Sonst wäre ein voller Satz gleichbedeutend mit „die ganze
      // Ausrüstung steht fest", und es gäbe nichts mehr zu wählen.
      for (final slot in <GearSlot>[GearSlot.ring, GearSlot.talisman]) {
        for (final item in GearCatalog.forSlot(slot)) {
          expect(item.setId, isNull, reason: item.name);
        }
      }
    });

    test('jeder Set-Platz führt weiter zwei freie Stücke', () {
      // Fünf Stücke je Platz, drei davon in Sets. Wer kein Set will, soll
      // trotzdem etwas zu wählen haben.
      for (final slot in <GearSlot>[
        GearSlot.waffe,
        GearSlot.ruestung,
        GearSlot.helm,
        GearSlot.schuhe,
      ]) {
        final frei = GearCatalog.forSlot(slot).where((i) => !i.isSetPiece);

        expect(frei, hasLength(2), reason: slot.label);
      }
    });

    test('jede setId an einem Stück gibt es auch als Set', () {
      // Die Naht in die andere Richtung: Eine Marke, die ins Leere zeigt,
      // wäre ein Stück, das nie zu einem Set beiträgt.
      for (final item in GearCatalog.all) {
        if (item.setId == null) continue;

        expect(GearSets.byId(item.setId), isNotNull, reason: item.name);
      }
    });

    test('jede Art kommt genau einmal vor', () {
      // Zwei Sets auf dieselbe Art wären austauschbar; man nähme das
      // stärkere. Drei Arten, drei Sets.
      final arten = GearSets.all.map((s) => s.target).toList();

      expect(arten.toSet(), hasLength(arten.length));
      expect(arten.toSet(), hasLength(SetTarget.values.length));
    });

    test('jedes Set begründet sich', () {
      for (final set in GearSets.all) {
        expect(set.why.length, greaterThan(40), reason: set.name);
      }
    });
  });

  group('Die beiden Stufen', () {
    test('beide wirken, und die volle wirkt stärker', () {
      for (final set in GearSets.all) {
        expect(set.twoPiece.isEmpty, isFalse, reason: set.name);
        expect(set.fourPiece.isEmpty, isFalse, reason: set.name);

        // Verglichen wird über die Beschreibung: Jede Stufe nennt
        // dieselben Hebel, die volle mit den größeren Zahlen.
        expect(
          set.fourPiece.labels,
          hasLength(set.twoPiece.labels.length),
          reason: '${set.name}: die Stufen ziehen an verschiedenen Hebeln',
        );
        expect(
          set.fourPiece.damageFactor,
          greaterThanOrEqualTo(set.twoPiece.damageFactor),
          reason: set.name,
        );
        expect(
          set.fourPiece.energyDiscount,
          greaterThanOrEqualTo(set.twoPiece.energyDiscount),
          reason: set.name,
        );
        expect(
          set.fourPiece.timingSpeedFactor,
          lessThanOrEqualTo(set.twoPiece.timingSpeedFactor),
          reason: set.name,
        );
        expect(
          set.fourPiece.timingWindowFactor,
          greaterThanOrEqualTo(set.twoPiece.timingWindowFactor),
          reason: set.name,
        );
      }
    });

    test('unter zwei Teilen wirkt nichts', () {
      for (final set in GearSets.all) {
        expect(set.perkFor(0), isNull, reason: set.name);
        expect(set.perkFor(1), isNull, reason: set.name);
        expect(set.perkFor(2), set.twoPiece, reason: set.name);
        expect(set.perkFor(4), set.fourPiece, reason: set.name);
      }
    });

    test('jede Stufe lässt sich in Worten sagen', () {
      for (final set in GearSets.all) {
        expect(set.twoPiece.labels, isNotEmpty, reason: set.name);
        expect(set.fourPiece.labels, isNotEmpty, reason: set.name);
      }
    });
  });

  group('Preise gegen den Gold-Zufluss', () {
    test('kein Set ist deutlich billiger als die anderen', () {
      // **Die Wahl zwischen den Sets soll eine Frage des Spielstils sein,
      // nicht des Geldbeutels.** Wäre eines um die Hälfte billiger, nähme
      // man dieses und die Entscheidung wäre keine.
      final preise = GearSets.all.map((s) => GearCatalog.fullSetPrice(s.id));
      final billigstes = preise.reduce((a, b) => a < b ? a : b);
      final teuerstes = preise.reduce((a, b) => a > b ? a : b);

      expect(teuerstes / billigstes, lessThan(1.15));
    });

    test('die kleine Stufe ist im ersten Monat erreichbar', () {
      // Ein Bonus, den im 30-Tage-Lauf niemand sieht, ist keiner.
      for (final set in GearSets.all) {
        final stuecke = GearCatalog.piecesOf(set.id);
        final zweiBilligste = stuecke.take(GearSet.smallSize);
        final tage =
            zweiBilligste.fold<int>(0, (sum, i) => sum + i.price) / goldProTag;

        expect(tage, lessThan(30), reason: '${set.name}: $tage Tage');
      }
    });

    test('die volle Stufe ist ein Fernziel, kein Monatskauf', () {
      // Das ist Absicht: Der Laden soll nach dreißig Tagen noch etwas zu
      // wollen übrig lassen. Zu weit darf es trotzdem nicht sein.
      for (final set in GearSets.all) {
        final tage = GearCatalog.fullSetPrice(set.id) / goldProTag;

        expect(tage, greaterThan(45), reason: '${set.name}: zu schnell voll');
        expect(tage, lessThan(110), reason: '${set.name}: unerreichbar');
      }
    });
  });
}
