import 'package:progression/progression.dart';
import 'package:test/test.dart';

/// Das Level vervielfacht im Kampf (ADR-0042).
void main() {
  test('Level 1 ist ×1, danach wächst es mit jedem Level', () {
    expect(PowerCurve.factorFor(1), 1);
    for (var level = 2; level <= LevelCurve.maxLevel; level++) {
      expect(
        PowerCurve.factorFor(level),
        greaterThan(PowerCurve.factorFor(level - 1)),
      );
    }
  });

  test('die Grössenordnung aus dem ADR: ×1,7 auf 15, ×6,8 auf 50', () {
    expect(PowerCurve.factorFor(15), closeTo(1.73, 0.01));
    expect(PowerCurve.factorFor(50), closeTo(6.83, 0.01));
  });

  test('ausserhalb der Kurve wird auf den Rand gezogen', () {
    expect(PowerCurve.factorFor(0), 1);
    expect(PowerCurve.factorFor(99), PowerCurve.factorFor(LevelCurve.maxLevel));
  });
}
