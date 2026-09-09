import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/gear/gear_icon.dart';
import 'package:lifes_game/gear/widgets/shop_item_cell.dart';

/// Die Bilder auf den Item-Kacheln im Laden.
///
/// **Dieselben zwei Nähte wie bei `move_icon_test.dart`:** dass eine Id
/// wirklich im Katalog ankommt, und dass die Datei da **und** in
/// `pubspec.yaml` angemeldet ist. Ein Bild, das im Katalog steht und
/// nicht existiert, fällt sonst erst im Laden auf — als graues Kreuz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Jede eingetragene Id kommt im Katalog an', () {
    test('kein Bild zeigt auf ein Stück, das es nicht gibt', () {
      for (final id in GearIcons.itemIds) {
        expect(
          GearCatalog.all.any((item) => item.id == id),
          isTrue,
          reason: 'Fuer "$id" gibt es ein Bild, aber kein Ausruestungsstueck.',
        );
      }
    });
  });

  group('Jede eingetragene Datei ist wirklich da', () {
    test('sie lässt sich laden und ist nicht leer', () async {
      for (final id in GearIcons.itemIds) {
        final pfad = GearIcons.forItemId(id)!;

        // `rootBundle` findet nur, was in `pubspec.yaml` steht — der Test
        // prueft damit Datei **und** Anmeldung in einem Zug.
        final daten = await rootBundle.load(pfad);

        expect(
          daten.lengthInBytes,
          greaterThan(1000),
          reason: '$pfad ist verdaechtig klein.',
        );
      }
    });
  });

  group('Die meisten Stücke haben noch keins', () {
    // Issue #35 führt „Items" unter den Designs auf, die noch entstehen
    // müssen. Gezeichnet sind bisher zwei Klingen; die übrigen Kacheln
    // tragen das Zeichen ihres Platzes.
    test('zwei Stücke tragen eins, und beide sind Waffen', () {
      final mitBild = GearCatalog.all
          .where((item) => GearIcons.forItemId(item.id) != null)
          .toList();

      expect(mitBild, hasLength(2));
      for (final item in mitBild) {
        expect(item.slot, GearSlot.waffe);
      }
    });

    test('keine zwei Stücke teilen sich eine Zeichnung', () {
      // Zwei Ids auf dieselbe Datei zu legen wäre kein Fehler, den
      // irgendetwas meldet — im Laden stünden dann zwei verschiedene
      // Stücke mit demselben Bild nebeneinander.
      final pfade = <String>[];
      for (final id in GearIcons.itemIds) {
        pfade.add(GearIcons.forItemId(id)!);
      }

      expect(pfade.toSet(), hasLength(pfade.length));
    });

    test('eine unbekannte Id hat keins', () {
      expect(GearIcons.forItemId('gibt-es-nicht'), isNull);
    });

    test('jeder Platz hat solange ein Ersatzzeichen', () {
      // Ohne Bild trägt die Kachel das Zeichen ihres Platzes. Fiele eines
      // aus, stünde dort eine leere Fläche — und im Raster ließen sich
      // die Stücke nur noch am Namen unterscheiden.
      final zeichen = <IconData>{};
      for (final slot in GearSlot.values) {
        zeichen.add(GearIcons.fallbackFor(slot));
      }

      expect(zeichen, hasLength(GearSlot.values.length));
    });
  });

  group('Das Raster teilt die Breite', () {
    // 390 Pixel Bildschirm minus 16 Rand je Seite.
    const breite = 358.0;

    test('drei Kacheln füllen eine Reihe ganz aus', () {
      final seite = ShopItemCell.sideFor(breite);

      expect(
        seite * ShopItemCell.columns +
            ShopItemCell.gap * (ShopItemCell.columns - 1),
        closeTo(breite, 0.01),
      );
    });

    test('eine Kachel bleibt auf dem Handy bedienbar', () {
      // Unter 44 Pixeln ist eine Tippfläche auf einem Handy unzuverlässig
      // — und ein Name in zwei Zeilen passt dort ohnehin nicht mehr.
      expect(ShopItemCell.sideFor(breite), greaterThan(44));
    });
  });
}
