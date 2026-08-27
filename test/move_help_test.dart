import 'package:combat/combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/move_help.dart';

/// Die Erklärung hinter dem langen Druck auf einen Move-Knopf.
///
/// Geprüft wird vor allem eines: dass die **Zahlen aus dem Move kommen**
/// und nicht im Text stehen. Ein Hilfetext mit abgeschriebenen Zahlen ist
/// eine zweite Wahrheit, und die driftet — dieselbe Falle, die in dieser
/// Woche schon zweimal zugeschnappt hat.
void main() {
  group('Jeder Zug lässt sich erklären', () {
    test('alle fünfzehn Fähigkeiten haben einen Text', () {
      for (final move in AbilityMoves.all) {
        final hilfe = moveHelpFor(move, 16);

        expect(hilfe.effect, isNotEmpty, reason: '${move.name} ohne Wirkung');
        expect(
          hilfe.perfect,
          isNotNull,
          reason: '${move.name} sagt nicht, was Perfect bringt',
        );
      }
    });

    test('auch jede Waffe', () {
      for (final move in Moves.all) {
        expect(moveHelpFor(move, 16).effect, isNotEmpty);
      }
    });

    test('ein unbekannter Move bekommt wenigstens seine Zahlen', () {
      const fremd = Move(
        id: 'gibt-es-nicht',
        name: 'X',
        power: 2,
        energyDelta: 0,
      );

      expect(moveHelpFor(fremd, 10).effect, contains('20'));
    });
  });

  group('Die Zahlen hängen am Angriffswert', () {
    test('derselbe Zug erklärt sich bei mehr Angriff anders', () {
      final schwach = moveHelpFor(AbilityMoves.donnerkeil, 13).effect;
      final stark = moveHelpFor(AbilityMoves.donnerkeil, 20).effect;

      expect(schwach, isNot(stark));
    });

    test('die Vorlage trifft bei Angriff 16 ihre eigenen Zahlen', () {
      // Die Vorlage rechnet mit Angriff 16 — dort muss Donnerkeil seine
      // 34 und seine 48 zeigen, sonst stimmt die Umrechnung aus ADR-0022
      // nicht mehr.
      final hilfe = moveHelpFor(AbilityMoves.donnerkeil, 16);

      expect(hilfe.effect, contains('34'));
      expect(hilfe.perfect, contains('48'));
    });

    test('Funkenstoss ebenso: 12 und 18', () {
      final hilfe = moveHelpFor(AbilityMoves.funkenstoss, 16);

      expect(hilfe.effect, contains('12'));
      expect(hilfe.perfect, contains('18'));
    });

    test('Sternenfall nennt auch, was Verfehlen kostet', () {
      final hilfe = moveHelpFor(AbilityMoves.sternenfall, 16);

      expect(hilfe.effect, contains('60'));
      expect(hilfe.effect, contains('24'));
      expect(hilfe.perfect, contains('85'));
    });

    test('Blütentau heilt 20, perfekt 28', () {
      final hilfe = moveHelpFor(AbilityMoves.bluetentau, 16);

      expect(hilfe.effect, contains('20'));
      expect(hilfe.perfect, contains('28'));
    });
  });

  group('Die Wirkungen werden abgelesen, nicht abgeschrieben', () {
    test('Steinhaut nennt beide Minderungen', () {
      final hilfe = moveHelpFor(AbilityMoves.steinhaut, 16);

      // effects: ReduceIncoming(0.6) -> −40 %, perfect: 0.4 -> −60 %
      expect(hilfe.effect, contains('40'));
      expect(hilfe.perfect, contains('60'));
    });

    test('Prisma-Barriere nennt beide Anteile', () {
      final hilfe = moveHelpFor(AbilityMoves.prismaBarriere, 16);

      expect(hilfe.effect, contains('30'));
      expect(hilfe.perfect, contains('50'));
    });

    test('Klingenwirbel nennt die Zahl seiner Treffer', () {
      final hilfe = moveHelpFor(AbilityMoves.klingenwirbel, 16);

      expect(hilfe.effect, contains('${AbilityMoves.klingenwirbel.hits}'));
    });

    test('Aurastrom rechnet die Perfect-Energie zusammen', () {
      // +3 aus energyDelta, +2 aus GainEnergy -> 5, wie in der Vorlage.
      final hilfe = moveHelpFor(AbilityMoves.aurastrom, 16);

      expect(hilfe.effect, contains('+3'));
      expect(hilfe.perfect, contains('+5'));
    });
  });

  group('Umgebungen erklären sich aus ihren eigenen Werten', () {
    test('jede Umgebungsfähigkeit nennt Namen und Dauer', () {
      final paare = <Move, Environment>{
        AbilityMoves.frostnebel: Environments.frost,
        AbilityMoves.sandsturm: Environments.sandstorm,
        AbilityMoves.giftmoor: Environments.poisonBog,
        AbilityMoves.vulkanbruch: Environments.lava,
      };

      paare.forEach((move, feld) {
        final hilfe = moveHelpFor(move, 16);

        expect(hilfe.effect, contains(feld.name));
        expect(hilfe.effect, contains('${feld.remainingTurns}'));
      });
    });

    test('und die Perfect-Wirkung nennt die längere Dauer (ADR-0023)', () {
      final hilfe = moveHelpFor(AbilityMoves.giftmoor, 16);

      expect(hilfe.perfect, contains('5'));
      expect(hilfe.perfect, contains('4'));
    });

    test('Giftmoor nennt seine Steigerung', () {
      final hilfe = moveHelpFor(AbilityMoves.giftmoor, 16);

      // 5 pro Runde, steigend um 2 — beides aus environment.dart.
      expect(hilfe.effect, contains('5'));
      expect(hilfe.effect, contains('2'));
    });
  });
}
