import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/ability_buttons.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/pit_text.dart';
import 'package:lifes_game/audio/sound_effects.dart';

/// AktivesBretts zehn Fähigkeiten und zwei Ultimates in der App
/// (ADR-0074): ein Passiv hat im Kampf keinen Knopf, das Blatt nennt
/// jede neue Wirkung, und jede Id hat eine Bedingung.
void main() {
  const zehn = <String>[
    'zinseszins',
    'schattenschritt',
    'kampfrausch',
    'kriegsschrei',
    'spiegelbild',
    'parade',
    'ruhepuls',
    'kettenblitz',
    'rammbock',
    'zweiter_atem',
  ];

  test('jede der zehn ist wählbar und hat eine Bedingung', () {
    for (final id in zehn) {
      final ability = AbilityCatalog.byMoveId(id);
      expect(ability, isNotNull, reason: id);
      expect(ability!.requirement, isNotEmpty, reason: id);
    }
    for (final id in <String>['bestform', 'rueckspulen']) {
      expect(AbilityCatalog.ultimateByMoveId(id), isNotNull, reason: id);
    }
  });

  test('Spiegelbild ist episch', () {
    expect(AbilityCatalog.byMoveId('spiegelbild')?.rarity, Rarity.epic);
  });

  group('Das Blatt', () {
    test('ein Passiv nennt weder Mana noch Abklingzeit', () {
      final stats = pitAbilityStats(PitAbilities.kampfrausch);
      final labels = stats.map((s) => s.label).toList();
      expect(labels, isNot(contains('Mana')));
      expect(labels, isNot(contains('Abklingzeit')));
      expect(stats.first.value, contains('Passiv'));
      expect(labels, contains('Kampfrausch'));
    });

    test('jede neue Wirkung steht mit einer Zeile darin', () {
      // Mindestens eine Zeile mehr als Art, Kosten und Zielen — sonst
      // verschwiege das Blatt, was die Fähigkeit tut.
      for (final id in <String>[...zehn, 'bestform', 'rueckspulen']) {
        final ability = pitAbilityOf(id)!;
        final stats = pitAbilityStats(ability);
        final grundzeilen = ability.isPassive
            ? 1
            : (ability.isUltimate ? 3 : 4);
        expect(stats.length, greaterThan(grundzeilen), reason: id);
      }
    });
  });

  testWidgets('ein Passiv steht im Kampf, nimmt aber keinen Tipp an', (
    tester,
  ) async {
    final game = ActionGame(
      klang: const SilentSoundPlayer(),
      startXp: null,
      sim: ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.gereift,
        abilityIds: const <String>['steinhaut', 'kampfrausch'],
      ),
    );
    addTearDown(game.frame.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: AbilityButtons(game: game)),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Kampfrausch, passiv'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.bySemanticsLabel('Kampfrausch, passiv'),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });
}
