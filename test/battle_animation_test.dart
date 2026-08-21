import 'package:combat/combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/battle/move_animation.dart';

/// Prüft die Zuordnung Move → Animation.
///
/// Das ist die einzige Stelle der Kampfdarstellung, die sich ohne Renderer
/// prüfen lässt — und die einzige, an der ein Fehler still bleibt: Ein Move
/// ohne Eintrag fällt nicht auf, er sieht nur langweilig aus. Deshalb steht
/// hier ein Test und nicht bei den gezeichneten Figuren (CLAUDE.md:
/// „flame_test nur wo unvermeidbar").
void main() {
  group('Jeder Move hat eine Darstellung', () {
    test('für jeden Move im Standard-Set gibt es eine Animation', () {
      for (final move in Moves.defaultLoadout) {
        final animation = MoveAnimation.forMove(move);

        expect(animation.impact, greaterThan(0), reason: move.id);
        expect(
          animation.duration,
          greaterThan(animation.impact),
          reason: move.id,
        );
      }
    });

    test('der Einschlag kommt nie vor der Ausholbewegung', () {
      // Andernfalls flöge der Pfeil rückwärts durch die Zeit: Das Zucken
      // des Getroffenen hängt an `impact`, der Abschuss an `windUp`.
      for (final move in Moves.defaultLoadout) {
        final animation = MoveAnimation.forMove(move);

        expect(
          animation.impact,
          greaterThanOrEqualTo(animation.windUp),
          reason: move.id,
        );
      }
    });

    test('ein unbekannter Move fällt auf den Nahkampf zurück', () {
      // Sichtbar statt unsichtbar: Ein Move ohne Eintrag soll trotzdem
      // etwas tun.
      final animation = MoveAnimation.forId('gibtsnicht');

      expect(animation.kind, MoveVisual.melee);
      expect(animation.impact, greaterThan(0));
    });
  });

  group('Der Bogenschuss', () {
    test('ist das einzige Geschoss im Standard-Set', () {
      final projectiles = Moves.defaultLoadout
          .where((move) => MoveAnimation.forMove(move).isProjectile)
          .toList();

      expect(projectiles, hasLength(1));
      expect(projectiles.single.id, Moves.basicAttack.id);
    });

    test('lässt dem Pfeil Zeit zu fliegen', () {
      // windUp ist der Abschuss, impact der Einschlag. Die Differenz ist
      // die Flugzeit -- ist sie null, steht der Pfeil im Bild und
      // verschwindet sofort wieder.
      const bow = MoveAnimation.bow;
      final flight = bow.impact - bow.windUp;

      expect(flight, greaterThan(0.2));
    });

    test('hängt an der Id, nicht am Namen', () {
      // Der Move heißt „Bogenschuss", aber die Zuordnung darf das nicht
      // benutzen: Namen sind Anzeigetext und dürfen sich ändern.
      expect(MoveAnimation.forId('basic_attack').isProjectile, isTrue);
      expect(MoveAnimation.forId('Bogenschuss').isProjectile, isFalse);
    });
  });
}
