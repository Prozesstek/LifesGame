import 'package:progression/progression.dart';
import 'package:test/test.dart';

/// Was ein Aufstieg bringt — die Zahlen hinter der Feier.
void main() {
  test('kein Aufstieg, wenn das Level gleich bleibt oder fällt', () {
    expect(LevelUp.between(4, 4).isLevelUp, isFalse);
    expect(LevelUp.between(5, 4).isLevelUp, isFalse);
    expect(LevelUp.between(4, 5).isLevelUp, isTrue);
  });

  test('ein Level: ein Theoriepunkt und der Faktor der Machtkurve', () {
    final auf = LevelUp.between(4, 5);

    expect(auf.theoryPoints, TheoryPoints.perLevel);
    expect(auf.powerGain, closeTo(PowerCurve.perLevel, 1e-9));
    expect(auf.newSlots, isEmpty);
  });

  test('der Sprung auf Level 3 öffnet den zweiten Platz', () {
    expect(LevelUp.between(2, 3).newSlots, <int>[2]);
  });

  test('mehrere Level auf einmal zählen alles dazwischen', () {
    final auf = LevelUp.between(2, 6);

    expect(auf.theoryPoints, 4 * TheoryPoints.perLevel);
    expect(
      auf.powerGain,
      closeTo(PowerCurve.factorFor(6) / PowerCurve.factorFor(2), 1e-9),
    );
    expect(auf.newSlots, <int>[2, 3]);
  });

  test('das Höchstlevel wird erkannt', () {
    expect(
      LevelUp.between(LevelCurve.maxLevel - 1, LevelCurve.maxLevel).isMax,
      isTrue,
    );
    expect(LevelUp.between(4, 5).isMax, isFalse);
  });
}
