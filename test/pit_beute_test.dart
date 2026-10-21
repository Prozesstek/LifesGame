import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/action/beute_am_boden.dart';
import 'package:lifes_game/action/pit_beute.dart';
import 'package:lifes_game/combat/widgets/lauf_ergebnis.dart';

/// Beute in der Grube in der App (ADR-0083): was ein Fund ist, und dass
/// das Ergebnisblatt die Funde zeigt.
void main() {
  ItemDropped fund(int nth, {bool boss = false}) =>
      ItemDropped(id: 100 + nth, nth: nth, at: Vec2.zero, boss: boss);

  group('PitBeute', () {
    test('würfelt beim Fallen, was die Kaskade sagt', () {
      final beute = PitBeute(stage: 12, run: 99);
      final copy = beute.fallen(fund(1));
      final erwartet = GearLoot.cascade(stage: 12, run: 99, nth: 1);
      expect(copy.uid, erwartet.uid);
      expect(copy.itemId, erwartet.itemId);
      expect(copy.bonus, erwartet.bonus);
      expect(beute.fund(1)?.uid, copy.uid);
    });

    test('der Fund des Wächters wird als Wächterbeute gewürfelt', () {
      final beute = PitBeute(stage: 12, run: 99);
      final copy = beute.fallen(fund(3, boss: true));
      final erwartet = GearLoot.cascade(stage: 12, run: 99, nth: 3, boss: true);
      expect(copy.itemId, erwartet.itemId);
    });

    test('derselbe Fund zweimal gemeldet bleibt derselbe', () {
      final beute = PitBeute(stage: 4, run: 7);
      final a = beute.fallen(fund(1));
      final b = beute.fallen(fund(1));
      expect(identical(a, b), isTrue);
    });

    test('eingesammelt in der Reihenfolge des Einsammelns, Unbekanntes '
        'fällt heraus', () {
      final beute = PitBeute(stage: 4, run: 7);
      final a = beute.fallen(fund(1));
      final b = beute.fallen(fund(2));
      beute.fallen(fund(3));
      expect(beute.eingesammelt(<int>[2, 1, 9]).map((c) => c.uid), <String>[
        b.uid,
        a.uid,
      ]);
    });
  });

  test('am Boden lässt sich jede Seltenheit zeichnen', () {
    // Tief genug, dass Legendäres fallen kann; gesucht wird, bis jede
    // Seltenheit einmal dabei ist.
    final beute = PitBeute(stage: 25, run: 3);
    final funde = <ItemDropView>[];
    final gesehen = <GearRarity>{};
    for (var n = 1; n < 400 && gesehen.length < 5; n++) {
      final copy = beute.fallen(fund(n));
      if (gesehen.add(copy.item!.rarity)) {
        funde.add(ItemDropView(id: n, nth: n, position: Vec2(n * 20.0, 40)));
      }
    }
    expect(gesehen, GearRarity.values.toSet());

    final recorder = ui.PictureRecorder();
    BeuteAmBoden.zeichne(Canvas(recorder), funde, beute, 1.5);
    expect(recorder.endRecording(), isNotNull);
  });

  group('Das Ergebnisblatt', () {
    Future<void> zeige(WidgetTester tester, List<GearCopy> beute) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LaufErgebnis(
              won: true,
              stage: 3,
              seconds: 60,
              earnedXp: 20,
              earnedGold: 8,
              beute: beute,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('zeigt jeden Fund als Kachel', (tester) async {
      final beute = <GearCopy>[
        for (var n = 1; n <= 3; n++) GearLoot.cascade(stage: 3, run: 5, nth: n),
      ];
      await zeige(tester, beute);
      expect(find.byKey(LaufErgebnis.fundeKey), findsOneWidget);
      for (final copy in beute) {
        final item = copy.item!;
        expect(
          find.bySemanticsLabel('${item.name}, ${item.rarity.label}'),
          findsWidgets,
        );
      }
    });

    testWidgets('ohne Funde keine Reihe', (tester) async {
      await zeige(tester, const <GearCopy>[]);
      expect(find.byKey(LaufErgebnis.fundeKey), findsNothing);
      expect(find.byKey(LaufErgebnis.weiterKey), findsOneWidget);
    });
  });
}
