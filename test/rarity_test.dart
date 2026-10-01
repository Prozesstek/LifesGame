import 'dart:math' as math;

import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/gear/widgets/rarity_badge.dart';
import 'package:lifes_game/ui/palette.dart';

/// Die Seltenheit eines Ausrüstungsstücks — im Katalog und im Bild.
///
/// Der Katalog selbst wird in `packages/gear/test/catalog_test.dart`
/// geprüft. Hier geht es um die Naht zur Oberfläche: dass jede Stufe eine
/// eigene Farbe hat und einen lesbaren Namen trägt.
void main() {
  group('Jede Stufe ist unterscheidbar', () {
    test('keine zwei Stufen teilen sich eine Farbe', () {
      final farben = <int>{
        for (final rarity in GearRarity.values)
          RarityBadge.colorOf(rarity).toARGB32(),
      };

      expect(farben, hasLength(GearRarity.values.length));
    });

    test('jede Stufe hat einen deutschen Namen', () {
      for (final rarity in GearRarity.values) {
        expect(rarity.label, isNotEmpty);
        expect(rarity.label, isNot(rarity.name));
      }
    });

    test('es sind fünf — zwei davon verdient, nicht nur gekauft', () {
      // Bis ADR-0034 waren es drei: Im Laden gab es nichts zu erreichen.
      // Seit der Gegnerreihe gibt es das, und Episch und Legendär hängen
      // daran (`GearGates`).
      expect(GearRarity.values, hasLength(5));
      expect(GearRarity.gated, hasLength(2));
    });

    test('Ausrüstung und Fähigkeiten teilen sich die Stufenreihe', () {
      // **Zwei Aufzählungen, eine Farbtabelle.** `RarityBadge` bekommt
      // für eine Fähigkeit nur die Nummer der Stufe, weil es sonst
      // beide Packages kennen müsste. Käme drüben eine Stufe dazu oder
      // rutschte eine an eine andere Position, bekäme „Selten" bei den
      // Fähigkeiten die Farbe von „Episch" — ohne eine einzige Meldung.
      expect(Rarity.values, hasLength(GearRarity.values.length));
      for (final rarity in Rarity.values) {
        expect(
          rarity.label,
          GearRarity.values[rarity.index].label,
          reason: 'Stufe ${rarity.index} heißt zweimal verschieden.',
        );
      }
    });
  });

  group('Rahmen und Name tragen die Seltenheit', () {
    double kontrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    test('ein Name in der Farbe seiner Stufe ist auf Pergament lesbar', () {
      // **Der Anlass:** Das Gold der Marke hatte auf Pergament 2,4 : 1.
      // Als Marke fiel das nicht auf, als Name eines Stücks wäre es der
      // eine, den man nicht lesen kann — und zwar der des besten.
      for (final rarity in GearRarity.values) {
        expect(
          kontrast(RarityBadge.colorOf(rarity), Palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: rarity.label,
        );
      }
    });

    test('jeder Rahmen hebt sich vom Leder ab', () {
      // Die Kacheln liegen auf Leder; dort muss der Rand zu sehen sein.
      for (final rarity in GearRarity.values) {
        expect(
          kontrast(RarityBadge.rahmenOf(rarity), Palette.background),
          greaterThanOrEqualTo(3),
          reason: rarity.label,
        );
      }
    });

    test('keine zwei Stufen teilen sich einen Rahmen', () {
      final rahmen = <int>{
        for (final rarity in GearRarity.values)
          RarityBadge.rahmenOf(rarity).toARGB32(),
      };

      expect(rahmen, hasLength(GearRarity.values.length));
    });

    test('der Name der höchsten Stufe ist nicht die Tinte', () {
      // Gold muss für Schrift dunkel sein, und dunkles Gold ist braun.
      // Es darf trotzdem nicht in der gewöhnlichen Schrift untergehen.
      expect(
        kontrast(RarityBadge.colorOf(GearRarity.legendary), Palette.text),
        greaterThan(1.5),
      );
    });
  });

  group('Die Marke im Laden', () {
    testWidgets('nennt die Stufe beim Namen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RarityBadge(rarity: GearRarity.rare)),
        ),
      );

      expect(find.text('Selten'), findsOneWidget);
    });

    testWidgets('ein gekauftes Stück blasst sie ab', (tester) async {
      // Sonst leuchtet die Marke über einer grauen Karte und zieht den
      // Blick auf etwas, das man schon hat.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                RarityBadge(rarity: GearRarity.rare),
                RarityBadge(rarity: GearRarity.rare, faded: true),
              ],
            ),
          ),
        ),
      );

      final marken = tester.widgetList<Text>(find.text('Selten')).toList();

      expect(marken, hasLength(2));
      expect(
        marken.first.style!.color!.a,
        greaterThan(marken.last.style!.color!.a),
      );
    });
  });

  group('Der Katalog trägt die Stufen', () {
    test('jedes Stück hat eine', () {
      for (final item in GearCatalog.all) {
        expect(GearRarity.values, contains(item.rarity), reason: item.name);
      }
    });

    test('die erste Preisstufe ist gewöhnlich', () {
      // Der Einstieg soll nicht nach etwas Besonderem aussehen — er ist
      // die Grundversorgung (`konzept.md` Abschnitt 4).
      final billigste = GearCatalog.all.toList()
        ..sort((a, b) => a.price.compareTo(b.price));

      expect(billigste.first.rarity, GearRarity.common);
    });
  });
}
