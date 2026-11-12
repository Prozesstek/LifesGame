import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/neu/neu_gesehen.dart';
import 'package:lifes_game/neu/neu_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// **Der gelbe Punkt für Neues** (11.11.2026): am Kreis, bis er geöffnet
/// ist; innen am Neuen, bis es angetippt ist.
void main() {
  const heute = Day(2026, 10, 20);
  final klinge = GearCatalog.byId('gear-uebungsklinge')!;
  GearCopy stueck(String uid) => GearCopy(
    uid: uid,
    itemId: klinge.id,
    bonus: klinge.bonus.scaled,
    paid: 0,
  );

  ProviderContainer stand(SaveData save, {bool tutorial = false}) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(save),
        todayProvider.overrideWithValue(heute),
        if (!tutorial)
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('NeuGesehen', () {
    test('wirft heraus, was es nicht mehr gibt', () {
      const alt = NeuGesehen(marken: <String>{'laden:1', 'stueck:a'});
      final neu = alt.sieh(
        <String>['laden:2'],
        alle: <String>{'stueck:a', 'laden:2'},
      );
      expect(neu.marken, <String>{'stueck:a', 'laden:2'});
    });

    test('überlebt JSON und ist nachsichtig', () {
      const g = NeuGesehen(marken: <String>{'a'}, angetippt: <String>{'b'});
      final zurueck = NeuGesehen.fromJson(g.toJson());
      expect(zurueck.marken, g.marken);
      expect(zurueck.angetippt, g.angetippt);
      expect(NeuGesehen.fromJson('Unsinn').marken, isEmpty);
      final save = SaveData.decode(SaveData(neu: g).encode());
      expect(save.neu?.angetippt, <String>{'b'});
    });
  });

  group('am Kreis', () {
    test('ein alter Stand hat alles schon gesehen', () {
      final c = stand(
        SaveData(loadout: const Loadout.empty().addFree(stueck('a'))),
      );
      for (final ort in NeuOrt.values) {
        expect(c.read(neuAmOrtProvider(ort)), isFalse, reason: '$ort');
      }
      expect(c.read(neuInnenProvider(stueckMarke('a'))), isFalse);
    });

    test('ein neues Stück: Punkt am Kreis, bis er geöffnet ist', () {
      final c = stand(
        SaveData(
          neu: const NeuGesehen(),
          loadout: const Loadout.empty().addFree(stueck('neu')),
        ),
      );

      expect(c.read(neuAmOrtProvider(NeuOrt.ausruestung)), isTrue);
      c.read(neuGesehenProvider.notifier).sieh(NeuOrt.ausruestung);
      expect(c.read(neuAmOrtProvider(NeuOrt.ausruestung)), isFalse);

      // Innen bleibt er, bis das Stück angetippt ist.
      expect(c.read(neuInnenProvider(stueckMarke('neu'))), isTrue);
      c.read(neuGesehenProvider.notifier).tippe(stueckMarke('neu'));
      expect(c.read(neuInnenProvider(stueckMarke('neu'))), isFalse);
    });

    test('der Laden ist jeden Tag neu', () {
      final c = stand(const SaveData(neu: NeuGesehen()));
      expect(c.read(neuAmOrtProvider(NeuOrt.laden)), isTrue);
      c.read(neuGesehenProvider.notifier).sieh(NeuOrt.laden);
      expect(c.read(neuAmOrtProvider(NeuOrt.laden)), isFalse);
    });

    test('im Tutorial steht kein Punkt — dort zeigt der Mentor', () {
      final c = stand(const SaveData(neu: NeuGesehen()), tutorial: true);
      expect(c.read(ersterStartProvider).schritt, isNotNull);
      for (final ort in NeuOrt.values) {
        expect(c.read(neuAmOrtProvider(ort)), isFalse, reason: '$ort');
      }
    });
  });

  testWidgets('der Kreis trägt den Punkt, ein Tipp nimmt ihn', (tester) async {
    useTallView(tester);
    final c = stand(const SaveData(neu: NeuGesehen()));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final laden = find.byKey(HubCircle.keyFor('Laden'));
    final punkt = find.descendant(
      of: laden,
      matching: find.byKey(HubCircle.neuKey),
    );
    expect(punkt, findsOneWidget);

    await tester.tap(laden);
    await tester.pumpAndSettle();
    expect(c.read(neuAmOrtProvider(NeuOrt.laden)), isFalse);
  });
}
