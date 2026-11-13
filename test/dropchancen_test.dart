import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/combat/widgets/dropchancen.dart';
import 'package:lifes_game/gear/weapon_ability_line.dart';

import 'test_view.dart';

/// Was auf der nächsten Etage fällt, und wie ein Grundangriff sich
/// beschreibt (13.11.2026).
void main() {
  testWidgets('der Eingang zeigt die Dropchancen der nächsten Etage', (
    tester,
  ) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LadderScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DropchancenKnopf.knopfKey));
    await tester.pumpAndSettle();

    expect(find.byType(DropchancenDialog), findsOneWidget);
    expect(find.text('Beute auf Etage 1'), findsOneWidget);
    // Etage 1: Gegner 70 / 25 / 5, der Boss eine Stufe höher: 70 / 30.
    expect(find.text('70 %'), findsNWidgets(2));
    expect(find.text('25 %'), findsOneWidget);
    expect(find.text('5 %'), findsOneWidget);
    expect(find.text('30 %'), findsOneWidget);
    // Was es hier nicht gibt, steht als Strich da.
    expect(find.text('—'), findsNWidgets(5));
  });

  group('Der Grundangriff in Worten', () {
    test('zwei Treffer nennen beide und den Anteil je Treffer', () {
      expect(
        weaponKampfText(PitWeapons.doppelstich),
        'Trifft 2-mal pro Schlag, jeder Treffer mit 60 % deines '
        'Angriffsschadens. Rund 2 Schläge pro Sekunde.',
      );
    });

    test('ein Stab schlägt mit der Fähigkeitsstärke', () {
      final stab = <PitWeapon>[
        for (final waffe in PitWeapons.all)
          if (waffe.fs >= 1) waffe,
      ].first;
      expect(weaponKampfText(stab), contains('deiner Fähigkeitsstärke'));
    });

    test('die Seltenheit steht als Satz da, nur bei Waffe und Rüstung', () {
      for (final item in GearCatalog.all) {
        final satz = rarityKampfText(item);
        final mitFaktor =
            item.rarity != GearRarity.common &&
            (item.slot == GearSlot.waffe || item.slot == GearSlot.ruestung);
        expect(satz != null, mitFaktor, reason: item.name);
      }
      final waffe = GearCatalog.forSlot(
        GearSlot.waffe,
      ).firstWhere((i) => i.rarity == GearRarity.uncommon);
      expect(rarityKampfText(waffe), 'Ungewöhnlich: +15 % Schaden im Kampf');
    });
  });
}
