import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/gear/gear_icon.dart';
import 'package:lifes_game/gear/widgets/laden_bild.dart';

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
    test('sie ist ein PNG in der vereinbarten Größe', () async {
      // **Früher stand hier „größer als 1000 Bytes".** Flache Pixelbilder
      // komprimieren darunter — die Grenze hat nichts über das Bild
      // gesagt, nur über den Zufall. Signatur und Kantenlänge sagen etwas.
      for (final id in GearIcons.itemIds) {
        final pfad = GearIcons.forItemId(id)!;

        // `rootBundle` findet nur, was in `pubspec.yaml` steht — der Test
        // prueft damit Datei **und** Anmeldung in einem Zug.
        final daten = await rootBundle.load(pfad);
        final bytes = daten.buffer.asUint8List(
          daten.offsetInBytes,
          daten.lengthInBytes,
        );

        expect(bytes.sublist(0, 8), <int>[
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ], reason: '$pfad ist kein PNG.');
        // IHDR: Breite und Höhe als Big-Endian-Zahlen ab Byte 16.
        final breite = daten.getUint32(16);
        final hoehe = daten.getUint32(20);
        expect(breite, GearIcons.assetSize, reason: pfad);
        expect(hoehe, GearIcons.assetSize, reason: pfad);
      }
    });
  });

  group('Wer ein Bild hat und wer nicht', () {
    // Seit dem 21.09. hat jedes Stück ein Bild aus dem Raven-Paket
    // (`assets/RAVEN.md`). Kommt ein Stück dazu, fällt dieser Test um,
    // bis es eins bekommt — sonst stünde es als einziges mit dem
    // Platz-Zeichen im Laden.
    test('jedes Stück im Katalog hat eins', () {
      for (final item in GearCatalog.all) {
        expect(GearIcons.forItemId(item.id), isNotNull, reason: item.name);
      }
    });

    test('jedes verdiente Stück hat eins', () {
      // **Die Sperre soll auf etwas hinführen, das man sieht.** Ein
      // gesperrtes Stück mit dem Platz-Symbol wäre ein Ziel ohne Bild.
      for (final item in GearCatalog.all) {
        if (!item.rarity.isGated) continue;

        expect(GearIcons.forItemId(item.id), isNotNull, reason: item.name);
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

  group('Tafel und Fächer liegen im Ladenbild', () {
    const bild = Rect.fromLTWH(0, 0, LadenBild.breite, LadenBild.hoehe);

    test('alles liegt innerhalb des Bildes', () {
      expect(bild.contains(LadenBild.tafel.topLeft), isTrue);
      expect(bild.contains(LadenBild.tafel.bottomRight), isTrue);
      for (final fach in LadenBild.faecher) {
        expect(fach.rahmen.left, greaterThanOrEqualTo(0));
        expect(fach.rahmen.right, lessThanOrEqualTo(LadenBild.breite));
        expect(fach.rahmen.bottom, lessThanOrEqualTo(LadenBild.hoehe));
        // Inneres und Planke liegen im Rahmen, die Planke darunter.
        expect(fach.rahmen.contains(fach.innen.center), isTrue);
        expect(fach.planke.top, greaterThanOrEqualTo(fach.innen.bottom));
      }
    });

    test('sechs Fächer, keine zwei überlappen, keins unter der Tafel', () {
      expect(LadenBild.faecher, hasLength(6));
      for (final (i, a) in LadenBild.faecher.indexed) {
        expect(a.rahmen.overlaps(LadenBild.tafel), isFalse);
        for (final b in LadenBild.faecher.skip(i + 1)) {
          expect(a.rahmen.overlaps(b.rahmen), isFalse);
        }
      }
    });

    test('ein Fach bleibt auf dem Handy bedienbar', () {
      // 390 Punkte Bildschirm: Unter 44 ist eine Tippfläche unzuverlässig.
      const skala = 390 / LadenBild.breite;
      for (final fach in LadenBild.faecher) {
        expect(fach.rahmen.width * skala, greaterThan(44));
      }
    });
  });
}
