import 'package:combat/combat.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/move_icon.dart';

/// Die Bilder auf den Move-Knöpfen im Kampf.
///
/// **Zwei Nähte werden hier geprüft, und beide sind schon einmal
/// gerissen:** dass eine Id wirklich in `package:combat` ankommt (wie bei
/// `abilities_seam_test.dart`), und dass die Datei tatsächlich da ist.
/// Ein Bild, das im Katalog steht und nicht existiert, fällt sonst erst
/// im Kampf auf — als graues Kreuz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Jede eingetragene Id kommt in combat an', () {
    test('kein Bild zeigt auf einen Zug, den es nicht gibt', () {
      for (final id in MoveIcons.moveIds) {
        expect(
          Moves.byId(id),
          isNotNull,
          reason: 'Fuer "$id" gibt es ein Bild, aber keinen Move.',
        );
      }
    });

    test('und jedes gehört zu einer wählbaren Fähigkeit', () {
      for (final id in MoveIcons.moveIds) {
        expect(
          AbilityMoves.all.any((m) => m.id == id),
          isTrue,
          reason: '"$id" ist keine Faehigkeit aus dem Set.',
        );
      }
    });
  });

  group('Jede eingetragene Datei ist wirklich da', () {
    test('sie lässt sich laden und ist nicht leer', () async {
      for (final id in MoveIcons.moveIds) {
        final pfad = MoveIcons.forMoveId(id)!;

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

  group('Derzeit gibt es keine Bilder', () {
    // Die vier Umgebungen hatten am 27.08. eines und haben es wieder
    // verloren; das Kachelformat ist geblieben. Die Prüfungen oben laufen
    // dadurch über eine leere Menge — sie greifen wieder, sobald jemand
    // eine Zeile in `MoveIcons` ergänzt, und genau dafür bleiben sie
    // stehen.
    test('kein einziger Zug trägt eins', () {
      for (final move in <Move>[...Moves.all, ...AbilityMoves.all]) {
        expect(
          MoveIcons.forMoveId(move.id),
          isNull,
          reason: '${move.name} hat ein Bild, aber keins ist abgelegt.',
        );
      }
    });

    test('eine unbekannte Id ebenfalls nicht', () {
      expect(MoveIcons.forMoveId('gibt-es-nicht'), isNull);
    });
  });

  group('Die Kacheln teilen sich eine Reihe', () {
    // 390 Pixel Bildschirm minus 16 Rand je Seite.
    const breite = 358.0;

    test('alle vier passen nebeneinander', () {
      final seite = MoveIcons.tileSideFor(breite, 4);

      expect(seite * 4 + MoveIcons.gap * 3, lessThanOrEqualTo(breite));
      expect(seite, greaterThan(70));
    });

    test('vier Kacheln füllen die Breite ganz aus', () {
      final seite = MoveIcons.tileSideFor(breite, 4);

      expect(seite * 4 + MoveIcons.gap * 3, closeTo(breite, 0.01));
    });

    test('bei weniger Zügen greift die Obergrenze', () {
      // Sonst würden zwei Kacheln je 174 Pixel breit — und damit auch 174
      // hoch. Genau diese Höhe soll der Arena bleiben.
      expect(MoveIcons.tileSideFor(breite, 1), MoveIcons.maxTileSide);
      expect(MoveIcons.tileSideFor(breite, 2), MoveIcons.maxTileSide);
    });

    test('in einem breiten Fenster ebenfalls', () {
      // Ohne Deckel wüchsen die Kacheln mit der Fensterbreite mit und
      // liefen in der Höhe über — die Kachel ist quadratisch, ihre Breite
      // bestimmt also ihre Höhe.
      expect(MoveIcons.tileSideFor(1200, 4), MoveIcons.maxTileSide);
    });

    test('auf einem sehr schmalen Gerät bleibt sie bedienbar', () {
      expect(MoveIcons.tileSideFor(120, 4), greaterThanOrEqualTo(40));
    });

    test('ohne Züge gibt es nichts zu rechnen', () {
      expect(MoveIcons.tileSideFor(breite, 0), 0);
    });
  });
}
