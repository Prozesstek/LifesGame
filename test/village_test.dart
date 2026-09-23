import 'package:action_combat/action_combat.dart' show Vec2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/village/village_game.dart';
import 'package:lifes_game/village/village_map.dart';
import 'package:lifes_game/village/village_screen.dart';

import 'test_view.dart';

/// Das Dorf des Prototyps, ohne Bildschirm.
void main() {
  /// Läuft höchstens [sekunden], bis die Figur vor einer Tür steht.
  VillagePlace? laufe(
    VillageWalker w, {
    Vec2 input = Vec2.zero,
    double sekunden = 20,
  }) {
    const dt = 1 / 60;
    for (var t = 0.0; t < sekunden; t += dt) {
      w.step(dt, input);
      final ort = w.atDoor;
      if (ort != null) return ort;
    }
    return null;
  }

  group('Die Karte', () {
    test('hat jeden Ort, mit Tür und Gebäude', () {
      for (final ort in VillagePlace.dorf) {
        expect(village.doors, contains(ort), reason: ort.label);
        expect(village.bodies, contains(ort), reason: ort.label);
      }
    });

    test('jede Tür ist vom Start aus erreichbar', () {
      for (final MapEntry(:key, :value) in village.doors.entries) {
        expect(
          village.pathBetween(village.start, value),
          isNotNull,
          reason: key.label,
        );
      }
    });

    test('Bäume und Gebäude halten auf, Wege und Türen nicht', () {
      expect(village.isWalkable(0, 0), isFalse, reason: 'Baum am Rand');
      final laden = village.bodies[VillagePlace.laden]!.from;
      expect(village.isWalkable(laden.x, laden.y), isFalse);
      final tuer = village.doors[VillagePlace.laden]!;
      expect(village.isWalkable(tuer.x, tuer.y), isTrue);
      expect(village.isWalkable(village.start.x, village.start.y), isTrue);
    });
  });

  group('Die Figur', () {
    for (final ort in VillagePlace.dorf) {
      test('ein Tipp auf ${ort.label} führt vor die Tür', () {
        final w = VillageWalker(village);
        final mitte = village.bodies[ort]!.from;
        expect(w.walkTo(VillageMap.centerOf(mitte)), isTrue);
        expect(laufe(w), ort);
      });
    }

    test('läuft nicht durch den Waldrand', () {
      final w = VillageWalker(village);
      laufe(w, input: const Vec2(0, 1), sekunden: 5);
      final unten = (village.height - 1) * VillageMap.tileSize;
      expect(w.position.y, lessThan(unten));
    });

    test('solange sie einem Weg folgt, steht sie vor keiner Tür', () {
      final w = VillageWalker(village);
      w.walkTo(VillageMap.centerOf(village.doors[VillagePlace.zuhause]!));
      // Unterwegs, auch wenn der Weg über eine Tür führte.
      w.step(1 / 60, Vec2.zero);
      expect(w.atDoor, isNull);
    });

    test('wer weitergeht, lässt die Tür hinter sich', () {
      final w = VillageWalker(village);
      w.walkTo(VillageMap.centerOf(village.doors[VillagePlace.brett]!));
      expect(laufe(w), VillagePlace.brett);
      w.walkTo(VillageMap.centerOf(village.start));
      for (var i = 0; i < 120; i++) {
        w.step(1 / 60, Vec2.zero);
      }
      expect(w.atDoor, isNull);
    });

    test('nach dem Zurückkommen steht sie vor der Tür, nicht darin', () {
      final w = VillageWalker(village);
      w.stepOutOf(VillagePlace.buecherei);
      final tuer = village.doors[VillagePlace.buecherei]!;
      expect(VillageMap.tileOf(w.position), TilePos(tuer.x, tuer.y + 1));
      expect(laufe(w, sekunden: 1), isNull);
    });

    test('Steuern hat Vorrang vor einem angetippten Weg', () {
      final w = VillageWalker(village);
      w.walkTo(VillageMap.centerOf(village.doors[VillagePlace.hoehle]!));
      w.step(1 / 60, const Vec2(1, 0));
      expect(w.isWalkingPath, isFalse);
    });
  });

  group('Der Bildschirm', () {
    Future<VillageGame> pumpDorf(WidgetTester tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: VillageScreen())),
      );
      await tester.pump();
      return tester
          .widget<GameWidget<VillageGame>>(find.byType(GameWidget<VillageGame>))
          .game!;
    }

    /// Lässt das Spiel laufen — `pumpAndSettle` endet bei Flame nie
    /// (`gotchas.md`).
    Future<void> laufenLassen(WidgetTester tester, double sekunden) async {
      for (var t = 0.0; t < sekunden; t += 0.05) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('steht auf dem Handy, mit dem Weg zu den Gewohnheiten', (
      tester,
    ) async {
      await pumpDorf(tester);
      expect(find.text('Heute 0/0'), findsOneWidget);
      // Die Kopfzeile gehört nach oben — sie stand einmal mitten im Bild.
      expect(tester.getRect(find.byIcon(Icons.arrow_back)).top, lessThan(80));
      expect(tester.getRect(find.text('Heute 0/0')).top, lessThan(80));

      await tester.tap(find.text('Heute 0/0'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HabitsScreen), findsOneWidget);
    });

    testWidgets('das Brett öffnet erst der Knopf, dann zurück davor', (
      tester,
    ) async {
      final spiel = await pumpDorf(tester);
      final brett = village.doors[VillagePlace.brett]!;
      spiel.walker.walkTo(VillageMap.centerOf(brett));
      await laufenLassen(tester, 3);
      expect(
        find.byType(HabitsScreen),
        findsNothing,
        reason: 'ankommen öffnet nichts',
      );
      expect(find.text('Brett betreten'), findsOneWidget);

      await tester.tap(find.text('Brett betreten'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HabitsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HabitsScreen), findsNothing);
      expect(
        VillageMap.tileOf(spiel.walker.position),
        TilePos(brett.x, brett.y + 1),
        reason: 'vor dem Brett, nicht darin',
      );
    });

    testWidgets('ein zweiter Tipp auf das Gebäude geht hinein', (tester) async {
      final spiel = await pumpDorf(tester);
      spiel.walker.walkTo(
        VillageMap.centerOf(village.doors[VillagePlace.buecherei]!),
      );
      // Gut fünfzehn Felder bei 110 Punkten je Sekunde.
      await laufenLassen(tester, 7);
      expect(find.text('Bücherei betreten'), findsOneWidget);

      // Die linke obere Ecke — weit weg vom Knopf in der Mitte.
      final ecke = village.bodies[VillagePlace.buecherei]!.from;
      await tester.tapAt(spiel.worldToScreen(VillageMap.centerOf(ecke)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SkillTreeScreen), findsOneWidget);
    });

    testWidgets('die Höhle bleibt zu, solange der Kampf es ist', (
      tester,
    ) async {
      final spiel = await pumpDorf(tester);
      spiel.walker.walkTo(
        VillageMap.centerOf(village.doors[VillagePlace.hoehle]!),
      );
      await laufenLassen(tester, 6);
      await tester.tap(find.text('Höhle betreten'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LadderScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('jedes Dorfbild ist abgelegt und angemeldet', (tester) async {
      for (final datei in DorfBilder.all) {
        final daten = await rootBundle.load(datei);
        expect(daten.lengthInBytes, greaterThan(100), reason: datei);
      }
    });
  });
}
