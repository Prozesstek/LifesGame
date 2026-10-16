import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/combat/widgets/eingangs_glut.dart';
import 'package:lifes_game/gear/widgets/rarity_badge.dart';

/// Der Schlund im Eingang glüht in der Farbe dessen, was unten fällt.
void main() {
  test('die Farbe folgt den Sperren im Laden', () {
    expect(GlutStufe.fuer(1), GlutStufe.feuer);
    expect(GlutStufe.fuer(GearGates.epicRung - 1), GlutStufe.feuer);
    expect(GlutStufe.fuer(GearGates.epicRung), GlutStufe.episch);
    expect(GlutStufe.fuer(GearGates.legendaryRung), GlutStufe.legendaer);
    expect(GlutStufe.fuer(PitStage.referenceStage), GlutStufe.legendaer);
    expect(GlutStufe.fuer(PitStage.referenceStage + 1), GlutStufe.mythisch);
    expect(GlutStufe.fuer(PitStage.count), GlutStufe.mythisch);
  });

  test('episch und legendär tragen den Rand ihrer Seltenheit', () {
    expect(GlutStufe.episch.farbe, RarityBadge.rahmenOf(GearRarity.epic));
    expect(
      GlutStufe.legendaer.farbe,
      RarityBadge.rahmenOf(GearRarity.legendary),
    );
  });

  test('je tiefer, desto mehr Glut', () {
    for (var i = 1; i < GlutStufe.values.length; i++) {
      expect(
        GlutStufe.values[i].funken,
        greaterThan(GlutStufe.values[i - 1].funken),
      );
    }
  });

  testWidgets('in Tests steht er still, die Zahl davor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EingangsGlut(ebene: 31, child: Text('31'))),
      ),
    );
    // Käme er nie zur Ruhe, liefe pumpAndSettle in die Zeitgrenze.
    await tester.pumpAndSettle();
    expect(find.text('31'), findsOneWidget);
  });
}
