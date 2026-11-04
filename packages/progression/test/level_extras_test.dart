import 'package:progression/progression.dart';
import 'package:test/test.dart';

/// Was erst mit einem Level aufgeht (ADR-0098).
void main() {
  test('das Haustier geht auf Level 5 auf, nicht vorher', () {
    expect(LevelExtra.haustier.offenAuf(4), isFalse);
    expect(LevelExtra.haustier.offenAuf(5), isTrue);
  });

  test('die Extras stehen aufsteigend und nie auf demselben Level', () {
    final level = <int>[for (final e in LevelExtra.values) e.level];
    expect(level, orderedEquals(<int>[...level]..sort()));
    expect(level.toSet(), hasLength(level.length));
  });

  test('kein Extra vor Level 3 — Level 2 gehört dem Mentor', () {
    // Auf Level 2 öffnen Charakter und der zweite Platz; der Weg des
    // Mentors endet etwa dort. Ein Extra daneben zöge ihm die Schau.
    for (final e in LevelExtra.values) {
      expect(e.level, greaterThanOrEqualTo(3), reason: e.name);
    }
  });

  test('ein Aufstieg nennt, was aufgeht — auch über mehrere Level', () {
    expect(LevelUp.between(4, 5).extras, <LevelExtra>[LevelExtra.haustier]);
    expect(LevelUp.between(2, 5).extras, <LevelExtra>[
      LevelExtra.lagerfeuer,
      LevelExtra.tagesdungeon,
      LevelExtra.haustier,
    ]);
    expect(LevelUp.between(5, 6).extras, isEmpty);
  });

  test('die Ultimate und die Meilensteine', () {
    expect(LevelUp.between(14, 15).opensUltimate, isTrue);
    expect(LevelUp.between(15, 16).opensUltimate, isFalse);
    expect(LevelUp.between(4, 5).isMilestone, isTrue);
    expect(LevelUp.between(8, 9).isMilestone, isFalse);
    expect(LevelUp.between(49, 50).isMilestone, isTrue);
  });

  test('aufLevel findet genau das Extra seines Levels', () {
    expect(LevelExtra.aufLevel(10), <LevelExtra>[LevelExtra.sammlung]);
    expect(LevelExtra.aufLevel(9), isEmpty);
  });
}
