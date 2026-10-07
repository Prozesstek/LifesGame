import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/action_joystick.dart';
import 'package:lifes_game/action/lauf_zeichen.dart';
import 'package:lifes_game/action/lauf_zeichen_view.dart';
import 'package:lifes_game/action/pit_run_view.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/combat/widgets/lauf_ergebnis.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';

import 'test_view.dart';

/// Der erste Lauf (ADR-0069): Die Grube erklärt sich mit zwei Zeichen,
/// bis die erste Stufe geschafft ist, und eine Niederlage zeigt den Weg
/// zur Theorie.
void main() {
  group('die Regel', () {
    test('die Grube erklärt sich, bis die erste Stufe geschafft ist', () {
      expect(
        ErsterStart.aus(const ErsterStartStand()).grubeErklaertSich,
        isTrue,
      );
      // Ein verlorener Lauf ändert daran nichts: Wer verliert, hat die
      // Hilfe im nächsten am nötigsten.
      expect(
        ErsterStart.aus(
          const ErsterStartStand(haekchen: 1, hatGekaempft: true),
        ).grubeErklaertSich,
        isTrue,
      );
      expect(
        ErsterStart.aus(
          const ErsterStartStand(
            haekchen: 1,
            hatGekaempft: true,
            stufenGeschafft: 1,
          ),
        ).grubeErklaertSich,
        isFalse,
      );
    });

    test('allesOffen erklärt nichts — Tests anderer Bereiche bleiben, '
        'wie sie sind', () {
      expect(ErsterStart.allesOffen.grubeErklaertSich, isFalse);
    });

    test('das Geister-Steuerkreuz geht mit dem ersten Schritt', () {
      final zeichen = LaufZeichen();
      expect(zeichen.zeigtZiehen, isTrue);
      expect(zeichen.ziehenDeckkraft, 1);

      // Stehen lässt es stehen, so lange es dauert.
      zeichen.advance(30, gelaufen: 0);
      expect(zeichen.ziehenDeckkraft, 1);

      // Auf den letzten Punkten blendet es aus, statt wegzuspringen.
      zeichen.advance(
        0.1,
        gelaufen: LaufZeichen.wegBisVerstanden - LaufZeichen.ausblendWeg / 2,
      );
      expect(zeichen.ziehenDeckkraft, closeTo(0.5, 0.001));

      zeichen.advance(0.1, gelaufen: LaufZeichen.ausblendWeg);
      expect(zeichen.zeigtZiehen, isFalse);
    });

    test('das Zeichen am Helden kommt mit dem ersten Schlag, einmal', () {
      final zeichen = LaufZeichen();
      expect(zeichen.zeigtSchlag, isFalse);

      // Ohne Schlag vergeht die Zeit, ohne dass etwas erscheint.
      zeichen.advance(10, gelaufen: 0);
      expect(zeichen.zeigtSchlag, isFalse);

      zeichen.heldSchlaegt();
      expect(zeichen.schlagDeckkraft, 1);

      // Jeder weitere Hieb fängt nicht von vorn an.
      zeichen.advance(LaufZeichen.schlagSekunden - 0.5, gelaufen: 0);
      zeichen.heldSchlaegt();
      expect(zeichen.schlagDeckkraft, closeTo(0.5, 0.001));

      zeichen.advance(1, gelaufen: 0);
      zeichen.heldSchlaegt();
      expect(zeichen.zeigtSchlag, isFalse);
    });

    test('der Geisterdaumen zieht reihum in alle vier Richtungen', () {
      // Mitten im Halten ist er voll ausgelenkt.
      Offset gehalten(int runde) =>
          LaufZeichenView.knopf((runde + 0.65) * LaufZeichenView.ziehenPeriode);

      const r = ActionJoystick.radius;
      expect(gehalten(0).dx, closeTo(r, 0.001));
      expect(gehalten(1).dy, closeTo(-r, 0.001));
      expect(gehalten(2).dx, closeTo(-r, 0.001));
      expect(gehalten(3).dy, closeTo(r, 0.001));
      expect(gehalten(4).dx, closeTo(r, 0.001));

      // Am Anfang jeder Runde setzt er in der Mitte auf.
      expect(LaufZeichenView.knopf(0), Offset.zero);
    });

    test('das Zeichen sitzt über dem Helden — und darunter, wenn oben '
        'die Kopfzeile liegt', () {
      const feld = Size(390, 780);

      final mitte = LaufZeichenView.schlagMitte(const Offset(195, 400), feld);
      expect(mitte, const Offset(195, 400 - LaufZeichenView.schlagHoehe));

      // Die Kamera hält am Rand der Grube an; dann steht der Held dicht
      // unter der Kopfzeile, und über ihm ist kein Platz.
      final oben = LaufZeichenView.schlagMitte(const Offset(195, 120), feld);
      expect(oben.dy, greaterThan(120));
      expect(oben.dy, greaterThan(LaufZeichenView.kopfzeile));

      // Am Rand rückt es herein.
      final links = LaufZeichenView.schlagMitte(const Offset(2, 400), feld);
      expect(links.dx, greaterThan(20));
      final rechts = LaufZeichenView.schlagMitte(const Offset(388, 400), feld);
      expect(rechts.dx, lessThan(370));
    });
  });

  group('im Lauf', () {
    ActionGame lauf({LaufZeichen? zeichen}) {
      return ActionGame(
        sim: ActionWorld(
          level: LevelCatalog.grube,
          heroStats: ActionStats.gereift,
        ),
        zeichen: zeichen,
      );
    }

    Future<void> zeige(WidgetTester tester, ActionGame game) async {
      addTearDown(game.frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PitRunView(game: game)),
        ),
      );
      await tester.pump();
    }

    /// Lässt den Lauf [sekunden] weiterlaufen, ohne auf die Uhr des Tests
    /// zu warten.
    Future<void> spiele(
      WidgetTester tester,
      ActionGame game,
      double sekunden,
    ) async {
      for (var t = 0.0; t < sekunden; t += 0.05) {
        game.update(0.05);
      }
      await tester.pump();
    }

    testWidgets('am Anfang steht das Geister-Steuerkreuz, und ein Schritt '
        'nimmt es weg', (tester) async {
      final game = lauf(zeichen: LaufZeichen());
      await zeige(tester, game);

      expect(find.byKey(LaufZeichenView.ziehenKey), findsOneWidget);
      expect(find.bySemanticsLabel('Zum Laufen ziehen'), findsOneWidget);

      // Die Welt sagt, wohin es frei ist: dorthin, wohin der Held am
      // weitesten kommt.
      final start = game.sim.heroView.position;
      for (final richtung in const <Vec2>[
        Vec2(1, 0),
        Vec2(-1, 0),
        Vec2(0, 1),
        Vec2(0, -1),
      ]) {
        game.moveInput = richtung;
        await spiele(tester, game, 1);
        if ((game.sim.heroView.position - start).length >
            LaufZeichen.wegBisVerstanden) {
          break;
        }
      }

      expect(find.byKey(LaufZeichenView.ziehenKey), findsNothing);
    });

    testWidgets('das Zeichen nimmt dem Daumen nichts weg', (tester) async {
      final game = lauf(zeichen: LaufZeichen());
      await zeige(tester, game);

      // Aufsetzen mitten auf dem Geisterkreuz und ziehen: Das echte
      // Steuerkreuz darunter bekommt die Geste.
      final mitte = tester.getCenter(find.byKey(LaufZeichenView.ziehenKey));
      final geste = await tester.startGesture(mitte);
      await geste.moveBy(const Offset(40, 0));
      await tester.pump();

      expect(game.moveInput.x, greaterThan(0));
      await geste.up();
    });

    testWidgets('der erste Schlag setzt das Zeichen an den Helden', (
      tester,
    ) async {
      final zeichen = LaufZeichen();
      final game = lauf(zeichen: zeichen);
      await zeige(tester, game);
      expect(find.byKey(LaufZeichenView.schlagKey), findsNothing);

      // Die Welt meldet den Schlag; hier zählt nur, was die Anzeige
      // daraus macht.
      zeichen.heldSchlaegt();
      await spiele(tester, game, 0.1);

      expect(find.byKey(LaufZeichenView.schlagKey), findsOneWidget);
      expect(find.bySemanticsLabel('Der Held schlägt von selbst'), findsOne);

      // Es sitzt am Helden, nicht irgendwo.
      final feld = tester.getRect(find.byType(PitRunView));
      final soll = LaufZeichenView.schlagMitte(game.heroOnScreen, feld.size);
      final lage = tester.getCenter(find.byKey(LaufZeichenView.schlagKey));
      expect(lage.dx - feld.left, closeTo(soll.dx, 0.5));
      expect(lage.dy - feld.top, closeTo(soll.dy, 0.5));

      await spiele(tester, game, LaufZeichen.schlagSekunden);
      expect(find.byKey(LaufZeichenView.schlagKey), findsNothing);
    });

    testWidgets('ein Schlag des Helden in der Welt löst es aus', (
      tester,
    ) async {
      // Der ganze Weg, nicht nur die Anzeige: Der Held läuft los, bis ihn
      // ein Gegner bemerkt, und schlägt dann von selbst.
      final zeichen = LaufZeichen();
      final game = lauf(zeichen: zeichen);
      await zeige(tester, game);

      var geschlagen = false;
      for (final richtung in const <Vec2>[
        Vec2(1, 0),
        Vec2(0, 1),
        Vec2(-1, 0),
        Vec2(0, -1),
      ]) {
        game.moveInput = richtung;
        for (var i = 0; i < 12 && !geschlagen; i++) {
          await spiele(tester, game, 0.5);
          geschlagen = zeichen.zeigtSchlag || zeichen.schlagAlter > 0;
        }
        if (geschlagen || game.sim.isOver) break;
      }

      expect(geschlagen, isTrue);
    });

    testWidgets('ohne Zeichen steht nichts davon da', (tester) async {
      final game = lauf();
      await zeige(tester, game);

      expect(find.byType(LaufZeichenView), findsNothing);
    });
  });

  group('in der Grube', () {
    Future<ProviderContainer> hinab(
      WidgetTester tester, [
      SaveData stand = const SaveData.empty(),
    ]) async {
      usePhoneView(tester);
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(stand)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: PitScreen(stage: PitStage(1))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return container;
    }

    ActionGame spielVon(WidgetTester tester) =>
        tester.widget<PitRunView>(find.byType(PitRunView)).game;

    /// Lässt die Uhr ablaufen: Der Held steht, bis der Lauf verloren ist,
    /// und das Blatt „Niederlage“ ist weggetippt.
    Future<void> verliere(WidgetTester tester) async {
      final game = spielVon(tester);
      for (var i = 0; i < 20000 && !game.sim.isOver; i++) {
        game.update(0.05);
      }
      expect(game.sim.isOver, isTrue);
      expect(game.sim.isWon, isFalse);

      await tester.pump();
      await tester.pump();
      expect(find.byType(LaufErgebnis), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(LaufErgebnis.weiterKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('ein neuer Stand bekommt die Zeichen', (tester) async {
      final c = await hinab(tester);

      expect(c.read(ersterStartProvider).grubeErklaertSich, isTrue);
      expect(spielVon(tester).zeichen, isNotNull);
      expect(find.byKey(LaufZeichenView.ziehenKey), findsOneWidget);
    });

    testWidgets('wer Stufe 1 geschafft hat, bekommt sie nicht mehr', (
      tester,
    ) async {
      await hinab(
        tester,
        SaveData(ladder: const LadderProgress.empty().defeat(1)),
      );

      expect(spielVon(tester).zeichen, isNull);
      expect(find.byType(LaufZeichenView), findsNothing);
    });

    testWidgets('nach einer Niederlage führt das Buch in die Theorie', (
      tester,
    ) async {
      await hinab(tester);
      await verliere(tester);

      expect(find.text('Nochmal'), findsOneWidget);
      expect(find.byKey(PitScreen.lesenKey), findsOneWidget);

      await tester.tap(find.byKey(PitScreen.lesenKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SkillTreeScreen), findsOneWidget);
      // An die Stelle der Grube, nicht darüber: „Zurück“ führt nicht in
      // den verlorenen Lauf.
      expect(find.byType(PitScreen), findsNothing);
    });

    testWidgets('„Nochmal“ bringt die Zeichen wieder', (tester) async {
      await hinab(tester);
      final erster = spielVon(tester).zeichen;
      await verliere(tester);

      await tester.tap(find.text('Nochmal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final zweiter = spielVon(tester).zeichen;
      expect(zweiter, isNotNull);
      expect(zweiter, isNot(same(erster)));
      expect(find.byKey(LaufZeichenView.ziehenKey), findsOneWidget);
    });

    testWidgets('wer schon eine Stufe geschafft hat, sieht nach einer '
        'Niederlage kein Buch', (tester) async {
      await hinab(
        tester,
        SaveData(ladder: const LadderProgress.empty().defeat(1)),
      );
      await verliere(tester);

      expect(find.text('Nochmal'), findsOneWidget);
      expect(find.byKey(PitScreen.lesenKey), findsNothing);
    });
  });
}
