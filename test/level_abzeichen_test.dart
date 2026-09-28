import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/ui/level_abzeichen.dart';
import 'package:progression/progression.dart';

/// Welcher Rahmen um das Level liegt: je zehn Level einer.
void main() {
  test('je zehn Level ein Rahmen, ab 40 der letzte', () {
    expect(LevelRahmen.fuer(1), LevelRahmen.holz);
    expect(LevelRahmen.fuer(9), LevelRahmen.holz);
    expect(LevelRahmen.fuer(10), LevelRahmen.bronze);
    expect(LevelRahmen.fuer(19), LevelRahmen.bronze);
    expect(LevelRahmen.fuer(20), LevelRahmen.silber);
    expect(LevelRahmen.fuer(30), LevelRahmen.gold);
    expect(LevelRahmen.fuer(40), LevelRahmen.edelstein);
    expect(LevelRahmen.fuer(LevelCurve.maxLevel), LevelRahmen.edelstein);
  });

  test('ein höherer Rahmen ist auch ohne Farbe zu erkennen', () {
    // Jede Stufe hat mehr Nieten als die davor. Holz und Bronze sahen
    // ohne Nieten fast gleich aus.
    for (var i = 1; i < LevelRahmen.values.length; i++) {
      expect(
        LevelRahmen.values[i].nieten,
        greaterThan(LevelRahmen.values[i - 1].nieten),
      );
    }
  });
}
