import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/beute_anzeige.dart';
import 'package:lifes_game/action/beute_regen.dart';
import 'package:progression/progression.dart';

/// Der Goldregen: Was ein Gegner bringt, fliegt als Münzen und Funken
/// zum Helden — und **kommt genau so an, wie die Welt es gezahlt hat**.
void main() {
  const held = Vec2(200, 200);
  const fall = Vec2(100, 120);

  /// Rechnet in Bildern zu 1/60 s, bis nichts mehr fliegt.
  void allesEinsammeln(BeuteRegen regen, {Vec2 bei = held}) {
    for (var i = 0; i < 60 * 5 && !regen.leer; i++) {
      regen.update(1 / 60, bei);
    }
  }

  group('wie viel fällt', () {
    test('nie eine einzelne Münze, nie ein einzelner Funke', () {
      expect(BeuteRegen.muenzenFuer(1, gross: false), greaterThanOrEqualTo(3));
      expect(BeuteRegen.funkenFuer(1, gross: false), greaterThanOrEqualTo(3));
    });

    test('der Wächter wirft einen Brunnen', () {
      expect(BeuteRegen.muenzenFuer(1, gross: true), greaterThanOrEqualTo(16));
      expect(BeuteRegen.funkenFuer(1, gross: true), greaterThanOrEqualTo(12));
    });

    test('ohne Betrag fällt nichts', () {
      final regen = BeuteRegen(startXp: 0)
        ..wirf(const LootDropped(at: fall, xp: 0, gold: 0), gross: true);
      expect(regen.leer, isTrue);
    });
  });

  group('was ankommt', () {
    test('genau der gezahlte Betrag, nicht mehr und nicht weniger', () {
      final regen = BeuteRegen(startXp: 0)
        ..wirf(const LootDropped(at: fall, xp: 7, gold: 3), gross: false)
        ..wirf(const LootDropped(at: fall, xp: 11, gold: 5), gross: true);
      allesEinsammeln(regen);

      expect(regen.leer, isTrue);
      expect(regen.gold, 8);
      expect(regen.xp, 18);
    });

    test('erst springen, dann einsammeln — nichts kommt sofort an', () {
      final regen = BeuteRegen(startXp: 0)
        ..wirf(const LootDropped(at: fall, xp: 5, gold: 2), gross: false);
      for (var i = 0; i < 15; i++) {
        regen.update(1 / 60, held);
      }
      expect(regen.gold, 0);
      expect(regen.xp, 0);
      expect(regen.stuecke, isNotEmpty);
    });

    test('wer davonrennt, zieht keine Wolke hinter sich her', () {
      final regen = BeuteRegen(startXp: 0)
        ..wirf(const LootDropped(at: fall, xp: 5, gold: 2), gross: true);
      // Der Held ist weit weg und rennt weiter weg.
      var weg = 0.0;
      var zeit = 0.0;
      while (!regen.leer && zeit < BeuteRegen.hoechstensUnterwegs + 0.1) {
        weg += 4;
        zeit += 1 / 60;
        regen.update(1 / 60, Vec2(5000 + weg, 5000));
      }
      expect(regen.leer, isTrue);
      expect(regen.gold, 2);
    });

    test('Kasse und Balken leuchten bei der Ankunft auf und klingen ab', () {
      final regen = BeuteRegen(startXp: 0)
        ..wirf(const LootDropped(at: held, xp: 2, gold: 2), gross: false);
      var gold = false;
      while (!gold && !regen.leer) {
        gold = regen.update(1 / 60, held).gold;
      }
      expect(regen.goldLeuchten, greaterThan(0.9));
      allesEinsammeln(regen);
      regen.update(BeuteRegen.pulsDauer, held);
      expect(regen.goldLeuchten, 0);
      expect(regen.xpLeuchten, 0);
    });
  });

  group('der Balken und der Aufstieg', () {
    test('ein Level mitten im Lauf wird genau einmal gemeldet', () {
      final kurzVor = LevelCurve.totalXpFor(2) - 3;
      final regen = BeuteRegen(startXp: kurzVor)
        ..wirf(const LootDropped(at: fall, xp: 10, gold: 0), gross: false);
      expect(regen.stand?.level, 1);

      var aufstiege = 0;
      for (var i = 0; i < 60 * 4; i++) {
        if (regen.update(1 / 60, held).aufstieg) aufstiege++;
      }
      expect(aufstiege, 1);
      expect(regen.stand?.level, 2);
    });

    test('der Aufstieg steht eine Weile da und geht dann', () {
      final regen = BeuteRegen(startXp: LevelCurve.totalXpFor(2) - 1)
        ..wirf(const LootDropped(at: held, xp: 3, gold: 0), gross: false);
      var gesehen = false;
      while (!regen.leer) {
        regen.update(1 / 60, held);
        gesehen = gesehen || regen.aufstieg != null;
      }
      expect(gesehen, isTrue);
      regen.update(BeuteRegen.aufstiegDauer, held);
      expect(regen.aufstieg, isNull);
    });

    test('ohne Erfahrung vor dem Lauf gibt es weder Balken noch Aufstieg', () {
      final regen = BeuteRegen(startXp: null)
        ..wirf(const LootDropped(at: fall, xp: 500, gold: 0), gross: true);
      var aufstieg = false;
      for (var i = 0; i < 60 * 4; i++) {
        aufstieg = regen.update(1 / 60, held).aufstieg || aufstieg;
      }
      expect(regen.stand, isNull);
      expect(aufstieg, isFalse);
    });
  });

  group('die Anzeige', () {
    Widget umrahmt(Widget kind) => MaterialApp(
      home: Scaffold(body: Center(child: kind)),
    );

    testWidgets('die Kasse zeigt, was angekommen ist', (tester) async {
      final regen = BeuteRegen(startXp: 0)
        ..wirf(const LootDropped(at: held, xp: 0, gold: 4), gross: false);
      allesEinsammeln(regen);

      await tester.pumpWidget(umrahmt(LaufKasse(regen: regen)));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('ohne Erfahrung vor dem Lauf kein Balken', (tester) async {
      await tester.pumpWidget(
        umrahmt(ErfahrungsLeiste(regen: BeuteRegen(startXp: null))),
      );
      expect(find.byKey(ErfahrungsLeiste.schluessel), findsNothing);

      await tester.pumpWidget(
        umrahmt(
          SizedBox(
            width: 300,
            child: ErfahrungsLeiste(regen: BeuteRegen(startXp: 120)),
          ),
        ),
      );
      expect(find.byKey(ErfahrungsLeiste.schluessel), findsOneWidget);
    });
  });
}
