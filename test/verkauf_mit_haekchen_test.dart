import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/combat/widgets/lauf_ergebnis.dart';
import 'package:lifes_game/combat/widgets/siegerblatt_funde.dart';
import 'package:lifes_game/gear/equipment_screen.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/verkauf_auswahl.dart';
import 'package:lifes_game/gear/widgets/gear_sheet.dart';
import 'package:lifes_game/gear/widgets/verkauf_leiste.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Block 2 von #136 (ADR-0083): das Siegerblatt, das seine Funde
/// aufdeckt, und Verkaufen mit Häkchen — dort und im Rucksack.
void main() {
  const tag = Day(2026, 10, 21);

  /// Zehn Funde eines Laufs — genug, dass auf einem Platz zwei liegen:
  /// Das erste Stück eines leeren Platzes wird angelegt, erst das zweite
  /// liegt im Rucksack.
  List<GearCopy> funde() => <GearCopy>[
    for (var n = 1; n <= 10; n++)
      GearLoot.cascade(stage: 12, run: 31, nth: n, boss: n == 10),
  ];

  Loadout mitFunden(List<GearCopy> lauf) {
    var loadout = const Loadout.empty();
    for (final copy in lauf) {
      loadout = loadout.addFree(copy);
    }
    return loadout;
  }

  ProviderContainer behaelter(Loadout loadout) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(loadout: loadout)),
        todayProvider.overrideWithValue(tag),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Die Rechnung', () {
    test('Gesperrtes und Getragenes lassen sich nicht anhaken', () {
      final lauf = funde();
      final getragen = mitFunden(
        lauf,
      ).ownedCopies.firstWhere((c) => mitFunden(lauf).isEquipped(c.uid));
      final loadout = mitFunden(lauf).toggleLock(lauf.last.uid);
      expect(VerkaufAuswahl.waehlbar(loadout, getragen), isFalse);
      expect(VerkaufAuswahl.waehlbar(loadout, lauf.last), isFalse);
      final frei = lauf.where(
        (c) => c.uid != lauf.last.uid && !loadout.isEquipped(c.uid),
      );
      expect(frei, isNotEmpty);
      for (final copy in frei) {
        expect(VerkaufAuswahl.waehlbar(loadout, copy), isTrue);
      }
    });

    test('der Erlös zählt nur, was sich verkaufen lässt', () {
      final lauf = funde();
      final loadout = mitFunden(lauf).toggleLock(lauf.first.uid);
      final alle = lauf.map((c) => c.uid).toSet();
      final erwartet = <GearCopy>[
        for (final c in lauf)
          if (VerkaufAuswahl.waehlbar(loadout, c)) c,
      ].fold<int>(0, (s, c) => s + Loadout.refundFor(c.item!));
      expect(VerkaufAuswahl.erloes(loadout, alle), erwartet);
      expect(
        VerkaufAuswahl.bereinigt(loadout, alle),
        isNot(contains(lauf.first.uid)),
      );
    });

    test('der Controller verkauft nur, was wählbar ist', () {
      final lauf = funde();
      final c = behaelter(mitFunden(lauf).toggleLock(lauf.first.uid));
      final vorher = c.read(loadoutProvider);
      final erwartet = VerkaufAuswahl.erloes(vorher, lauf.map((f) => f.uid));
      final erloes = c
          .read(loadoutProvider.notifier)
          .sellSelected(lauf.map((f) => f.uid));
      expect(erloes, erwartet);
      final nachher = c.read(loadoutProvider);
      expect(nachher.owns(lauf.first.uid), isTrue, reason: 'gesperrt');
      for (final copy in lauf) {
        if (vorher.isEquipped(copy.uid)) {
          expect(nachher.owns(copy.uid), isTrue, reason: 'getragen');
        }
      }
    });
  });

  group('Das Siegerblatt', () {
    test('das Seltenste wird zuletzt aufgedeckt', () {
      final reihe = SiegerblattFunde.reihenfolge(funde());
      for (var i = 1; i < reihe.length; i++) {
        expect(
          reihe[i].item!.rarity.index,
          greaterThanOrEqualTo(reihe[i - 1].item!.rarity.index),
        );
      }
    });

    Future<ProviderContainer> zeige(
      WidgetTester tester,
      List<GearCopy> lauf,
    ) async {
      useTallView(tester);
      final c = behaelter(mitFunden(lauf));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(
              body: LaufErgebnis(
                won: true,
                stage: 12,
                seconds: 70,
                earnedXp: 40,
                earnedGold: 16,
                beute: lauf,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('jeder Fund liegt aufgedeckt mit Pfeil da', (tester) async {
      final lauf = funde();
      await zeige(tester, lauf);
      for (final copy in lauf) {
        expect(
          find.byKey(ValueKey<String>('fund-${copy.uid}')),
          findsOneWidget,
        );
      }
      expect(find.byType(ExemplarKachel), findsNWidgets(lauf.length));
    });

    testWidgets('vor dem Umdrehen sieht man nur die Gruppe', (tester) async {
      final lauf = funde();
      final c = behaelter(mitFunden(lauf));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(body: SiegerblattFunde(funde: lauf)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ExemplarKachel), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(ExemplarKachel), findsNWidgets(lauf.length));
    });

    testWidgets('Antippen öffnet das Blatt des Stücks', (tester) async {
      final lauf = funde();
      await zeige(tester, lauf);
      await tester.tap(find.byKey(ValueKey<String>('fund-${lauf.first.uid}')));
      await tester.pumpAndSettle();
      expect(find.byType(GearSheet), findsOneWidget);
    });

    testWidgets('mit Häkchen verkaufen: weg aus Rucksack und Blatt', (
      tester,
    ) async {
      final lauf = funde();
      final c = await zeige(tester, lauf);
      final loadout = c.read(loadoutProvider);
      final verkaufbar = lauf
          .where((f) => VerkaufAuswahl.waehlbar(loadout, f))
          .toList();
      expect(verkaufbar, isNotEmpty);
      final weg = verkaufbar.first;

      await tester.tap(find.byKey(VerkaufLeiste.umschaltenKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey<String>('fund-${weg.uid}')));
      await tester.pumpAndSettle();
      expect(
        find.byType(GearSheet),
        findsNothing,
        reason: 'Häkchen, kein Blatt',
      );
      expect(find.byKey(const ValueKey<String>('auswahl-an')), findsOneWidget);

      await tester.tap(find.byKey(VerkaufLeiste.verkaufenKey));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Verkaufen'));
      await tester.pumpAndSettle();

      expect(c.read(loadoutProvider).owns(weg.uid), isFalse);
      expect(find.byKey(ValueKey<String>('fund-${weg.uid}')), findsNothing);
    });

    testWidgets('ohne Auswahl ist Verkaufen aus', (tester) async {
      await zeige(tester, funde());
      await tester.tap(find.byKey(VerkaufLeiste.umschaltenKey));
      await tester.pumpAndSettle();
      final knopf = tester.widget<FilledButton>(
        find.byKey(VerkaufLeiste.verkaufenKey),
      );
      expect(knopf.onPressed, isNull);
    });
  });

  group('Der Rucksack', () {
    testWidgets('auch hier mit Häkchen verkaufen', (tester) async {
      useTallView(tester);
      final lauf = funde();
      final c = behaelter(mitFunden(lauf));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: EquipmentScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final loadout = c.read(loadoutProvider);
      final weg = lauf.firstWhere((f) => VerkaufAuswahl.waehlbar(loadout, f));
      await tester.tap(find.byKey(VerkaufLeiste.umschaltenKey));
      await tester.pumpAndSettle();
      final kachel = find.byKey(ValueKey<String>('rucksack-${weg.uid}'));
      await tester.ensureVisible(kachel);
      await tester.tap(kachel.first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VerkaufLeiste.verkaufenKey));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Verkaufen'));
      await tester.pumpAndSettle();

      expect(c.read(loadoutProvider).owns(weg.uid), isFalse);
    });
  });
}
