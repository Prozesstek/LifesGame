import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_joystick.dart';
import 'package:lifes_game/action/action_prototype_screen.dart';
import 'package:lifes_game/action/damage_popup.dart';
import 'package:lifes_game/ui/palette.dart';

import 'test_view.dart';

/// **Kein `pumpAndSettle` in diesem Test.** Flames `GameWidget` zeichnet
/// dauerhaft weiter, es gibt also nie ein Bild, nach dem nichts mehr
/// ansteht — der Fallstrick steht seit dem 11.08. in `gotchas.md`.
Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: ActionPrototypeScreen())),
  );
  await tester.pump();
}

void main() {
  group('Der Prototyp-Bildschirm', () {
    testWidgets('fragt zuerst nach der Machtstufe', (tester) async {
      useTallView(tester);
      await _pumpScreen(tester);

      expect(find.text('Die Grube'), findsOneWidget);
      expect(find.text('Tag 0'), findsOneWidget);
      expect(find.text('Deine Werte'), findsOneWidget);
      expect(find.text('Decke von heute'), findsOneWidget);
      expect(find.text('Mit Potenz-Kurve'), findsOneWidget);
    });

    testWidgets('eine Stufe wählen startet den Lauf', (tester) async {
      useTallView(tester);
      await _pumpScreen(tester);

      await tester.tap(find.text('Decke von heute'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Die Kopfzeile zählt mit — und die Zahl kommt aus der Halle,
      // nicht aus dem Bildschirm.
      final gegner = LevelCatalog.grube.spawns.length;
      expect(find.textContaining('/ $gegner erledigt'), findsOneWidget);
      expect(find.byType(ActionJoystick), findsOneWidget);
    });

    testWidgets('das Startblatt passt aufs Handy', (tester) async {
      usePhoneView(tester);
      await _pumpScreen(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('Das Steuerkreuz', () {
    testWidgets('ein Zug nach rechts meldet eine Richtung nach rechts', (
      tester,
    ) async {
      Vec2 letzte = Vec2.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActionJoystick(onChanged: (v) => letzte = v)),
        ),
      );

      final mitte = tester.getCenter(find.byType(ActionJoystick));
      final geste = await tester.startGesture(mitte);
      await geste.moveBy(const Offset(60, 0));
      await tester.pump();

      expect(letzte.x, greaterThan(0.5));
      expect(letzte.y.abs(), lessThan(0.2));
    });

    testWidgets('ein Wackeln unter der Totzone bewegt nichts', (tester) async {
      Vec2 letzte = const Vec2(1, 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActionJoystick(onChanged: (v) => letzte = v)),
        ),
      );

      final mitte = tester.getCenter(find.byType(ActionJoystick));
      final geste = await tester.startGesture(mitte);
      await geste.moveBy(const Offset(3, 2));
      await tester.pump();

      expect(letzte, Vec2.zero);
    });

    testWidgets('loslassen hält die Figur an', (tester) async {
      Vec2 letzte = Vec2.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActionJoystick(onChanged: (v) => letzte = v)),
        ),
      );

      final mitte = tester.getCenter(find.byType(ActionJoystick));
      final geste = await tester.startGesture(mitte);
      await geste.moveBy(const Offset(60, 0));
      await tester.pump();
      await geste.up();
      await tester.pump();

      expect(letzte, Vec2.zero);
    });
  });

  group('Schadenszahlen', () {
    HitLanded treffer({
      int amount = 12,
      bool isCrit = false,
      Faction target = Faction.gegner,
    }) {
      return HitLanded(
        targetId: 2,
        targetFaction: target,
        at: const Vec2(100, 100),
        amount: amount,
        isCrit: isCrit,
      );
    }

    test('ein Schlag ohne Wirkung bekommt keine Null', () {
      // Eine Null über dem Kopf liest sich wie ein Fehler, nicht wie ein
      // Ergebnis.
      expect(DamagePopup.forHit(treffer(amount: 0)), isNull);
    });

    test('ein kritischer Treffer ist grösser und golden', () {
      final normal = DamagePopup.forHit(treffer())!;
      final kritisch = DamagePopup.forHit(treffer(isCrit: true))!;

      expect(kritisch.scale, greaterThan(normal.scale));
      expect(kritisch.color, Palette.goldOnDark);
    });

    test('was am Spieler ankommt, ist rot', () {
      final popup = DamagePopup.forHit(treffer(target: Faction.held))!;

      expect(popup.color, Palette.enemyOnDark);
    });

    test('sie steigt und verblasst, dann ist sie weg', () {
      final popup = DamagePopup.forHit(treffer())!;
      final start = popup.position.y;

      popup.update(DamagePopup.lifetime / 2);
      expect(popup.position.y, lessThan(start));
      expect(popup.opacity, 1, reason: 'die erste Hälfte bleibt lesbar');

      popup.update(DamagePopup.lifetime / 2 + 0.01);
      expect(popup.isAlive, isFalse);
    });
  });
}
