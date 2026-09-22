import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// Die Seltenheit vervielfacht im Kampf (ADR-0042).
void main() {
  test('gewöhnlich ist ×1, jede Stufe darüber mehr', () {
    expect(GearRarity.common.powerFactor, 1);
    for (var i = 1; i < GearRarity.values.length; i++) {
      expect(
        GearRarity.values[i].powerFactor,
        greaterThan(GearRarity.values[i - 1].powerFactor),
        reason: GearRarity.values[i].label,
      );
    }
  });

  test('legendär schlägt mehr als doppelt so hart', () {
    expect(GearRarity.legendary.powerFactor, greaterThanOrEqualTo(2));
  });
}
