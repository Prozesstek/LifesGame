import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/pit_run_view.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/dev/dev_controller.dart';
import 'package:lifes_game/dev/grube_werkbank.dart';
import 'package:lifes_game/dev/save_slot.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Die Werkbank in der Grube: Funde und Gegner von Hand, nur auf dem
/// Dev-Stand.
void main() {
  Future<void> hinab(WidgetTester tester, SaveSlot slot) async {
    usePhoneView(tester);
    final container = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(const SaveData()),
        activeSlotProvider.overrideWithValue(slot),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PitScreen(stage: PitStage(2))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  ActionGame spielVon(WidgetTester tester) =>
      tester.widget<PitRunView>(find.byType(PitRunView)).game;

  testWidgets('auf dem echten Stand gibt es keine Werkbank', (tester) async {
    await hinab(tester, SaveSlot.real);
    expect(find.byKey(GrubeWerkbank.knopfKey), findsNothing);
  });

  testWidgets('auf dem Dev-Stand legt sie Legendäres und beschwört Gegner', (
    tester,
  ) async {
    await hinab(tester, SaveSlot.dev);
    final spiel = spielVon(tester);

    await tester.tap(find.byKey(GrubeWerkbank.knopfKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(spiel.paused, isTrue, reason: 'der Lauf steht still');

    await tester.tap(find.byKey(GrubeWerkbank.fundKey(GearRarity.legendary)));
    await tester.tap(find.byKey(GrubeWerkbank.gegnerKey(EnemyKind.grimlock)));
    await tester.pump();

    // Das Blatt schliessen: ein Tipp auf den Schleier darüber.
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(spiel.paused, isFalse);

    expect(
      spiel.sim.views.where((v) => v.kind == EnemyKind.grimlock),
      isNotEmpty,
    );
    final nth = spiel.sim.itemsDropped;
    expect(nth, greaterThan(0));
    expect(spiel.funde!.fund(nth)?.item?.rarity, GearRarity.legendary);
  });
}
