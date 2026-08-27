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

  group('Die vier Umgebungen haben ihr Bild', () {
    test('Frostnebel, Sandsturm, Giftmoor und Vulkanbruch', () {
      for (final move in <Move>[
        AbilityMoves.frostnebel,
        AbilityMoves.sandsturm,
        AbilityMoves.giftmoor,
        AbilityMoves.vulkanbruch,
      ]) {
        expect(
          MoveIcons.forMoveId(move.id),
          isNotNull,
          reason: '${move.name} hat kein Bild bekommen.',
        );
      }
    });

    test('jede Fähigkeit, die eine Umgebung legt, hat auch eins', () {
      // Die eigentliche Aussage: Es sind genau die Umgebungsleger. Kommt
      // eine fuenfte Umgebung dazu, faellt das hier auf.
      final leger = <Move>[
        for (final move in AbilityMoves.all)
          if (move.effects.any((e) => e is SetEnvironment)) move,
      ];

      expect(leger, hasLength(4));
      for (final move in leger) {
        expect(MoveIcons.forMoveId(move.id), isNotNull);
      }
    });
  });

  group('Wer kein Bild hat, bekommt keins', () {
    test('die Waffen und die übrigen Fähigkeiten bleiben ohne', () {
      expect(MoveIcons.forMoveId(Moves.basicAttack.id), isNull);
      expect(MoveIcons.forMoveId(Moves.swordStrike.id), isNull);
      expect(MoveIcons.forMoveId(AbilityMoves.donnerkeil.id), isNull);
      expect(MoveIcons.forMoveId(AbilityMoves.steinhaut.id), isNull);
    });

    test('eine unbekannte Id ebenfalls nicht', () {
      expect(MoveIcons.forMoveId('gibt-es-nicht'), isNull);
    });
  });

  group('Die Kachel ist quadratisch und teilt sich die Breite', () {
    test('zwei Kacheln plus Abstand füllen die Reihe', () {
      const breite = 358.0; // 390 minus 16 Rand je Seite

      final seite = MoveIcons.tileSideFor(breite);

      expect(seite * 2 + MoveIcons.gap, closeTo(breite, 0.01));
    });

    test('auf einem Handy greift die Obergrenze nicht', () {
      expect(MoveIcons.tileSideFor(358), lessThan(MoveIcons.maxTileSide));
    });

    test('in einem breiten Fenster schon', () {
      // Ohne Deckel wüchsen die Kacheln mit der Fensterbreite mit und
      // liefen in der Höhe über — die Kachel ist quadratisch, ihre Breite
      // bestimmt also ihre Höhe.
      expect(MoveIcons.tileSideFor(1200), MoveIcons.maxTileSide);
    });

    test('und auf einem sehr schmalen Gerät bleibt sie bedienbar', () {
      expect(MoveIcons.tileSideFor(60), greaterThanOrEqualTo(48));
    });
  });
}
