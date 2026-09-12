import 'package:combat/combat.dart';
import 'package:test/test.dart';

/// Die Spur „Niederlagen je Sprosse" aus ADR-0033.
///
/// Sie ist der Grund, warum „der Unbeugsame" ueberhaupt bestimmbar ist:
/// Bis hierher hielt der Stand nur den hoechsten Sieg, eine Niederlage
/// stand nirgends.
void main() {
  group('Zaehlen', () {
    test('ein frischer Stand hat keine', () {
      const stand = LadderProgress.empty();
      expect(stand.defeatsAt(1), 0);
      expect(stand.comebackVictoriesAfter(3), 0);
    });

    test('eine Niederlage wird der richtigen Sprosse zugeschrieben', () {
      final stand = const LadderProgress.empty().recordDefeat(7);

      expect(stand.defeatsAt(7), 1);
      expect(stand.defeatsAt(6), 0);
      expect(stand.highestDefeated, 0);
    });

    test('mehrere Niederlagen summieren sich', () {
      var stand = const LadderProgress.empty();
      for (var i = 0; i < 4; i++) {
        stand = stand.recordDefeat(3);
      }
      expect(stand.defeatsAt(3), 4);
    });

    test('eine Sprosse ausserhalb der Reihe wird nicht gezaehlt', () {
      var stand = const LadderProgress.empty();
      stand = stand.recordDefeat(0);
      stand = stand.recordDefeat(Enemies.rungs + 1);
      stand = stand.recordDefeat(-5);

      expect(stand.defeats, isEmpty);
    });

    test('ein Sieg nimmt die Niederlagen nicht mit', () {
      var stand = const LadderProgress.empty();
      stand = stand.recordDefeat(1).recordDefeat(1);
      stand = stand.defeat(1);

      expect(stand.highestDefeated, 1);
      expect(stand.defeatsAt(1), 2);
    });
  });

  group('Der Unbeugsame', () {
    test('drei Niederlagen ohne Sieg zaehlen nicht', () {
      var stand = const LadderProgress.empty();
      for (var i = 0; i < 3; i++) {
        stand = stand.recordDefeat(1);
      }

      expect(stand.comebackVictoriesAfter(3), 0);
    });

    test('ein Sieg nach zwei Niederlagen zaehlt nicht', () {
      var stand = const LadderProgress.empty();
      stand = stand.recordDefeat(1).recordDefeat(1).defeat(1);

      expect(stand.comebackVictoriesAfter(3), 0);
    });

    test('ein Sieg nach drei Niederlagen zaehlt', () {
      var stand = const LadderProgress.empty();
      for (var i = 0; i < 3; i++) {
        stand = stand.recordDefeat(1);
      }
      stand = stand.defeat(1);

      expect(stand.comebackVictoriesAfter(3), 1);
    });

    test('zwei zaehe Sprossen zaehlen doppelt', () {
      var stand = const LadderProgress.empty();
      for (var i = 0; i < 3; i++) {
        stand = stand.recordDefeat(1);
      }
      stand = stand.defeat(1);
      for (var i = 0; i < 5; i++) {
        stand = stand.recordDefeat(2);
      }
      stand = stand.defeat(2);

      expect(stand.comebackVictoriesAfter(3), 2);
    });

    // Die Bedingung darf nie wieder wegfallen (ADR-0033, Punkt 3). Beide
    // Groessen, aus denen sie sich ergibt, steigen nur.
    test('weiterer Fortschritt nimmt sie nicht weg', () {
      var stand = const LadderProgress.empty();
      for (var i = 0; i < 3; i++) {
        stand = stand.recordDefeat(1);
      }
      stand = stand.defeat(1);
      expect(stand.comebackVictoriesAfter(3), 1);

      for (var rung = 2; rung <= 6; rung++) {
        stand = stand.defeat(rung);
      }
      expect(stand.comebackVictoriesAfter(3), 1);
      expect(stand.highestDefeated, 6);
    });
  });

  group('Speichern und Laden', () {
    test('die Niederlagen ueberleben', () {
      var stand = const LadderProgress.empty();
      stand = stand.recordDefeat(4).recordDefeat(4).recordDefeat(9);
      stand = stand.defeat(1);

      final geladen = LadderProgress.fromJson(stand.toJson());

      expect(geladen.defeatsAt(4), 2);
      expect(geladen.defeatsAt(9), 1);
      expect(geladen.highestDefeated, 1);
      expect(geladen, stand);
    });

    test('ein Stand ohne Niederlagen sieht aus wie vor ADR-0033', () {
      final json = const LadderProgress(highestDefeated: 3).toJson();
      expect(json.containsKey('defeats'), isFalse);
    });

    test('ein alter Stand laedt unveraendert', () {
      final geladen = LadderProgress.fromJson(<String, Object?>{'defeated': 5});

      expect(geladen.highestDefeated, 5);
      expect(geladen.defeats, isEmpty);
    });

    test('Unbrauchbares wird uebersprungen, nicht geworfen', () {
      final geladen = LadderProgress.fromJson(<String, Object?>{
        'defeated': 2,
        'defeats': <String, Object?>{
          '3': 2,
          'quatsch': 4,
          '0': 9,
          '999': 1,
          '5': 'viele',
          '6': -1,
        },
      });

      expect(geladen.defeatsAt(3), 2);
      expect(geladen.defeats, hasLength(1));
      expect(geladen.highestDefeated, 2);
    });

    test('Niederlagen ueberleben auch eine kaputte Sprossenzahl', () {
      final geladen = LadderProgress.fromJson(<String, Object?>{
        'defeated': 'kaputt',
        'defeats': <String, Object?>{'2': 3},
      });

      expect(geladen.highestDefeated, 0);
      expect(geladen.defeatsAt(2), 3);
    });
  });
}
