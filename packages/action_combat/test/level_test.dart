import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

void main() {
  group('Der Hallen-Katalog', () {
    test('jede Halle trägt', () {
      for (final level in LevelCatalog.all) {
        expect(level.problems, isEmpty, reason: level.name);
      }
    });

    test('die Grube hat genau einen Endgegner und reichlich Fussvolk', () {
      final grube = LevelCatalog.grube;

      expect(
        grube.spawns.where((s) => s.kind == EnemyKind.endgegner),
        hasLength(1),
      );
      expect(grube.trashCount, greaterThanOrEqualTo(20));
    });

    test('der Start liegt auf Boden, nicht in einer Wand', () {
      for (final level in LevelCatalog.all) {
        expect(
          level.isWallAtPoint(level.heroStart),
          isFalse,
          reason: level.name,
        );
      }
    });
  });

  group('Karten lesen', () {
    test('Zeichen werden zu Feldern und Gegnern', () {
      final level = Level.parse('Probe', const <String>[
        '#####',
        '#@.e#',
        '#..B#',
        '#####',
      ]);

      expect(level.width, 5);
      expect(level.height, 4);
      expect(level.isWallAt(0, 0), isTrue);
      expect(level.isWallAt(2, 1), isFalse);
      expect(level.spawns, hasLength(2));
      expect(level.trashCount, 1);
      expect(level.problems, isEmpty);
    });

    test('kürzere Zeilen werden mit Wand aufgefüllt', () {
      final level = Level.parse('Probe', const <String>[
        '#####',
        '#@.e#',
        '#..B',
        '#####',
      ]);

      expect(level.isWallAt(4, 2), isTrue);
      expect(level.problems, isEmpty);
    });

    test('ein unbekanntes Zeichen wirft', () {
      expect(
        () => Level.parse('Probe', const <String>['##', '#x']),
        throwsArgumentError,
      );
    });

    test('ohne Start wirft sie auch', () {
      expect(
        () => Level.parse('Probe', const <String>['####', '#..#', '####']),
        throwsArgumentError,
      );
    });
  });

  group('Was die Gesundheitsprüfung findet', () {
    test('einen eingemauerten Gegner', () {
      // Der Gegner rechts steht hinter einer durchgehenden Wand. Im
      // Spiel würde der Lauf nie enden — er ist nicht zu erreichen.
      final level = Level.parse('Eingemauert', const <String>[
        '#######',
        '#@.#e.#',
        '#..#..#',
        '#..#.B#',
        '#######',
      ]);

      expect(
        level.problems.any((p) => p.contains('eingemauert')),
        isTrue,
        reason: level.problems.toString(),
      );
    });

    test('eine offene Aussenwand', () {
      final level = Level.parse('Offen', const <String>[
        '#####',
        '#@.e.',
        '#..B#',
        '#####',
      ]);

      expect(
        level.problems.any((p) => p.contains('offen')),
        isTrue,
        reason: level.problems.toString(),
      );
    });

    test('einen fehlenden Endgegner', () {
      final level = Level.parse('Ohne Boss', const <String>[
        '#####',
        '#@.e#',
        '#...#',
        '#####',
      ]);

      expect(
        level.problems.any((p) => p.contains('Endgegner')),
        isTrue,
        reason: level.problems.toString(),
      );
    });
  });
}
